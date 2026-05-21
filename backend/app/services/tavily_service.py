"""
Real-time web search service using Tavily, restricted to curated whitelists:
- Philippine government and legal reference sites
- Trusted Philippine outlets for legal/court news

Graceful degradation: if TAVILY_API_KEY is not set, or the API call fails,
search_for_chat() returns [] and the chatbot continues without web context.
"""

from __future__ import annotations

import asyncio
import logging
import re
from dataclasses import dataclass

from tavily import AsyncTavilyClient

from app.config import settings
from app.services.tavily_router_service import needs_realtime_web_search

logger = logging.getLogger(__name__)

# Government and legal reference — Tavily enforces via include_domains.
TRUSTED_PH_LEGAL_DOMAINS: list[str] = [
    "lawphil.net",
    "sc.judiciary.gov.ph",
    "officialgazette.gov.ph",
    "congress.gov.ph",
    "senate.gov.ph",
    "chanrobles.com",
    "bir.gov.ph",
    "dole.gov.ph",
    "bsp.gov.ph",
    "doj.gov.ph",
    "sec.gov.ph",
    "psa.gov.ph",
    "ombudsman.gov.ph",
    "sandiganbayan.gov.ph",
    "ca.judiciary.gov.ph",
    "philhealth.gov.ph",
    "sss.gov.ph",
    "gsis.gov.ph",
    "hlurb.gov.ph",
    "pagc.gov.ph",
]

# Major PH news outlets with consistent court/legal coverage.
TRUSTED_PH_LEGAL_NEWS_DOMAINS: list[str] = [
    "inquirer.net",
    "philstar.com",
    "rappler.com",
    "gmanetwork.com",
    "mb.com.ph",
    "manilatimes.net",
    "bworldonline.com",
    "abs-cbn.com",
    "cnnphilippines.com",
]

_MAX_RESULTS = 3
_MAX_NEWS_RESULTS = 3
_MAX_MERGED_RESULTS = 5
_MAX_CONTENT_WORDS = 200
_MIN_QUERY_CHARS_FOR_EMPTY_RAG = 50

_TIME_SENSITIVE_KEYWORDS: frozenset[str] = frozenset(
    {
        "latest", "recent", "new law", "new legislation", "amendment",
        "amended", "updated", "current", "circular", "irr",
        "implementing rules", "implementing regulations", "just signed",
        "just passed", "newly enacted", "newly signed", "2024", "2025", "2026",
        "republic act", "executive order", "administrative order",
        "memorandum circular", "memorandum order",
    }
)

_LEGAL_NEWS_KEYWORDS: frozenset[str] = frozenset(
    {
        "legal news",
        "law news",
        "court news",
        "news about",
        "in the news",
        "headline",
        "headlines",
        "recent news",
        "latest news",
        "breaking news",
        "news today",
        "news update",
        "news updates",
        "what's in the news",
        "whats in the news",
        "current events",
        "legal headlines",
        "supreme court news",
        "sc news",
        "congress news",
        "senate news",
        "real-time",
        "real time",
        "up to date",
        "up-to-date",
    }
)

# Obvious real-time intent without calling the Tavily LLM router.
_REALTIME_HEURISTIC_PATTERNS: tuple[re.Pattern[str], ...] = (
    re.compile(
        r"\b(?:latest|current|recent|newest|updated?)\s+"
        r"(?:news|update|updates|status|development|developments|situation)\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\b(?:what(?:'s| is)|any)\s+(?:the\s+)?(?:latest|current|recent)\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\b(?:right\s+now|as\s+of\s+(?:now|today)|today|this\s+week|this\s+month|"
        r"yesterday|ongoing|breaking)\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\b(?:is|are|was|will|gonna|going\s+to)\s+[^?.!]{0,80}?"
        r"(?:arrested|arrest|charged|indicted|convicted|warrant|detained|released|raffled)\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\b(?:has|have)\s+[^?.!]{0,60}?"
        r"(?:been\s+)?(?:arrested|charged|passed|signed|enacted|approved|published)\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\b(?:what(?:'s| is)\s+)?happening\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\b(?:going\s+on|in\s+the\s+news|news\s+about|update\s+on|status\s+of)\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\b(?:still|already)\s+[^?.!]{0,40}?"
        r"(?:in\s+effect|passed|signed|law|enacted)\b",
        re.IGNORECASE,
    ),
)

