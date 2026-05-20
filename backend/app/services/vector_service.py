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
from app.services.rag_relevance_service import filter_chunks_by_relevance
from app.services.rag_router_service import should_retrieve_legal_context

logger = logging.getLogger(__name__)

_pool: asyncpg.Pool | None = None
_http: httpx.AsyncClient | None = None

# Retrieve 3 chunks — enough to ground the answer without burning token budget.
_TOP_K = 3

# Only inject chunks that are clearly relevant (cosine similarity floor).
_MIN_SIMILARITY = 0.68

# Pull extra vector hits, then re-rank with category + recency before selecting top-k.
_CANDIDATE_LIMIT = 24

# Prefer statutes/issuances over case law unless the user asks about jurisprudence.
_STATUTE_CATEGORIES = frozenset({
    "republic_acts",
    "batas_pambansa",
    "presidential_decrees",
    "executive_orders",
    "commonwealth_acts",
    "administrative_orders",
})
_CASELAW_CATEGORIES = frozenset({
    "supreme_court_decisions",
})

_CASELAW_QUERY_RE = re.compile(
    r"\b(?:"
    r"supreme\s+court|sc\s+decision|jurisprudence|case\s+law|court\s+held|"
    r"ruled\s+that|doctrine|precedent|ponente|"
    r"g\.?\s*r\.?\s*(?:no\.?)?\s*\d+|gr\s+no\.?\s*\d+"
    r")\b",
    re.IGNORECASE,
)

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
    (
        ("child", "children", "minor", "minors", "kids", "abuse", "abused"),
        "Republic Act 7610 Special Protection of Children Against Abuse Philippines",
        ("7610", "child abuse", "special protection of children"),
    ),
]

_STATUTE_LOOKUP_CATEGORIES = (
    "republic_acts",
    "batas_pambansa",
    "presidential_decrees",
    "executive_orders",
    "commonwealth_acts",
    "administrative_orders",
)

# Similarity assigned to metadata-matched rows (display + ranking).
_METADATA_MATCH_SIMILARITY = 0.72

_CITED_LAW_RE = re.compile(
    r"\b(?:Republic\s+Act|R\.?\s*A\.?|Presidential\s+Decree|P\.?\s*D\.?|P\.?\s*D\.?\s*No\.?)"
    r"\s*(?:No\.?\s*)?(\d{3,5})\b",
    re.IGNORECASE,
)
# Bare "RA 7610" / "R.A. No. 7610" when not caught above
_RA_BARE_RE = re.compile(
    r"\bR\.?\s*A\.?\s*(?:No\.?\s*)?(\d{3,5})\b",
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


def _recency_weight() -> float:
    return max(0.0, min(0.35, settings.RAG_RECENCY_WEIGHT))


def _combined_rank_score(similarity: float, recency: float) -> float:
    w = _recency_weight()
    return (1.0 - w) * similarity + w * recency


def _is_caselaw_query(query: str) -> bool:
    return bool(_CASELAW_QUERY_RE.search(query or ""))


def _category_score_adjustment(category: str | None, *, caselaw_query: bool) -> float:
    """Nudge ranking toward statutes for general questions; toward SC when case law is asked."""
    cat = (category or "").strip().lower()
    if caselaw_query:
        if cat in _CASELAW_CATEGORIES:
            return 0.07
        return 0.0
    if cat in _STATUTE_CATEGORIES:
        return 0.10
    if cat in _CASELAW_CATEGORIES:
        return -0.14
    return 0.0


def _law_identity_key(chunk: dict) -> str:
    number = (chunk.get("number") or "").strip().lower()
    if number:
        return number
    return (chunk.get("title") or "").strip().lower()[:80] or _chunk_dedupe_key(chunk)


def _select_diverse_top_k(
    ranked: list[tuple[float, float, dict]],
    top_k: int,
    *,
    caselaw_query: bool,
) -> list[dict]:
    """Prefer one chunk per law/case and cap unrelated SC decisions in results."""
    selected: list[dict] = []
    sc_count = 0
    max_sc = top_k if caselaw_query else max(0, settings.RAG_MAX_SC_DECISIONS)
    seen_laws: set[str] = set()

    for _score, sim, chunk in ranked:
        if len(selected) >= top_k:
            break
        cat = (chunk.get("category") or "").strip().lower()
        if cat in _CASELAW_CATEGORIES:
            if sc_count >= max_sc:
                continue
            if not caselaw_query and sim < settings.RAG_MIN_TOP_SIMILARITY + 0.04:
                continue
            sc_count += 1
        law_key = _law_identity_key(chunk)
        if law_key in seen_laws:
            continue
        seen_laws.add(law_key)
        selected.append(chunk)
    return selected


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


# Greetings / small-talk tokens — never use for metadata LIKE search.
_META_GREETING_WORDS = frozenset((
    "hello", "helo", "hi", "hey", "thanks", "thank", "salamat", "kumusta",
    "kamusta", "musta", "goodbye", "bye", "morning", "afternoon", "evening",
    "greetings", "welcome", "po", "lang", "sir", "maam", "mam",
))

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
    "concern", "concerns", "issue", "issues", "problem", "problems",
    "help", "assist", "assistance", "question", "questions",
)) | _META_GREETING_WORDS


