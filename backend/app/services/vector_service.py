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
import re
from datetime import date, datetime

import asyncpg
import httpx

from app.config import settings

logger = logging.getLogger(__name__)

_pool: asyncpg.Pool | None = None
_http: httpx.AsyncClient | None = None

# Retrieve 3 chunks — enough to ground the answer without burning token budget.
_TOP_K = 3

# Only inject chunks that are clearly relevant (≥0.65 similarity).
_MIN_SIMILARITY = 0.65

# Pull extra vector hits, then re-rank with enactment date so newer laws can win
# close ties without overriding strong semantic matches.
_CANDIDATE_LIMIT = 20

# Share of the ranking score from recency (0–1). Similarity still dominates.
_RECENCY_WEIGHT = 0.22

# Laws before this year get the minimum recency score.
_RECENCY_FLOOR_YEAR = 1900

# Max words per chunk shown in the prompt. The stored chunk is 800 words but
# we only send the first 250 words — saves ~1 400 tokens per request.
_MAX_CHUNK_WORDS = 250

_DATE_FORMATS = (
    "%Y-%m-%d",
    "%B %d, %Y",
    "%b %d, %Y",
    "%d %B %Y",
    "%d %b %Y",
    "%m/%d/%Y",
    "%m-%d-%Y",
)

# When the user message matches topic needles, append legal context to the embed
# query and run metadata lookups (number/title) so cited statutes can be retrieved.
_TOPIC_QUERY_EXPANSIONS: list[tuple[tuple[str, ...], str, tuple[str, ...]]] = [
    (
        ("bully", "bullied", "bullying", "harass", "harassed"),
        "Republic Act 10627 Anti-Bullying Act Philippines school workplace",
        ("10627", "anti-bullying", "bullying"),
    ),
    (
        ("dismiss", "terminated", "fired", "resign", "employer"),
        "Labor Code illegal dismissal termination Philippines",
        ("442", "illegal dismissal", "labor code"),
    ),
    (
        ("estate", "inherit", "will", "succession", "deceased"),
        "estate succession Civil Code Philippines",
        ("inheritance", "succession", "estate"),
    ),
    (
        ("annul", "divorce", "separate", "marriage"),
        "Family Code annulment legal separation Philippines",
        ("family code", "annulment", "legal separation"),
    ),
]

# Similarity assigned to metadata-matched rows (display + ranking).
_METADATA_MATCH_SIMILARITY = 0.72

_CITED_LAW_RE = re.compile(
    r"\b(?:Republic\s+Act|R\.?\s*A\.?|Presidential\s+Decree|P\.?\s*D\.?)"
    r"\s*(?:No\.?\s*)?(\d+)\b",
    re.IGNORECASE,
)


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


def _parse_date_enacted(raw: str | None) -> date | None:
    """Best-effort parse for scraped date_enacted strings."""
    if raw is None:
        return None
    s = str(raw).strip()
    if not s:
        return None

    for fmt in _DATE_FORMATS:
        try:
            return datetime.strptime(s, fmt).date()
        except ValueError:
            continue

    year_match = re.search(r"\b(19|20)\d{2}\b", s)
    if year_match:
        year = int(year_match.group(0))
        return date(year, 6, 15)

    return None


def _recency_score(enacted: date | None, *, today: date | None = None) -> float:
    """
    Map enactment date → [0, 1]. Missing/unknown dates stay neutral (0.45)
    so classic statutes are not excluded when similarity is high.
    """
    if enacted is None:
        return 0.45

    ref = today or date.today()
    ref_year = ref.year
    year = min(enacted.year, ref_year)
    floor = _RECENCY_FLOOR_YEAR
    span = max(ref_year - floor, 1)
    return max(0.0, min(1.0, (year - floor) / span))


def _combined_rank_score(similarity: float, recency: float) -> float:
    return (1.0 - _RECENCY_WEIGHT) * similarity + _RECENCY_WEIGHT * recency


def _chunk_dedupe_key(chunk: dict) -> str:
    number = (chunk.get("number") or "").strip().lower()
    title = (chunk.get("title") or "").strip().lower()
    text_head = (chunk.get("text") or "")[:96].strip().lower()
    return f"{number}|{title}|{text_head}"


def _merge_chunk_lists(*lists: list[dict]) -> list[dict]:
    merged: list[dict] = []
    seen: set[str] = set()
    for items in lists:
        for chunk in items:
            key = _chunk_dedupe_key(chunk)
            if key in seen:
                continue
            seen.add(key)
            merged.append(chunk)
    return merged


