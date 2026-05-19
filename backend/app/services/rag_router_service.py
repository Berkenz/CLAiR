"""
LLM router: decide whether to run Philippine-law RAG for a user turn.

Uses a fast model with conversation context so vague openers ("I have a legal concern")
do not trigger retrieval, while specific questions still do.
"""

from __future__ import annotations

import logging
import re

from app.config import settings
from app.services.llm_completion import AllProvidersRateLimitedError, chat_completion

logger = logging.getLogger(__name__)

_ROUTER_SYSTEM = (
    "You route retrieval for CLAiR, a Philippine legal assistant with a statute/case database.\n"
    "Given the user's latest message and brief recent conversation, output exactly one word:\n"
    "YES — search the law database before answering.\n"
    "NO — answer from general capability only (no database search).\n\n"
    "Output YES when the user:\n"
    "- Asks a specific legal question (rights, penalties, steps, which law applies).\n"
    "- Describes a concrete situation needing legal grounding (eviction, firing, injury, fraud, etc.).\n"
    "- Names or implies a specific law, case type, agency, or document (RA, labor case, affidavit, etc.).\n"
    "- Follows up with new legal facts after a vague opener (use recent turns).\n\n"
    "Output NO when the user:\n"
    "- Greets, thanks, says goodbye, or makes small talk.\n"
    "- Only states they need help or have a 'legal concern/issue/problem' without any topic yet.\n"
    "- Asks what CLAiR can do or how the app works.\n"
    "- Acknowledges without adding legal substance ('ok', 'thanks', 'got it').\n\n"
    "When unsure, prefer NO until the user gives enough detail to target a statute or situation.\n"
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


async def should_retrieve_legal_context(
    message: str,
    history: list[dict[str, str]] | None = None,
) -> bool:
    """
    Return True when the law library should be queried for this turn.

    Uses the configured fast LLM; on failure returns False (no spurious retrieval).
    """
    if not settings.RAG_ROUTER_ENABLED:
        return True

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
            preferred_groq_model=settings.GROQ_RAG_ROUTER_MODEL,
        )
    except AllProvidersRateLimitedError:
        logger.warning("RAG router: all LLM providers rate-limited; skipping retrieval")
        return False
    except Exception:
        logger.exception("RAG router failed; skipping retrieval")
        return False

    decision = _parse_router_decision(raw)
    if decision is None:
        logger.warning("RAG router unparseable response %r; skipping retrieval", raw[:80])
        return False

    logger.info("RAG router decision=%s for message_len=%d", "YES" if decision else "NO", len(text))
    return decision