def _filter_by_retrieval_confidence(chunks: list[dict]) -> list[dict]:
    """Drop weak vector matches so vague queries do not surface random statutes."""
    if not chunks:
        return []

    floor = settings.RAG_MIN_TOP_SIMILARITY
    statute_hits = [c for c in chunks if c.get("_exact_statute_lookup")]
    vector_hits = [c for c in chunks if not c.get("_exact_statute_lookup")]

    if vector_hits:
        top = max(float(c.get("similarity") or 0.0) for c in vector_hits)
        if top < floor and not statute_hits:
            logger.info(
                "RAG confidence filter: top similarity %.3f < %.3f — returning no chunks",
                top,
                floor,
            )
            return []
        vector_hits = [
            c for c in vector_hits if float(c.get("similarity") or 0.0) >= floor
        ]

    if not vector_hits and not statute_hits:
        return []

    return _merge_chunk_lists(statute_hits, vector_hits)

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
    blob = text or ""
    for pattern in (_CITED_LAW_RE, _RA_BARE_RE):
        for m in pattern.finditer(blob):
            num = m.group(1)
            if num not in seen:
                seen.add(num)
                out.append(num)
    return out


def _ra_pd_number_regex(num: str) -> str:
    """
    Regex for a specific RA/PD number (PostgreSQL ~ and Python re).

    Requires an RA/PD prefix and digit boundaries so 7610 does not match G.R. 117610.
    """
    n = re.escape(num.strip())
    return (
        rf"(?i)(R\.?\s*A\.?|Republic\s+Act|P\.?\s*D\.?|Presidential\s+Decree)"
        rf"\s*(No\.?\s*)?(?<![0-9]){n}(?![0-9])"
    )


def _postgres_ra_pd_number_pattern(num: str) -> str:
    return _ra_pd_number_regex(num)


def _stored_number_cites_law(stored_number: str, cited_num: str) -> bool:
    """True when stored_number is an RA/PD citation of cited_num (not a GR substring hit)."""
    if not cited_num or not stored_number:
        return False
    try:
        return bool(re.search(_ra_pd_number_regex(cited_num), stored_number))
    except re.error:
        return False


def _split_metadata_terms(terms: list[str]) -> tuple[list[str], list[str]]:
    """Separate statute numbers (exact lookup) from free-text metadata terms."""
    law_nums: list[str] = []
    text_terms: list[str] = []
    for t in terms:
        t = t.strip()
        if t.isdigit() and len(t) >= 3:
            law_nums.append(t)
        elif t:
            text_terms.append(t)
    return law_nums, text_terms


def _rerank_candidates(
    candidates: list[dict],
    top_k: int,
    *,
    query: str,
) -> list[dict]:
    """Re-rank by semantic match, light recency, and source type (statute vs SC decision)."""
    if not candidates:
        return []

    caselaw_query = _is_caselaw_query(query)
    ranked: list[tuple[float, float, dict]] = []
    for chunk in candidates:
        sim = float(chunk.get("similarity") or 0.0)
        enacted = _parse_date_enacted(chunk.get("date_enacted"))
        rec = _recency_score(enacted)
        adj = _category_score_adjustment(chunk.get("category"), caselaw_query=caselaw_query)
        score = _combined_rank_score(sim, rec) + adj
        ranked.append((score, sim, chunk))

    ranked.sort(key=lambda item: (item[0], item[1]), reverse=True)
    return _select_diverse_top_k(ranked, top_k, caselaw_query=caselaw_query)