def _expand_retrieval_query(query: str) -> str:
    q = query.lower()
    extras: list[str] = []
    for needles, expansion, _meta in _TOPIC_QUERY_EXPANSIONS:
        if any(needle in q for needle in needles):
            extras.append(expansion)
    if not extras:
        return query
    return f"{query}\n\nRelated Philippine law: {'; '.join(extras)}"


_META_STOPWORDS = frozenset((
    "someone", "please", "help", "about", "there", "their", "which",
    "would", "could", "should", "where", "these", "those", "other",
    "after", "before", "under", "between", "through", "against",
    "private", "public", "person", "people", "state", "court",
    "damage", "damages", "residence", "property", "complainant",
    "right", "rights", "shall", "section", "order", "filed",
    "action", "party", "parties", "based", "cases", "being",
    "every", "first", "following", "general", "given", "having",
    "issue", "issues", "known", "legal", "matter", "means",
    "necessary", "notice", "offense", "penalty", "period",
    "provided", "provisions", "purpose", "reason", "referred",
    "respect", "service", "subject", "terms", "thereof", "within",
))


def _metadata_search_terms(query: str) -> list[str]:
    q = query.lower()
    terms: list[str] = []
    for needles, _expansion, meta_terms in _TOPIC_QUERY_EXPANSIONS:
        if any(needle in q for needle in needles):
            terms.extend(meta_terms)
    for word in re.findall(r"[a-z]{5,}", q):
        if word not in _META_STOPWORDS:
            terms.append(word)
    # Stable dedupe
    seen: set[str] = set()
    out: list[str] = []
    for t in terms:
        t = t.strip().lower()
        if not t or t in seen:
            continue
        seen.add(t)
        out.append(t)
    return out[:8]


def extract_cited_law_numbers(text: str) -> list[str]:
    """Extract numeric IDs from RA / PD style citations in model or user text."""
    seen: set[str] = set()
    out: list[str] = []
    for m in _CITED_LAW_RE.finditer(text or ""):
        num = m.group(1)
        if num not in seen:
            seen.add(num)
            out.append(num)
    return out


def _rerank_by_recency(candidates: list[dict], top_k: int) -> list[dict]:
    """Prefer newer enactments among semantically similar chunks."""
    if not candidates:
        return []

    ranked: list[tuple[float, float, dict]] = []
    for chunk in candidates:
        sim = float(chunk.get("similarity") or 0.0)
        enacted = _parse_date_enacted(chunk.get("date_enacted"))
        rec = _recency_score(enacted)
        score = _combined_rank_score(sim, rec)
        ranked.append((score, sim, chunk))

    ranked.sort(key=lambda item: (item[0], item[1]), reverse=True)
    return [chunk for _, _, chunk in ranked[:top_k]]


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


async def _search_chunks_by_metadata(
    pool: asyncpg.Pool,
    terms: list[str],
    *,
    limit: int,
) -> list[dict]:
    if not terms:
        return []

    patterns = [f"%{t}%" for t in terms]
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
                    date_enacted,
                    $3::float AS similarity
                FROM law_chunks
                WHERE number ILIKE ANY($1::text[])
                   OR title ILIKE ANY($1::text[])
                ORDER BY date_enacted DESC NULLS LAST, chunk_index ASC
                LIMIT $2
                """,
                patterns,
                limit,
                _METADATA_MATCH_SIMILARITY,
            )
        return [dict(r) for r in rows]
    except Exception:
        logger.exception("metadata law_chunks search failed")
        return []


async def fetch_chunks_by_law_numbers(
    pool: asyncpg.Pool,
    numbers: list[str],
    *,
    limit_per_number: int = 1,
) -> list[dict]:
    """Fetch chunks whose number/title matches cited RA/PD numbers."""
    if not numbers:
        return []

    out: list[dict] = []
    try:
        async with pool.acquire() as conn:
            for num in numbers[:6]:
                pattern = f"%{num}%"
                rows = await conn.fetch(
                    """
                    SELECT
                        text,
                        number,
                        title,
                        category,
                        source_url,
                        date_enacted,
                        $3::float AS similarity
                    FROM law_chunks
                    WHERE number ILIKE $1 OR title ILIKE $1
                    ORDER BY chunk_index ASC
                    LIMIT $2
                    """,
                    pattern,
                    limit_per_number,
                    _METADATA_MATCH_SIMILARITY,
                )
                out.extend(dict(r) for r in rows)
    except Exception:
        logger.exception("law number chunk lookup failed")
        return []

    return _merge_chunk_lists(out)


async def _search_chunks_by_embedding(
    pool: asyncpg.Pool,
    embedding: list[float],
    top_k: int,
) -> list[dict]:
    vec_literal = "[" + ",".join(f"{v:.8f}" for v in embedding) + "]"
    candidate_limit = max(top_k, _CANDIDATE_LIMIT)
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
                    date_enacted,
                    1 - (embedding <=> $1::vector) AS similarity
                FROM law_chunks
                WHERE 1 - (embedding <=> $1::vector) >= $3
                ORDER BY embedding <=> $1::vector
                LIMIT $2
                """,
                vec_literal,
                candidate_limit,
                _MIN_SIMILARITY,
            )
        candidates = [dict(r) for r in rows]
        return _rerank_by_recency(candidates, top_k)
    except Exception:
        logger.exception("pgvector search failed")
        return []


