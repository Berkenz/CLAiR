"""
LLM router: decide whether a user turn is within CLAiR's Philippine legal scope.

Off-topic messages (programming, homework, recipes, etc.) are rejected before
the main chat model runs.
"""

from __future__ import annotations

import logging
import re

from app.config import settings
from app.services.llm_completion import AllProvidersRateLimitedError, chat_completion

logger = logging.getLogger(__name__)

_SCOPE_ROUTER_SYSTEM = (
    "You classify user messages for CLAiR, a Philippine legal information assistant.\n"
    "Given the latest message and brief recent conversation, output exactly one word:\n"
    "IN_SCOPE — CLAiR should answer (or continue a legal conversation).\n"
    "OUT_OF_SCOPE — not a legal question; CLAiR must refuse without answering the substance.\n\n"
    "Output IN_SCOPE when the user:\n"
    "- Asks about Philippine law, rights, penalties, procedures, courts, or government agencies.\n"
    "- Describes a situation that may have legal consequences in the Philippines.\n"
    "- Asks about legal documents (contracts, affidavits, complaints, notarization under PH law).\n"
    "- Greets, thanks, says goodbye, or asks what CLAiR can do.\n"
    "- Has a vague legal opener ('I need legal help', 'legal concern') even without a topic yet.\n"
    "- Follows up on a prior in-scope legal thread in the recent conversation.\n\n"
    "Output OUT_OF_SCOPE when the user:\n"
    "- Seeks general knowledge unrelated to law (programming, data structures, math/science "
    "homework, history trivia, recipes, entertainment, sports, travel tips, etc.).\n"
    "- Asks for help with non-legal school or work tasks (essays, coding bugs, calculations) "
    "unless clearly tied to a Philippine legal document or dispute.\n"
    "- Wants medical, financial investment, or relationship advice with no legal angle.\n"
    "- Asks primarily about another country's law with no Philippine-law connection.\n\n"
    "When unsure, prefer IN_SCOPE only if the message could reasonably be about Philippine law; "
    "otherwise OUT_OF_SCOPE.\n"
    "Reply with IN_SCOPE or OUT_OF_SCOPE only — no punctuation or explanation."
)

_IN_SCOPE_RE = re.compile(r"\bIN[_\s-]?SCOPE\b", re.IGNORECASE)
_OUT_OF_SCOPE_RE = re.compile(r"\bOUT[_\s-]?OF[_\s-]?SCOPE\b", re.IGNORECASE)


def _parse_scope_decision(raw: str) -> bool | None:
    """Return True if in-scope, False if out-of-scope, None if unparseable."""
    text = (raw or "").strip()
    if not text:
        return None
    first = text.split()[0].upper().rstrip(".,!?").replace("-", "_")
    if first in ("IN_SCOPE", "INSCOPE"):
        return True
    if first in ("OUT_OF_SCOPE", "OUTOFSCOPE"):
        return False
    if _OUT_OF_SCOPE_RE.search(text) and not _IN_SCOPE_RE.search(text):
        return False
    if _IN_SCOPE_RE.search(text) and not _OUT_OF_SCOPE_RE.search(text):
        return True
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


async def is_message_in_scope(
    message: str,
    history: list[dict[str, str]] | None = None,
) -> bool:
    """
    Return True when the message should be handled by the legal assistant.

    On router failure or unparseable output, defaults to True (do not block users).
    """
    if not settings.SCOPE_ROUTER_ENABLED:
        return True

    text = (message or "").strip()
    if not text:
        return True

    user_block = (
        f"Recent conversation:\n{_format_history_snippet(history)}\n\n"
        f"Latest user message:\n{text}"
    )
    messages = [
        {"role": "system", "content": _SCOPE_ROUTER_SYSTEM},
        {"role": "user", "content": user_block},
    ]

    try:
        raw = await chat_completion(
            messages,
            max_tokens=12,
            temperature=0.0,
            preferred_groq_model=settings.GROQ_SCOPE_ROUTER_MODEL,
        )
    except AllProvidersRateLimitedError:
        logger.warning("Scope router: all LLM providers rate-limited; allowing message")
        return True
    except Exception:
        logger.exception("Scope router failed; allowing message")
        return True

    decision = _parse_scope_decision(raw)
    if decision is None:
        logger.warning("Scope router unparseable response %r; allowing message", raw[:80])
        return True

    logger.info(
        "Scope router decision=%s for message_len=%d",
        "IN_SCOPE" if decision else "OUT_OF_SCOPE",
        len(text),
    )
    return decision