def _rerank_by_recency(candidates: list[dict], top_k: int) -> list[dict]:
    """Backward-compatible alias used in tests."""
    return _rerank_candidates(candidates, top_k, query="")


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
    caselaw_query: bool = False,
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
                WHERE (number ILIKE ANY($1::text[])
                   OR title ILIKE ANY($1::text[]))
                  AND ($4::bool OR category IS DISTINCT FROM 'supreme_court_decisions')
                ORDER BY
                    CASE category
                        WHEN 'republic_acts' THEN 0
                        WHEN 'batas_pambansa' THEN 1
                        WHEN 'presidential_decrees' THEN 2
                        WHEN 'executive_orders' THEN 3
                        WHEN 'commonwealth_acts' THEN 4
                        WHEN 'administrative_orders' THEN 5
                        WHEN 'supreme_court_decisions' THEN 9
                        ELSE 6
                    END,
                    date_enacted DESC NULLS LAST,
                    chunk_index ASC
                LIMIT $2
                """,
                patterns,
                limit,
                _METADATA_MATCH_SIMILARITY,
                caselaw_query,
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
    """Fetch chunks for specific RA/PD numbers (word-boundary match, statutes only)."""
    if not numbers:
        return []

    out: list[dict] = []
    try:
        async with pool.acquire() as conn:
            for num in numbers[:6]:
                pattern = _postgres_ra_pd_number_pattern(num)
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
                    WHERE category = ANY($4::text[])
                      AND (number ~ $1 OR title ~ $1)
                    ORDER BY chunk_index ASC
                    LIMIT $2
                    """,
                    pattern,
                    limit_per_number,
                    _METADATA_MATCH_SIMILARITY,
                    list(_STATUTE_LOOKUP_CATEGORIES),
                )
                for r in rows:
                    chunk = dict(r)
                    chunk["_exact_statute_lookup"] = True
                    # Must clear the confidence floor (metadata rows default to 0.72).
                    chunk["similarity"] = max(
                        float(chunk.get("similarity") or 0.0),
                        settings.RAG_MIN_TOP_SIMILARITY,
                        _METADATA_MATCH_SIMILARITY,
                    )
                    out.append(chunk)
    except Exception:
        logger.exception("law number chunk lookup failed")
        return []

    return _merge_chunk_lists(out)


async def _filter_by_original_query_similarity(
    pool: asyncpg.Pool,
    query: str,
    chunks: list[dict],
) -> list[dict]:
    """Keep chunks that also match the user's message (not only expanded embed)."""
    if not chunks:
        return []
    embedding = await _embed(query.strip())
    if embedding is None:
        return chunks

    hits = await _search_chunks_by_embedding(pool, embedding, _CANDIDATE_LIMIT)
    floor = settings.RAG_ORIGINAL_QUERY_MIN_SIMILARITY
    allowed = {
        _chunk_dedupe_key(h)
        for h in hits
        if float(h.get("similarity") or 0.0) >= floor
    }
    filtered = [
        c
        for c in chunks
        if c.get("_exact_statute_lookup") or _chunk_dedupe_key(c) in allowed
    ]
    if len(filtered) < len(chunks):
        logger.info(
            "RAG original-query filter: kept %d/%d chunks (floor=%.2f)",
            len(filtered),
            len(chunks),
            floor,
        )
    return filtered


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
        return [dict(r) for r in rows]
    except Exception:
        logger.exception("pgvector search failed")
        return []


