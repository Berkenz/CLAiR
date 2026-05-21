"""
LLM router: classify user turns for CLAiR's Philippine legal assistant.

Tiers:
- LEGAL — full legal / CLAiR capability answer
- PIVOT — related but not legal; brief help then steer to legal topics
- REJECT — far off-topic; natural redirect without answering substance
"""

from __future__ import annotations

import logging
import random
import re
from enum import Enum

from app.config import settings
from app.services.llm_completion import AllProvidersRateLimitedError, chat_completion

logger = logging.getLogger(__name__)


class ScopeTier(str, Enum):
    LEGAL = "legal"
    PIVOT = "pivot"
    REJECT = "reject"


_SCOPE_ROUTER_SYSTEM = (
    "You classify user messages for CLAiR, a Philippine legal information assistant.\n"
    "Given the latest message and brief recent conversation, output exactly one word:\n"
    "IN_SCOPE — primarily Philippine law, a legal situation, or what CLAiR can do.\n"
    "PIVOT — somewhat related but not a legal question; CLAiR may answer briefly then "
    "guide back to legal topics (e.g. general PH news without a legal problem yet, broad "
    "civics, administrative how-tos that are not mainly legal).\n"
    "OUT_OF_SCOPE — far from CLAiR's purpose; do not answer the substance.\n\n"
    "IN_SCOPE: rights, cases, contracts, courts, agencies, legal documents, CLAiR features, "
    "recent law/legal updates, vague 'legal help', continuing a legal thread.\n"
    "PIVOT: general news/headlines, non-legal PH government trivia, lifestyle/admin questions "
    "with a possible but weak legal angle — not homework, math, or entertainment.\n"
    "OUT_OF_SCOPE: arithmetic, coding homework, recipes, sports/entertainment, medical or "
    "investment advice with no legal angle, other countries' law only.\n\n"
    "When unsure between IN_SCOPE and PIVOT, choose PIVOT. When unsure between PIVOT and "
    "OUT_OF_SCOPE, choose OUT_OF_SCOPE only if clearly unrelated.\n"
    "Reply with IN_SCOPE, PIVOT, or OUT_OF_SCOPE only — no punctuation or explanation."
)

# Pure math / general homework with no legal angle — reject before the main model.
_ARITHMETIC_EXPR_RE = re.compile(
    r"^\s*(?:(?:what\s+is|how\s+much\s+is|calculate|solve|compute)\s+)?"
    r"\d+(?:\.\d+)?(?:\s*[\+\-\*\/x×÷]\s*\d+(?:\.\d+)?)+"
    r"\s*[\?=]?\s*$",
    re.IGNORECASE,
)

_CLEARLY_OFF_TOPIC_PATTERNS: tuple[re.Pattern[str], ...] = (
    re.compile(
        r"\b(write|debug|fix|create)\s+(me\s+)?(a\s+)?"
        r"(python|javascript|java|typescript|code|script|program)\b",
        re.IGNORECASE,
    ),
    re.compile(r"\b(binary\s+search|leetcode|hackerrank)\b", re.IGNORECASE),
    re.compile(
        r"\b(recipe|ingredients)\s+for\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\b(who\s+won|score\s+of|nba|nfl|premier\s+league)\b",
        re.IGNORECASE,
    ),
)

_LEGAL_HINT_RE = re.compile(
    r"\b(law|legal|right|rights|court|case|ra\s*\d|republic\s+act|batas|"
    r"tenant|contract|lawyer|attorney|philippine|affidavit|summons|penalty|"
    r"complaint|notar|annulment|divorce|estafa|bp\s*\d)\b",
    re.IGNORECASE,
)

_IN_SCOPE_RE = re.compile(r"\bIN[_\s-]?SCOPE\b", re.IGNORECASE)
_PIVOT_RE = re.compile(r"\bPIVOT\b", re.IGNORECASE)
_OUT_OF_SCOPE_RE = re.compile(r"\bOUT[_\s-]?OF[_\s-]?SCOPE\b", re.IGNORECASE)

