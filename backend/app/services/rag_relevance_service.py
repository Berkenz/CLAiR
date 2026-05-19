"""
LLM relevance grading for retrieved law chunks.

After vector search, each candidate excerpt is judged against the user's
actual question so unrelated statutes/cases are not injected or shown.
"""

from __future__ import annotations

import logging
import re

from app.config import settings
from app.services.llm_completion import AllProvidersRateLimitedError, chat_completion
from app.services.rag_router_service import _format_history_snippet

logger = logging.getLogger(__name__)

_GRADER_SYSTEM = (
    "You are a strict relevance judge for Philippine legal retrieval in CLAiR.\n"
    "Given the user's question and numbered law excerpts, label EACH excerpt.\n\n"
    "YES — The excerpt directly helps answer this specific question: same legal "
    "topic, applicable rights, penalties, procedures, or the statute the user asked about.\n\n"
    "NO — Different subject matter, only loose keyword overlap, wrong law type "
    "(e.g. unrelated GR case when user asks about an RA), boilerplate/navigation text, "
    "or cannot substantively help answer this question.\n\n"
    "Output exactly one line per excerpt: \"<index> YES\" or \"<index> NO\" "
    "(index is 1-based). No other text."
)

_VERDICT_RE = re.compile(r"^\s*(\d+)\s+(YES|NO)\s*$", re.IGNORECASE | re.MULTILINE)


def _excerpt_preview(chunk: dict, *, max_words: int = 160) -> str:
    num = chunk.get("number") or "Unknown"
    title = (chunk.get("title") or "")[:220]
    words = (chunk.get("text") or "").split()
    body = " ".join(words[:max_words])
    if len(words) > max_words:
        body += " …"
    return f"{num} — {title}\n{body}"


def _parse_verdicts(raw: str, n: int) -> dict[int, bool]:
    verdicts: dict[int, bool] = {}
    for m in _VERDICT_RE.finditer(raw or ""):
        idx = int(m.group(1))
        verdicts[idx] = m.group(2).upper() == "YES"
    if len(verdicts) >= n:
        return verdicts
    # Fallback: scan line by line
    for line in (raw or "").splitlines():
        parts = line.strip().split()
        if len(parts) >= 2 and parts[0].isdigit():
            idx = int(parts[0])
            verdicts[idx] = parts[1].upper().startswith("Y")
    return verdicts


async def filter_chunks_by_relevance(
    query: str,
    chunks: list[dict],
    history: list[dict[str, str]] | None = None,
) -> list[dict]:
    """
    Return only chunks the LLM judges as directly relevant to *query*.

    Chunks tagged with ``_exact_statute_lookup`` (RA/PD number fetch) are kept
    without grading when they match a topic expansion number.
    """
    if not chunks:
        return []
    if not settings.RAG_RELEVANCE_FILTER_ENABLED:
        return chunks

    to_grade: list[tuple[int, dict]] = []
    kept: list[dict] = []

    for i, chunk in enumerate(chunks):
        if chunk.get("_exact_statute_lookup"):
            kept.append(chunk)
        else:
            to_grade.append((i, chunk))

    if not to_grade:
        return kept

    lines = [
        f"[{j + 1}]\n{_excerpt_preview(chunk)}"
        for j, (_, chunk) in enumerate(to_grade)
    ]
    user_block = (
        f"Recent conversation:\n{_format_history_snippet(history)}\n\n"
        f"User question:\n{query.strip()}\n\n"
        f"Excerpts ({len(lines)}):\n\n" + "\n\n".join(lines)
    )
    messages = [
        {"role": "system", "content": _GRADER_SYSTEM},
        {"role": "user", "content": user_block},
    ]

    try:
        raw = await chat_completion(
            messages,
            max_tokens=min(8 * len(lines) + 16, 256),
            temperature=0.0,
            preferred_groq_model=settings.GROQ_RAG_ROUTER_MODEL,
        )
    except AllProvidersRateLimitedError:
        logger.warning("RAG relevance grader rate-limited; keeping high-similarity only")
        return _fallback_similarity_only(kept, to_grade)
    except Exception:
        logger.exception("RAG relevance grader failed; keeping high-similarity only")
        return _fallback_similarity_only(kept, to_grade)

    verdicts = _parse_verdicts(raw, len(to_grade))
    for j, (_, chunk) in enumerate(to_grade):
        if verdicts.get(j + 1, False):
            kept.append(chunk)
        else:
            logger.info(
                "RAG relevance: dropped %s (grader NO)",
                chunk.get("number") or chunk.get("title", "")[:40],
            )

    if not kept and to_grade:
        # If grader rejected everything, keep the strongest vector match only.
        best = max(
            (c for _, c in to_grade),
            key=lambda c: float(c.get("similarity") or 0.0),
        )
        if float(best.get("similarity") or 0.0) >= settings.RAG_RELEVANCE_FALLBACK_MIN_SIMILARITY:
            logger.info(
                "RAG relevance: grader rejected all; keeping top match %s (%.3f)",
                best.get("number"),
                float(best.get("similarity") or 0.0),
            )
            kept.append(best)
        else:
            logger.info("RAG relevance: all %d candidates rejected", len(chunks))
    return kept


def _fallback_similarity_only(
    kept: list[dict],
    to_grade: list[tuple[int, dict]],
) -> list[dict]:
    """When the grader is unavailable, keep only very strong vector matches."""
    floor = settings.RAG_RELEVANCE_FALLBACK_MIN_SIMILARITY
    for _, chunk in to_grade:
        if float(chunk.get("similarity") or 0.0) >= floor:
            kept.append(chunk)
    return kept
