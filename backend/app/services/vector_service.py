"""
RAG retrieval service.

Embeds the user's query by calling the embed microservice running on the
Google Cloud VM (EMBED_SERVICE_URL), then performs a cosine-similarity search
against the law_chunks table (pgvector).

Graceful degradation: if SUPABASE_DB_URL or EMBED_SERVICE_URL is not set,
or if either service is unreachable, get_relevant_chunks() returns [] so the
chatbot continues to work without RAG context.
"""

from __future__ import annotations

import logging

import asyncpg
import httpx

from app.config import settings

logger = logging.getLogger(__name__)

_pool: asyncpg.Pool | None = None
_http: httpx.AsyncClient | None = None

# Retrieve 3 chunks — enough to ground the answer without burning token budget.
_TOP_K = 3

# Only inject chunks that are clearly relevant (≥0.60 similarity).
_MIN_SIMILARITY = 0.60

# Max words per chunk shown in the prompt. The stored chunk is 800 words but
# we only send the first 250 words — saves ~1 400 tokens per request.
_MAX_CHUNK_WORDS = 250


async def _get_pool() -> asyncpg.Pool | None:
    """Return (and lazily create) the asyncpg connection pool."""
    global _pool

    if not settings.SUPABASE_DB_URL:
        return None

    if _pool is None:
        try:
            _pool = await asyncpg.create_pool(
                settings.SUPABASE_DB_URL,
                ssl=False,
                min_size=1,
                max_size=5,
                command_timeout=10,
            )
            logger.info("pgvector pool connected")
        except Exception:
            logger.exception("Could not connect to pgvector DB — RAG disabled")
            return None

    return _pool


def _get_http() -> httpx.AsyncClient:
    global _http
    if _http is None:
        _http = httpx.AsyncClient(timeout=10.0)
    return _http


async def _embed(text: str) -> list[float] | None:
    """Call the embed microservice on the VM and return a 768-dim vector."""
    if not settings.EMBED_SERVICE_URL:
        return None
    try:
        resp = await _get_http().post(
            f"{settings.EMBED_SERVICE_URL}/embed",
            json={"text": text},
        )
        resp.raise_for_status()
        return resp.json()["embedding"]
    except Exception:
        logger.exception("Embed service call failed")
        return None


async def _search_chunks_by_embedding(
    pool: asyncpg.Pool,
    embedding: list[float],
    top_k: int,
) -> list[dict]:
    vec_literal = "[" + ",".join(f"{v:.8f}" for v in embedding) + "]"
    try:
        async with pool.acquire() as conn:
            rows = await conn.fetch(
                """
                SELECT
                    text,
                    number,
                    title,
                    category,
                    source_url,
                    1 - (embedding <=> $1::vector) AS similarity
                FROM law_chunks
                WHERE 1 - (embedding <=> $1::vector) >= $3
                ORDER BY embedding <=> $1::vector
                LIMIT $2
                """,
                vec_literal,
                top_k,
                _MIN_SIMILARITY,
            )
        return [dict(r) for r in rows]
    except Exception:
        logger.exception("pgvector search failed")
        return []


async def get_relevant_chunks(query: str, top_k: int = _TOP_K) -> list[dict]:
    """
    Return the top-k most relevant law chunks for *query*.

    Each result dict has keys:
        text, number, title, category, source_url, similarity (float 0–1)
    """
    pool = await _get_pool()
    if pool is None:
        return []

    embedding = await _embed(query)
    if embedding is None:
        return []

    return await _search_chunks_by_embedding(pool, embedding, top_k)


async def rag_self_test(query: str) -> dict:
    """
    Diagnostics for DEBUG-only /debug/rag — one embed call + optional DB count.
    """
    out: dict = {
        "supabase_db_url_set": bool(settings.SUPABASE_DB_URL),
        "embed_service_url_set": bool(settings.EMBED_SERVICE_URL),
        "database_pool_ok": False,
        "law_chunks_total": None,
        "query_embedding_ok": False,
        "embedding_dimensions": 0,
        "chunks_retrieved": 0,
        "chunks": [],
        "summary": "",
    }
    pool = await _get_pool()
    out["database_pool_ok"] = pool is not None
    if pool is None:
        out["summary"] = (
            "Vector DB unreachable or SUPABASE_DB_URL missing. "
            "RAG is off until the backend can open a pool to PostgreSQL (pgvector)."
        )
        return out

    try:
        async with pool.acquire() as conn:
            out["law_chunks_total"] = int(
                await conn.fetchval("SELECT COUNT(*)::bigint FROM law_chunks")
            )
    except Exception:
        logger.exception("rag_self_test: could not count law_chunks")
        out["law_chunks_total"] = None

    vec = await _embed(query)
    if vec is None:
        out["summary"] = (
            "Embed service failed or EMBED_SERVICE_URL missing. "
            "RAG is off until POST /embed works from this backend (firewall, URL, systemd)."
        )
        return out

    out["query_embedding_ok"] = True
    out["embedding_dimensions"] = len(vec)

    chunks = await _search_chunks_by_embedding(pool, vec, _TOP_K)
    out["chunks_retrieved"] = len(chunks)
    out["chunks"] = [
        {
            "number": c.get("number"),
            "title": (c.get("title") or "")[:240],
            "category": c.get("category"),
            "similarity": round(float(c["similarity"]), 4),
            "text_preview": (c.get("text") or "")[:400],
            "source_url": c.get("source_url"),
        }
        for c in chunks
    ]

    if chunks:
        out["summary"] = (
            "RAG pipeline is working: query was embedded, pgvector returned "
            f"{len(chunks)} chunk(s) above the similarity threshold."
        )
    elif (out["law_chunks_total"] or 0) == 0:
        out["summary"] = (
            "Embed + DB OK but law_chunks is empty — run data/ingest.py against this database."
        )
    else:
        out["summary"] = (
            "Embed + DB OK and the table has rows, but no chunk met the similarity "
            f"cutoff (>={_MIN_SIMILARITY}). Try a more specific legal query or temporarily "
            "lower _MIN_SIMILARITY in vector_service.py."
        )
    return out


def format_rag_context(chunks: list[dict]) -> str:
    """
    Turn retrieved chunks into a Markdown block that is injected into the
    system prompt so Groq can cite actual Philippine legal text.

    Returns an empty string when *chunks* is empty (no context is injected).
    """
    if not chunks:
        return ""

    parts: list[str] = []
    for chunk in chunks:
        header = f"[{chunk.get('number', 'Unknown')} - {chunk.get('title', '')}]"
        # Truncate to _MAX_CHUNK_WORDS to keep prompt token cost predictable
        words = chunk["text"].split()
        body = " ".join(words[:_MAX_CHUNK_WORDS])
        if len(words) > _MAX_CHUNK_WORDS:
            body += " …"
        parts.append(f"{header}\n{body}")

    joined = "\n\n---\n\n".join(parts)

    return (
        "\n\n## RETRIEVED PHILIPPINE LEGAL TEXT\n\n"
        "The following excerpts were retrieved from Philippine statutes and are "
        "directly relevant to the user's question. Ground your answer in this text "
        "and cite the law numbers specifically. "
        "If an excerpt is not relevant to the user's query, ignore it.\n\n"
        f"{joined}\n\n"
        "---\n"
    )
