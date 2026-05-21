"""
LLM router: decide whether a user turn needs real-time web search (Tavily).

Complements keyword heuristics in tavily_service — catches case status, arrests,
and "what's happening now" questions that lack words like "latest news".
"""

from __future__ import annotations

import logging
import re

from app.config import settings
from app.services.llm_completion import AllProvidersRateLimitedError, chat_completion

logger = logging.getLogger(__name__)

_ROUTER_SYSTEM = (
    "You route real-time web search for CLAiR, a Philippine legal assistant.\n"
    "Given the user's latest message and brief recent conversation, output exactly one word:\n"
    "YES — the user needs current or real-time information from the web before answering.\n"
    "NO — general Philippine legal knowledge (definitions, typical procedures, "
    "established statutes) is enough; no need for today's news or live status.\n\n"
    "Output YES when the user asks about:\n"
    "- Recent or breaking news, headlines, or current events (especially legal/court/government).\n"
    "- Whether something is happening now or will happen soon (arrest, charges, warrant, "
    "ruling, bill passage, executive action, agency order).\n"
    "- The latest/current status, update, or development on a person, case, bill, or policy.\n"
    "- Newly signed, passed, or published laws, circulars, or IRRs they treat as \"new\" or \"just\".\n"
    "- What changed recently, what's in the news, or up-to-date facts they do not already have.\n"
    "- Follow-ups that continue a thread about current developments (use recent turns).\n\n"
    "Output NO when the user:\n"
    "- Greets, thanks, or makes small talk.\n"
    "- Asks timeless legal explanations (what is estafa, elements of theft, general steps).\n"
    "- Describes a personal situation without asking for news (eviction help, need affidavit).\n"
    "- Only asks what CLAiR can do.\n\n"
    "When unsure, prefer NO unless they clearly want information from \"now\" or \"recently\".\n"
    "Reply with YES or NO only — no punctuation or explanation."
)

_YES_RE = re.compile(r"\byes\b", re.IGNORECASE)
_NO_RE = re.compile(r"\bno\b", re.IGNORECASE)


def _parse_router_decision(raw: str) -> bool | None:
    text = (raw or "").strip()
    if not text:
        return None
    first = text.split()[0].upper().rstrip(".,!?")
    if first == "YES":
        return True
    if first == "NO":
        return False
    if _YES_RE.search(text) and not _NO_RE.search(text):
        return True
    if _NO_RE.search(text) and not _YES_RE.search(text):
        return False
    return None


def _format_history_snippet(
    history: list[dict[str, str]] | None,
    *,
    max_turns: int = 4,
    max_chars: int = 1200,
) -> str:
    if not history:
        return "(no prior messages)"
    lines: list[str] = []
    for msg in history[-max_turns:]:
        role = msg.get("role", "user")
        label = "User" if role in ("user", "human") else "Assistant"
        text = (msg.get("text") or "").strip()
        if text:
            lines.append(f"{label}: {text}")
    blob = "\n".join(lines)
    if len(blob) > max_chars:
        return blob[-max_chars:]
    return blob or "(no prior messages)"


async def needs_realtime_web_search(
    message: str,
    history: list[dict[str, str]] | None = None,
) -> bool:
    """
    Return True when Tavily should run for this turn (before keyword refinement).

    On router failure returns False (keyword rules in tavily_service still apply).
    """
    if not settings.TAVILY_ROUTER_ENABLED:
        return False
    if not settings.TAVILY_API_KEY:
        return False

    text = (message or "").strip()
    if not text:
        return False

    user_block = (
        f"Recent conversation:\n{_format_history_snippet(history)}\n\n"
        f"Latest user message:\n{text}"
    )
    messages = [
        {"role": "system", "content": _ROUTER_SYSTEM},
        {"role": "user", "content": user_block},
    ]

    try:
        raw = await chat_completion(
            messages,
            max_tokens=8,
            temperature=0.0,
            preferred_groq_model=settings.GROQ_TAVILY_ROUTER_MODEL,
        )
    except AllProvidersRateLimitedError:
        logger.warning("Tavily router: all LLM providers rate-limited")
        return False
    except Exception:
        logger.exception("Tavily router failed")
        return False

    decision = _parse_router_decision(raw)
    if decision is None:
        logger.warning("Tavily router unparseable response %r", raw[:80])
        return False
    logger.info("Tavily router: needs_realtime=%s", decision)
    return decision