async def get_relevant_chunks(query: str, top_k: int = _TOP_K) -> list[dict]:
    """
    Return the top-k most relevant law chunks for *query*.

    Each result dict has keys:
        text, number, title, category, source_url, date_enacted, similarity (float 0–1)

    Uses vector search plus topic metadata lookup, then re-ranks for recency.
    """
    pool = await _get_pool()
    if pool is None:
        return []

    expanded = _expand_retrieval_query(query)
    embedding = await _embed(expanded)
    if embedding is None:
        return []

    vector_hits = await _search_chunks_by_embedding(pool, embedding, top_k)
    meta_terms = _metadata_search_terms(query)
    meta_hits = await _search_chunks_by_metadata(
        pool, meta_terms, limit=max(top_k, 6)
    )
    merged = _merge_chunk_lists(vector_hits, meta_hits)
    return _rerank_by_recency(merged, top_k)


async def align_rag_sources_with_citations(
    rag_sources: list[dict],
    reply_text: str,
    *,
    top_k: int = _TOP_K,
) -> list[dict]:
    """
    Ensure laws cited in the assistant reply appear in rag_sources when they
    exist in law_chunks (UI 'Retrieved for this answer' matches citations).
    """
    pool = await _get_pool()
    if pool is None:
        return rag_sources

    cited = extract_cited_law_numbers(reply_text)
    if not cited:
        return rag_sources

    existing_numbers = {
        (s.get("number") or "").lower() for s in rag_sources if s.get("number")
    }
    missing = [n for n in cited if not any(n in num for num in existing_numbers)]
    if not missing:
        return rag_sources

    extra = await fetch_chunks_by_law_numbers(pool, missing)
    if not extra:
        return rag_sources

    combined = _merge_chunk_lists(
        [_rag_source_row_from_chunk(c) for c in extra],
        rag_sources,
    )
    return combined[:top_k]


def _rag_source_row_from_chunk(chunk: dict) -> dict:
    sim = chunk.get("similarity")
    try:
        sim_f = float(sim) if sim is not None else _METADATA_MATCH_SIMILARITY
    except (TypeError, ValueError):
        sim_f = _METADATA_MATCH_SIMILARITY
    return {
        "number": chunk.get("number"),
        "title": (chunk.get("title") or "")[:400],
        "category": chunk.get("category"),
        "similarity": round(sim_f, 4),
        "source_url": chunk.get("source_url"),
    }


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
            "date_enacted": c.get("date_enacted"),
            "text_preview": (c.get("text") or "")[:400],
            "source_url": c.get("source_url"),
        }
        for c in chunks
    ]

    if chunks:
        out["summary"] = (
            "RAG pipeline is working: query was embedded, pgvector returned "
            f"{len(chunks)} chunk(s) above the similarity threshold "
            f"(re-ranked with {_RECENCY_WEIGHT:.0%} recency weight)."
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
        "directly relevant to the user's question. They are ranked with preference "
        "for more recently enacted sources when similarity is comparable. Ground "
        "your answer in this text and cite the law numbers specifically. "
        "If a newer law amends or supersedes an older one on point, follow the "
        "newer text. If an excerpt is not relevant to the user's query, ignore it.\n\n"
        f"{joined}\n\n"
        "---\n"
    )