_OFFICIAL_UPDATE_HINT_RE = re.compile(
    r"\b(republic\s+act|ra\s*\d|executive\s+order|eo\s*\d|circular|irr|"
    r"implementing\s+rules|memorandum|official\s+gazette|new\s+law|bill\s+passed)\b",
    re.IGNORECASE,
)

_client: AsyncTavilyClient | None = None


@dataclass(frozen=True)
class RealtimeSearchPlan:
    search_news: bool
    search_law: bool
    source: str  # heuristic | router | keywords


def _get_client() -> AsyncTavilyClient | None:
    global _client
    if not settings.TAVILY_API_KEY:
        return None
    if _client is None:
        _client = AsyncTavilyClient(api_key=settings.TAVILY_API_KEY)
    return _client


def _is_time_sensitive(query: str) -> bool:
    q = query.lower()
    return any(kw in q for kw in _TIME_SENSITIVE_KEYWORDS)


def _is_legal_news_query(query: str) -> bool:
    q = query.lower()
    return any(kw in q for kw in _LEGAL_NEWS_KEYWORDS)


def _should_search_law(query: str, rag_chunk_count: int) -> bool:
    q = query.strip()
    return _is_time_sensitive(q) or (
        rag_chunk_count == 0 and len(q) >= _MIN_QUERY_CHARS_FOR_EMPTY_RAG
    )


def _should_search_legal_news(query: str) -> bool:
    q = query.strip()
    if not q:
        return False
    return _is_legal_news_query(q) or (
        _is_time_sensitive(q) and any(w in q.lower() for w in ("news", "headline", "report"))
    )


def heuristic_needs_realtime_search(query: str) -> bool:
    """Fast path: obvious recent/real-time intent without an LLM call."""
    q = (query or "").strip()
    if len(q) < 12:
        return False
    return any(p.search(q) for p in _REALTIME_HEURISTIC_PATTERNS)


def _plan_for_realtime_intent(query: str, rag_chunk_count: int, *, source: str) -> RealtimeSearchPlan:
    q = query.strip().lower()
    official = bool(_OFFICIAL_UPDATE_HINT_RE.search(q)) or _is_time_sensitive(query)
    news = True
    law = official or _should_search_law(query, rag_chunk_count)
    if not law and not _is_legal_news_query(query):
        # Person/case status — news only unless user also named a statute update.
        law = False
    return RealtimeSearchPlan(search_news=news, search_law=law, source=source)


async def plan_realtime_search(
    query: str,
    *,
    rag_chunk_count: int = 0,
    history: list[dict[str, str]] | None = None,
) -> RealtimeSearchPlan | None:
    """
    Return a search plan when this turn needs Tavily; None when keywords alone decide.
    """
    if _get_client() is None:
        return None

    q = query.strip()
    if not q:
        return None

    if heuristic_needs_realtime_search(q):
        return _plan_for_realtime_intent(q, rag_chunk_count, source="heuristic")

    if await needs_realtime_web_search(q, history):
        return _plan_for_realtime_intent(q, rag_chunk_count, source="router")

    return None


def _resolve_search_plan(
    query: str,
    rag_chunk_count: int,
    realtime: RealtimeSearchPlan | None,
) -> RealtimeSearchPlan:
    if realtime is not None:
        return realtime
    return RealtimeSearchPlan(
        search_news=_should_search_legal_news(query),
        search_law=_should_search_law(query, rag_chunk_count),
        source="keywords",
    )


def _merge_results(batches: list[list[dict]], *, max_total: int) -> list[dict]:
    seen_urls: set[str] = set()
    merged: list[dict] = []
    for batch in batches:
        for item in sorted(batch, key=lambda r: r.get("score", 0.0), reverse=True):
            url = (item.get("url") or "").strip()
            if url and url in seen_urls:
                continue
            if url:
                seen_urls.add(url)
            merged.append(item)
            if len(merged) >= max_total:
                return merged
    return merged


