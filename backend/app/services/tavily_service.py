"""
Real-time web search service using Tavily, restricted to a curated whitelist
of trusted Philippine government and legal websites.

Graceful degradation: if TAVILY_API_KEY is not set, or the API call fails,
search_philippine_law() returns [] and the chatbot continues without web context.
"""

from __future__ import annotations

import asyncio
import logging

from tavily import AsyncTavilyClient

from app.config import settings

logger = logging.getLogger(__name__)

# Only results from these domains are ever returned — Tavily enforces this
# at the API level via include_domains.
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

_MAX_RESULTS = 3
_MAX_CONTENT_WORDS = 200
_MIN_QUERY_CHARS_FOR_EMPTY_RAG = 50

# Keywords that signal the user is asking about recent/current legal developments.
# When present, Tavily is triggered even if RAG already returned chunks, because
# the static pgvector DB may not yet contain the latest amendments or circulars.
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

_client: AsyncTavilyClient | None = None


def _get_client() -> AsyncTavilyClient | None:
    global _client
    if not settings.TAVILY_API_KEY:
        return None
    if _client is None:
        _client = AsyncTavilyClient(api_key=settings.TAVILY_API_KEY)
    return _client


def _is_time_sensitive(query: str) -> bool:
    """Return True if the query likely asks about recent or current legal updates."""
    q = query.lower()
    return any(kw in q for kw in _TIME_SENSITIVE_KEYWORDS)


async def search_philippine_law(
    query: str,
    rag_chunk_count: int = 0,
) -> list[dict]:
    """Search Tavily restricted to trusted Philippine legal domains.

    Triggers when:
    - The query contains time-sensitive keywords (even if RAG returned chunks), OR
    - RAG returned zero chunks (no static coverage for this topic).

    Returns a list of result dicts with keys: title, url, content, score.
    Returns [] when TAVILY_API_KEY is unset or the API call fails.
    """
    client = _get_client()
    if client is None:
        return []

    q = query.strip()
    should_search = _is_time_sensitive(q) or (
        rag_chunk_count == 0 and len(q) >= _MIN_QUERY_CHARS_FOR_EMPTY_RAG
    )
    if not should_search:
        return []

    async def _search() -> list[dict]:
        response = await client.search(
            query=f"Philippines law {q}",
            search_depth="basic",
            include_domains=TRUSTED_PH_LEGAL_DOMAINS,
            max_results=_MAX_RESULTS,
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
        logger.warning("Tavily search timed out after %.1fs", settings.TAVILY_TIMEOUT_SECONDS)
        return []
    except Exception:
        logger.exception("Tavily search failed")
        return []


def format_tavily_context(results: list[dict]) -> str:
    """Format Tavily results into a Markdown block for injection into the system prompt.

    Returns an empty string when results is empty.
    """
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
        "government and legal websites to supplement your knowledge with current "
        "information. Use these only when relevant to the user's query and cite the "
        "source URL when referencing this content. Do not treat these as exhaustive — "
        "always recommend consulting a licensed attorney for formal action.\n\n"
        f"{joined}\n\n"
        "---\n"
    )