_REDIRECT_SYSTEM: dict[str, str] = {
    "en": (
        "You are CLAiR, a warm Philippine legal information assistant. The user's latest "
        "message is outside your scope.\n"
        "Write a natural reply (3–5 short sentences, Markdown allowed):\n"
        "- Briefly acknowledge their topic by name (e.g. 'a math problem', 'coding homework') "
        "without answering it — no numbers, code, recipes, or trivia.\n"
        "- Explain that you specialize in Philippine legal information (rights, procedures, "
        "documents, when to see a lawyer).\n"
        "- One sentence on why this request isn't what you're built for.\n"
        "- Invite a specific legal question they can ask you.\n"
        "Sound human and varied — not a fixed template. No bullet lists unless one short line."
    ),
    "fil": (
        "Ikaw si CLAiR, isang legal na assistant para sa batas ng Pilipinas. Ang huling "
        "mensahe ng user ay wala sa iyong saklaw.\n"
        "Sumulat ng natural na sagot (3–5 maikling pangungusap, Markdown ay ok):\n"
        "- Kilalanin ang paksa nila nang hindi ito sinasagot — walang numero, code, recipe, o trivia.\n"
        "- Ipaliwanag na nakatuon ka sa legal na impormasyon sa Pilipinas.\n"
        "- Isang pangungusap kung bakit hindi ito ang layunin mo.\n"
        "- Anyayahan silang magtanong ng konkretong legal na katanungan.\n"
        "Maging natural at iba-iba ang tono — hindi template."
    ),
    "ceb": (
        "Ikaw si CLAiR, usa ka legal nga assistant sa balod sa Pilipinas. Ang katapusang "
        "mensahe sa user wala sa imong scope.\n"
        "Pagsulat og natural nga tubag (3–5 mubo nga sentences, Markdown ok):\n"
        "- Ilha ang ilang hilisgutan nga dili sabton — walay numero, code, recipe, o trivia.\n"
        "- Sultihi nga nakatutok ka sa legal nga impormasyon sa Pilipinas.\n"
        "- Usa ka sentence ngano dili ni imong trabaho.\n"
        "- Dapita sila ug pangutana og legal.\n"
        "Kinahanglan natural ug lahi-lahi — dili template."
    ),
}

_OFF_TOPIC_FALLBACKS: dict[str, dict[str, list[str]]] = {
    "en": {
        "math": [
            (
                "I see you're working on a **math problem** — that's outside what I'm set up for. "
                "I'm **CLAiR**, focused on **Philippine legal information** (rights, procedures, "
                "documents, and when to talk to a lawyer). If something legal is behind that "
                "question — like a fine, deadline, or contract — tell me and we can go from there."
            ),
        ],
        "coding": [
            (
                "It looks like you're asking about **programming or coding** — I can't walk through "
                "that here. I'm built for **Philippine legal topics** instead. If your situation "
                "involves a contract, IP, or a dispute, describe it and I'll help from the legal side."
            ),
        ],
        "general": [
            (
                "That's a bit outside my lane — I'm **CLAiR**, here for **Philippine legal "
                "information**, not general questions like this. I can help with rights, "
                "procedures, documents, and finding a lawyer when it fits. **What legal situation "
                "can I help you with?**"
            ),
            (
                "I appreciate the question, but it's not something I'm designed to answer. "
                "My role is **legal guidance in the Philippines** — leases, complaints, family law, "
                "work issues, and similar topics. **Tell me what's going on legally** and we'll take it from there."
            ),
        ],
    },
    "fil": {
        "math": [
            (
                "Mukhang **math** ang tanong mo — hindi iyon ang pokus ko. Para ako sa "
                "**legal na impormasyon sa Pilipinas**. Kung may legal na anggulo (multa, kontrata, deadline), "
                "sabihin mo at tutulungan kita."
            ),
        ],
        "coding": [
            (
                "Tungkol sa **programming** ang tanong — hindi ko 'yan masasagot dito. "
                "Nakatuon ako sa **legal na paksa sa Pilipinas**. Kung may kontrata o dispute, ilahad mo."
            ),
        ],
        "general": [
            (
                "Medyo labas ito sa saklaw ko — ako si **CLAiR** para sa **legal na impormasyon "
                "sa Pilipinas**. **Anong legal na sitwasyon ang maitutulong ko?**"
            ),
        ],
    },
    "ceb": {
        "math": [
            (
                "Murag **math** imong pangutana — dili ni akong focus. Para ko sa **legal nga "
                "impormasyon sa Pilipinas**. Kung naay legal nga aspeto, sultihi ko."
            ),
        ],
        "coding": [
            (
                "Mahitungod sa **programming** — dili nako masabtan dinhi. Legal nga mga tema sa "
                "Pilipinas akong gitrabahoan."
            ),
        ],
        "general": [
            (
                "Gawas ni sa akong scope — si **CLAiR** ko para sa **legal nga impormasyon sa "
                "Pilipinas**. **Unsa nga legal nga sitwasyon ang imong ikasulti?**"
            ),
        ],
    },
}