async def _tavily_search(
    query: str,
    *,
    domains: list[str],
    query_prefix: str,
    max_results: int,
) -> list[dict]:
    client = _get_client()
    if client is None:
        return []

    q = query.strip()
    if not q:
        return []

    async def _search() -> list[dict]:
        response = await client.search(
            query=f"{query_prefix} {q}",
            search_depth="basic",
            include_domains=domains,
            max_results=max_results,
        )
        results: list[dict] = response.get("results", [])
        return [
            {
                "title": r.get("title", ""),
                "url": r.get("url", ""),
                "content": r.get("content", ""),
                "score": round(float(r.get("score", 0.0)), 4),
            }
            for r in results
        ]

    try:
        return await asyncio.wait_for(
            _search(),
            timeout=settings.TAVILY_TIMEOUT_SECONDS,
        )
    except asyncio.TimeoutError:
        logger.warning(
            "Tavily search timed out after %.1fs (prefix=%r)",
            settings.TAVILY_TIMEOUT_SECONDS,
            query_prefix,
        )
        return []
    except Exception:
        logger.exception("Tavily search failed (prefix=%r)", query_prefix)
        return []


async def search_philippine_law(
    query: str,
    rag_chunk_count: int = 0,
    *,
    force: bool = False,
) -> list[dict]:
    """Search Tavily on trusted PH government/legal domains only."""
    if not force and not _should_search_law(query, rag_chunk_count):
        return []
    return await _tavily_search(
        query,
        domains=TRUSTED_PH_LEGAL_DOMAINS,
        query_prefix="Philippines law",
        max_results=_MAX_RESULTS,
    )


async def search_philippine_legal_news(query: str, *, force: bool = False) -> list[dict]:
    """Search Tavily on trusted PH news outlets for legal/court reporting."""
    if not force and not _should_search_legal_news(query):
        return []
    return await _tavily_search(
        query,
        domains=TRUSTED_PH_LEGAL_NEWS_DOMAINS,
        query_prefix="Philippines legal news court law",
        max_results=_MAX_NEWS_RESULTS,
    )


async def search_for_chat(
    query: str,
    rag_chunk_count: int = 0,
    *,
    history: list[dict[str, str]] | None = None,
    realtime_plan: RealtimeSearchPlan | None = None,
) -> list[dict]:
    """Run government/legal and legal-news Tavily searches when triggers match.

    Uses heuristics + optional LLM router (plan_realtime_search) for recent/real-time intent.
    Returns merged, deduplicated results (up to _MAX_MERGED_RESULTS), highest score first.
    """
    if _get_client() is None:
        return []

    resolved_realtime = realtime_plan
    if resolved_realtime is None:
        resolved_realtime = await plan_realtime_search(
            query, rag_chunk_count=rag_chunk_count, history=history
        )
    plan = _resolve_search_plan(query, rag_chunk_count, resolved_realtime)

    if not plan.search_news and not plan.search_law:
        return []

    logger.info(
        "Tavily plan: news=%s law=%s source=%s",
        plan.search_news,
        plan.search_law,
        plan.source,
    )

    tasks: list[asyncio.Task[list[dict]]] = []
    force = plan.source in ("heuristic", "router")
    if plan.search_law:
        tasks.append(
            asyncio.create_task(
                search_philippine_law(query, rag_chunk_count, force=force)
            )
        )
    if plan.search_news:
        tasks.append(
            asyncio.create_task(search_philippine_legal_news(query, force=force))
        )

    if not tasks:
        return []

    batches = await asyncio.gather(*tasks)
    return _merge_results(list(batches), max_total=_MAX_MERGED_RESULTS)


def format_tavily_context(results: list[dict]) -> str:
    """Format Tavily results into a Markdown block for injection into the system prompt."""
    if not results:
        return ""

    parts: list[str] = []
    for r in results:
        title = r.get("title") or "Untitled"
        url = r.get("url", "")
        content = r.get("content", "")

        words = content.split()
        body = " ".join(words[:_MAX_CONTENT_WORDS])
        if len(words) > _MAX_CONTENT_WORDS:
            body += " …"

        source_line = f"[{title}]({url})" if url else title
        parts.append(f"{source_line}\n{body}")

    joined = "\n\n---\n\n".join(parts)

    return (
        "\n\n## REAL-TIME PHILIPPINE LEGAL INFORMATION\n\n"
        "The following excerpts were retrieved in real time from trusted Philippine "
        "government, legal reference, and major news websites to supplement your "
        "knowledge with current information. Use these only when relevant to the "
        "user's query and cite the source URL when referencing this content. News "
        "articles report events — distinguish reporting from enacted law or official "
        "issuances. Do not treat these as exhaustive — always recommend consulting a "
        "licensed attorney for formal action.\n\n"
        f"{joined}\n\n"
        "---\n"
    )