async def get_relevant_chunks(
    query: str,
    history: list[dict[str, str]] | None = None,
    top_k: int = _TOP_K,
    *,
    retrieve: bool | None = None,
) -> list[dict]:
    """
    Return the top-k most relevant law chunks for *query*.

    Each result dict has keys:
        text, number, title, category, source_url, date_enacted, similarity (float 0–1)

    Uses an LLM router (conversation-aware) to decide whether to search, then vector
    search plus topic metadata lookup, re-ranks for recency, and filters weak matches.
    """
    if retrieve is None:
        retrieve = await should_retrieve_legal_context(query, history)

    cited_in_query = extract_cited_law_numbers(query)
    if not retrieve:
        if not cited_in_query:
            return []
        pool = await _get_pool()
        if pool is None:
            return []
        hits = await fetch_chunks_by_law_numbers(pool, cited_in_query)
        return hits[:top_k]

    pool = await _get_pool()
    if pool is None:
        return []

    expanded = _expand_retrieval_query(query)
    embedding = await _embed(expanded)
    if embedding is None:
        return []

    caselaw_query = _is_caselaw_query(query)
    fetch_k = max(top_k * 3, _CANDIDATE_LIMIT // 2)
    vector_hits = await _search_chunks_by_embedding(pool, embedding, fetch_k)
    top_vector = (
        max(float(h.get("similarity") or 0.0) for h in vector_hits)
        if vector_hits
        else 0.0
    )
    cited = extract_cited_law_numbers(query)
    meta_hits: list[dict] = []
    if cited or top_vector >= settings.RAG_MIN_TOP_SIMILARITY:
        meta_terms = _metadata_search_terms(query)
        law_nums, text_terms = _split_metadata_terms(meta_terms)
        law_nums = list(dict.fromkeys([*cited, *law_nums]))
        if law_nums:
            meta_hits = await fetch_chunks_by_law_numbers(pool, law_nums)
        if text_terms:
            text_hits = await _search_chunks_by_metadata(
                pool,
                text_terms,
                limit=max(top_k, 6),
                caselaw_query=caselaw_query,
            )
            meta_hits = _merge_chunk_lists(meta_hits, text_hits)
    merged = _merge_chunk_lists(vector_hits, meta_hits)
    ranked = _rerank_candidates(merged, top_k, query=query)
    confident = _filter_by_retrieval_confidence(ranked)
    original_match = await _filter_by_original_query_similarity(pool, query, confident)
    graded = await filter_chunks_by_relevance(query, original_match, history)
    if graded:
        return graded
    # Safety net: never return empty when we had a strong statute or vector hit.
    if confident:
        logger.info("RAG: relevance filter emptied results; using confidence-passed chunks")
        return confident[:top_k]
    if meta_hits:
        return meta_hits[:top_k]
    return ranked[:top_k]


async def finalize_rag_sources_for_display(
    reply_text: str,
    rag_sources: list[dict],
    *,
    top_k: int = _TOP_K,
) -> list[dict]:
    """
    Sources for the UI: laws cited in the reply (exact RA/PD fetch) plus any
    relevance-verified chunks from retrieval, deduped. Never drops verified
    sources just because citation parsing missed a format.
    """
    if not rag_sources:
        cited = extract_cited_law_numbers(reply_text)
        if not cited:
            return []
        pool = await _get_pool()
        if pool is None:
            return []
        extra = await fetch_chunks_by_law_numbers(pool, cited)
        return [_rag_source_row_from_chunk(c) for c in extra][:top_k]

    cited = extract_cited_law_numbers(reply_text)
    out: list[dict] = []
    seen_keys: set[str] = set()

    def _source_key(s: dict) -> str:
        return ((s.get("number") or "") + "|" + (s.get("source_url") or "")).lower()

    def _add(s: dict) -> None:
        key = _source_key(s)
        if key in seen_keys:
            return
        seen_keys.add(key)
        out.append(s)

    for num in cited:
        for s in rag_sources:
            if _stored_number_cites_law(s.get("number") or "", num):
                _add(s)
                break

    missing = [
        n
        for n in cited
        if not any(_stored_number_cites_law(s.get("number") or "", n) for s in out)
    ]
    if missing:
        pool = await _get_pool()
        if pool:
            extra = await fetch_chunks_by_law_numbers(pool, missing)
            for c in extra:
                _add(_rag_source_row_from_chunk(c))

    # Always include relevance-verified retrieval (already filtered upstream).
    for s in rag_sources:
        if len(out) >= top_k:
            break
        _add(s)

    if settings.RAG_DISPLAY_ONLY_MATCHING and cited:
        # Strict mode: only cited laws, but never return empty if we had citations to fetch
        strict = [
            s
            for s in out
            if any(
                _stored_number_cites_law(s.get("number") or "", n) for n in cited
            )
        ]
        if strict:
            return strict[:top_k]

    return out[:top_k]


async def align_rag_sources_with_citations(
    rag_sources: list[dict],
    reply_text: str,
    *,
    top_k: int = _TOP_K,
) -> list[dict]:
    """Align UI sources with laws cited in the assistant reply."""
    return await finalize_rag_sources_for_display(
        reply_text, rag_sources, top_k=top_k
    )


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
            f"(re-ranked with {_recency_weight():.0%} recency weight)."
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
        "The following excerpts were retrieved from Philippine statutes, issuances, "
        "or (when applicable) Supreme Court decisions. Use only excerpts that clearly "
        "match the user's specific question — ignore unrelated text. For rights, "
        "definitions, and procedures, prefer Republic Acts and codes over case law "
        "unless the user asks about a court ruling or jurisprudence. Ground your "
        "answer in relevant excerpts and cite law numbers specifically. "
        "If an excerpt is not on point, do not cite it.\n\n"
        f"{joined}\n\n"
        "---\n"
    )