# Tokens allowed in short greetings / thanks (e.g. "hey clair", "salamat po").
_SOCIAL_TURN_WORDS = frozenset({
    "hi", "hey", "hello", "helo", "hiya", "yo",
    "kumusta", "kamusta", "musta", "ug", "maayong",
    "good", "morning", "afternoon", "evening", "day",
    "thanks", "thank", "salamat", "you", "po", "opo",
    "bye", "goodbye", "see", "later",
    "clair", "there", "na", "lang", "po",
})
_SOCIAL_OPENERS = frozenset({
    "hi", "hey", "hello", "helo", "hiya", "yo",
    "kumusta", "kamusta", "musta",
    "good", "thanks", "thank", "salamat", "bye", "goodbye",
})

# Questions about CLAiR itself or its capabilities — always answer, not off-topic.
_META_CAPABILITY_PATTERNS: tuple[re.Pattern[str], ...] = (
    re.compile(
        r"\b(what|who)\s+(is|are)\s+(you|clair)\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\bwhat\s+(can|do)\s+(you|clair)\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\bhow\s+(do|does)\s+(you|clair)\s+work\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\b(do|does|can)\s+(you|clair)\s+"
        r"(have\s+access|use|know\s+about|get|read|see|access)\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\b(are\s+you\s+able\s+to|your|clair'?s?)\s+"
        r"(capabilities?|limitations?|features?|sources?)\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\b(access|recent|latest)\s+(to\s+)?"
        r"(news|updates?|information|data|laws?|legal)\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\b(recent|latest)\s+(news|updates?|changes?)\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"\babout\s+(you|yourself|clair)\b",
        re.IGNORECASE,
    ),
)


def is_clearly_off_topic_message(message: str) -> bool:
    """True for obvious non-legal requests (e.g. 1+1, coding homework)."""
    text = (message or "").strip()
    if not text or len(text) > 400:
        return False
    if is_assistant_meta_question(text):
        return False
    if _LEGAL_HINT_RE.search(text):
        return False
    if _ARITHMETIC_EXPR_RE.match(text):
        return True
    if any(p.search(text) for p in _CLEARLY_OFF_TOPIC_PATTERNS):
        return True
    # Short message that is only a numeric expression (e.g. "1+1", "2 * 3?").
    compact = re.sub(r"\s+", "", text)
    if (
        len(compact) <= 24
        and re.fullmatch(r"[\d\.\+\-\*\/x×÷\?=]+", compact, re.IGNORECASE)
        and re.search(r"[\+\-\*\/x×÷]", compact)
    ):
        return True
    return False


def is_assistant_meta_question(message: str) -> bool:
    """True for questions about CLAiR's role, access, or capabilities."""
    text = (message or "").strip()
    if not text or len(text) > 320:
        return False
    return any(p.search(text) for p in _META_CAPABILITY_PATTERNS)


def is_greeting_or_small_talk(message: str) -> bool:
    """True for short greetings/thanks/name pings — never treat as off-topic."""
    raw = (message or "").strip()
    if not raw or len(raw) > 80:
        return False
    normalized = re.sub(r"[^\w\s]", " ", raw.lower())
    normalized = re.sub(r"\s+", " ", normalized).strip()
    if not normalized:
        return False
    words = normalized.split()
    if len(words) > 8 or not all(w in _SOCIAL_TURN_WORDS for w in words):
        return False
    if any(w in _SOCIAL_OPENERS for w in words):
        return True
    return normalized in ("clair",)


def _parse_scope_tier(raw: str) -> ScopeTier | None:
    """Map router LLM output to a scope tier, or None if unparseable."""
    text = (raw or "").strip()
    if not text:
        return None
    first = text.split()[0].upper().rstrip(".,!?").replace("-", "_")
    if first in ("OUT_OF_SCOPE", "OUTOFSCOPE"):
        return ScopeTier.REJECT
    if first == "PIVOT" or (_PIVOT_RE.search(text) and not _OUT_OF_SCOPE_RE.search(text)):
        return ScopeTier.PIVOT
    if first in ("IN_SCOPE", "INSCOPE"):
        return ScopeTier.LEGAL
    if _OUT_OF_SCOPE_RE.search(text) and not _IN_SCOPE_RE.search(text) and not _PIVOT_RE.search(text):
        return ScopeTier.REJECT
    if _PIVOT_RE.search(text) and not _OUT_OF_SCOPE_RE.search(text):
        return ScopeTier.PIVOT
    if _IN_SCOPE_RE.search(text) and not _OUT_OF_SCOPE_RE.search(text):
        return ScopeTier.LEGAL
    return None


def off_topic_category(message: str) -> str:
    """Hint for redirect tone: math, coding, or general."""
    text = (message or "").strip().lower()
    if _ARITHMETIC_EXPR_RE.match(text) or re.search(r"[\+\-\*\/]\s*\d", text):
        return "math"
    if any(
        k in text
        for k in (
            "python",
            "javascript",
            "code",
            "program",
            "leetcode",
            "binary search",
        )
    ):
        return "coding"
    return "general"


def _fallback_off_topic_redirect(message: str, locale: str) -> str:
    loc = locale if locale in _OFF_TOPIC_FALLBACKS else "en"
    cat = off_topic_category(message)
    pool = _OFF_TOPIC_FALLBACKS[loc].get(cat) or _OFF_TOPIC_FALLBACKS[loc]["general"]
    return random.choice(pool)


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


async def classify_message_scope(
    message: str,
    history: list[dict[str, str]] | None = None,
) -> ScopeTier:
    """
    Classify how CLAiR should handle this turn.

    On router failure or unparseable output, defaults to LEGAL or PIVOT (not REJECT).
    """
    if not settings.SCOPE_ROUTER_ENABLED:
        return ScopeTier.LEGAL

    text = (message or "").strip()
    if not text:
        return ScopeTier.LEGAL
    if is_greeting_or_small_talk(text) or is_assistant_meta_question(text):
        return ScopeTier.LEGAL
    if is_clearly_off_topic_message(text):
        logger.info("Scope router: clearly off-topic (heuristic)")
        return ScopeTier.REJECT

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
            max_tokens=16,
            temperature=0.0,
            preferred_groq_model=settings.GROQ_SCOPE_ROUTER_MODEL,
        )
    except AllProvidersRateLimitedError:
        logger.warning("Scope router: rate-limited; defaulting to PIVOT")
        return ScopeTier.PIVOT
    except Exception:
        logger.exception("Scope router failed; defaulting to PIVOT")
        return ScopeTier.PIVOT

    tier = _parse_scope_tier(raw)
    if tier is None:
        logger.warning("Scope router unparseable %r; defaulting to PIVOT", raw[:80])
        return ScopeTier.PIVOT

    logger.info("Scope router tier=%s message_len=%d", tier.value, len(text))
    return tier


async def generate_off_topic_redirect(
    message: str,
    history: list[dict[str, str]] | None,
    locale: str,
) -> str:
    """Natural, varied redirect for far off-topic turns (no substance answer)."""
    loc = locale if locale in _REDIRECT_SYSTEM else "en"
    user_block = (
        f"Recent conversation:\n{_format_history_snippet(history)}\n\n"
        f"Latest user message:\n{message.strip()}\n\n"
        f"Topic category hint: {off_topic_category(message)}"
    )
    messages = [
        {"role": "system", "content": _REDIRECT_SYSTEM[loc]},
        {"role": "user", "content": user_block},
    ]
    try:
        raw = await chat_completion(
            messages,
            max_tokens=220,
            temperature=0.85,
            preferred_groq_model=settings.GROQ_SCOPE_ROUTER_MODEL,
        )
        text = (raw or "").strip()
        if len(text) >= 40:
            return text
    except Exception:
        logger.exception("Off-topic redirect LLM failed; using fallback")

    return _fallback_off_topic_redirect(message, loc)


async def is_message_in_scope(
    message: str,
    history: list[dict[str, str]] | None = None,
) -> bool:
    """True when the message should reach the main legal model (LEGAL or PIVOT)."""
    tier = await classify_message_scope(message, history)
    return tier != ScopeTier.REJECT
