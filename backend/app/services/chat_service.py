import asyncio
import math
import re

from groq import AsyncGroq
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.services.lawyer_chat_feedback_context import (
    build_global_lawyer_feedback_context_block,
)
from app.services.lawyer_service import lawyer_service
from app.services.reverse_geocode import reverse_geocode_area_label
from app.services.tavily_service import format_tavily_context, search_philippine_law
from app.services.vector_service import format_rag_context, get_relevant_chunks

# Compact but complete system prompt — every sentence earns its tokens.
SYSTEM_INSTRUCTION = (
    "You are CLAiR, a warm, empathetic AI legal assistant specializing in Philippine law. "
    "Use the user's message and prior turns to infer intent; give the most helpful answer you can "
    "with the information you have.\n\n"
    "## CONVERSATION RULES\n"
    "1. **Answer first.** Lead with a clear, substantive explanation (law, typical process, options, "
    "risks) grounded in the provided context chunks and chat history. Fill reasonable gaps with "
    "general Philippine-law guidance and label uncertainty plainly (e.g. 'Typically…', 'This can "
    "depend on…').\n"
    "2. **Clarify only when necessary.** Ask one or a few focused questions only if something "
    "essential is missing or ambiguous and would materially change the answer (e.g. employer vs "
    "independent contractor, criminal vs civil, which court level). Do not stall with generic "
    "fact-gathering when the user already gave enough to be useful.\n"
    "3. **No invented facts.** Do not assert specific dates, amounts, or party names the user did "
    "not state; use hypotheticals or ranges where helpful.\n"
    "4. **Optional recap.** If the situation is complex, briefly mirror what you understood before "
    "your main answer; otherwise skip straight to substance.\n"
    "5. **Invite follow-up** at the end of substantive answers so they can add details.\n\n"
    "## LEGAL RULES\n"
    "- Responses are for information only — not legal advice.\n"
    "- Always recommend consulting a licensed attorney before signing documents or taking formal action.\n\n"
    "## PARTNER LAWYERS (only when the prompt lists nearby CLAiR partners)\n"
    "Infer the user's matter from their message and **recent turns**. If it plausibly involves work that "
    "matches a listed partner's **practice areas** (and showing local counsel would help — not for "
    "pure abstract trivia or pay-rate math you can answer from statute alone), include "
    "`[[SUGGEST_LAWYERS]]` once and add one short sentence on why those specialties fit. "
    "Skip the marker when no listed partner's practice areas reasonably match.\n\n"
    "## FORMAT\n"
    "Use Markdown: **bold** for key terms, numbered lists for steps, bullets for conditions, "
    "### headings for multi-topic answers, > blockquotes for statute citations. "
    "Keep paragraphs short. End with an italicised disclaimer when appropriate."
)

# Keep only the most recent N messages to bound history token cost.
# 8 messages = 4 back-and-forth turns — enough for context without runaway growth.
_MAX_HISTORY_MESSAGES = 8

_LOCALE_REPLY_RULES: dict[str, str] = {
    "en": (
        "\n\n## OUTPUT LANGUAGE\n"
        "Reply entirely in English. Keep Markdown formatting as usual."
    ),
    "fil": (
        "\n\n## OUTPUT LANGUAGE\n"
        "Mag-reply nang buo sa Filipino (Tagalog). Panatilihin ang Markdown formatting. "
        "Gumamit ng natural na legal vocabulary sa Filipino kung angkop."
    ),
    "ceb": (
        "\n\n## OUTPUT LANGUAGE\n"
        "Tubaga tanan sa Cebuano (Bisaya). Ipadayon ang Markdown formatting. "
        "Gamita ang natural nga legal vocabulary sa Cebuano kung angayan."
    ),
}

_FALLBACK_NO_REPLY: dict[str, str] = {
    "en": "Sorry, I couldn't generate a response. Please try again.",
    "fil": "Pasensya na, hindi ako makapagbigay ng sagot. Pakisubukan muli.",
    "ceb": "Pasensya na, dili ko makahimo og tubag. Palihug sulayi pag-usab.",
}

_TITLE_LOCALE_LINE: dict[str, str] = {
    "en": "Write the title in English.",
    "fil": "Isulat ang pamagat sa Filipino.",
    "ceb": "Isulat ang pamagat sa Cebuano.",
}


def _locale_rule(locale: str) -> str:
    return _LOCALE_REPLY_RULES.get(locale, _LOCALE_REPLY_RULES["en"])

# Title generation uses the fast 8B model — quality is fine for a short label.
_CHAT_MODEL = "llama-3.3-70b-versatile"
_TITLE_MODEL = "llama-3.1-8b-instant"

_client: AsyncGroq | None = None


def _get_client() -> AsyncGroq:
    global _client
    if _client is None:
        _client = AsyncGroq(api_key=settings.GROQ_API_KEY)
    return _client


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Great-circle distance in kilometres between two coordinate pairs."""
    r = 6371.0
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(d_lng / 2) ** 2
    )
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


# When the LLM includes this marker in its reply, the backend strips it and
# returns the nearby lawyers list so the mobile app can show profile cards.
_SUGGEST_MARKER = "[[SUGGEST_LAWYERS]]"

# Shared between topic scoring and “show cards even without [[SUGGEST_LAWYERS]]”.
_NOTARIAL_DOC_USER_HINTS: frozenset[str] = frozenset(
    {
        "affidavit",
        "affidavit of loss",
        "notary",
        "notarial",
        "notarize",
        "jurat",
        "acknowledgment",
        "special power of attorney",
        "authentication",
        "red ribbon",
    }
)
_NOTARIAL_DOC_AREA_FRAGMENTS: frozenset[str] = frozenset(
    {
        "civil",
        "notarial",
        "notary",
        "general",
        "documentation",
        "contracts",
    }
)


def _user_message_seeks_notarial_document_help(text: str) -> bool:
    """User is asking where/how to get notarial work (affidavit, SPA, etc.)."""
    t = text.lower()
    return any(h in t for h in _NOTARIAL_DOC_USER_HINTS)


# User message hints → substrings we expect in `practice_areas` (lowercased) for a match.
_PRACTICE_TOPIC_GROUPS: tuple[tuple[frozenset[str], frozenset[str]], ...] = (
    (
        frozenset(
            {
                "real estate",
                "property",
                " lot ",
                " land ",
                "condo",
                "subdivision",
                "ejectment",
                "deed of sale",
                "title transfer",
                "torrens",
                "leasehold",
                "lessor",
                "lessee",
                "buying a lot",
                "selling a lot",
                "land dispute",
            }
        ),
        frozenset({"real estate", "property", "land", "conveyanc", "lease", "titling"}),
    ),
    (
        frozenset(
            {
                "labor",
                "employment",
                "termination",
                "overtime",
                "nlrc",
                "holiday pay",
                "salary",
                "wage",
                "union",
                "collective bargaining",
                "constructive dismissal",
                "illegal dismissal",
                "labor arb",
            }
        ),
        frozenset({"labor", "employment", "industrial"}),
    ),
    (
        frozenset(
            {
                "annulment",
                "custody",
                "adoption",
                "divorce",
                "marriage",
                "visitation",
                "alimony",
                "child support",
                "spousal support",
            }
        ),
        frozenset({"family", "marital", "domestic"}),
    ),
    (
        frozenset(
            {
                "criminal",
                "bail",
                "accused",
                "charged with",
                "warrant of arrest",
                "theft",
                "murder",
                "rape",
            }
        ),
        frozenset({"criminal", "litigation"}),
    ),
    (
        frozenset(
            {
                "corporation",
                "articles of incorporation",
                "by-laws",
                "shareholder",
                "board of directors",
                "sec registration",
                "startup",
            }
        ),
        frozenset({"corporate", "commercial", "business", "securities"}),
    ),
    (
        frozenset(
            {
                "tax",
                "bir",
                "withholding tax",
                "estate tax",
                "income tax",
                "vat",
            }
        ),
        frozenset({"tax", "taxation"}),
    ),
    (
        _NOTARIAL_DOC_USER_HINTS,
        _NOTARIAL_DOC_AREA_FRAGMENTS,
    ),
)


_LOOSE_PRACTICE_TOKENS: frozenset[str] = frozenset(
    {"general", "litigation", "counsel", "consultation", "advisory"}
)


def _lawyer_topic_scores(message: str, lawyers: list[dict]) -> list[tuple[int, dict]]:
    """Score each lawyer: curated topic groups, full practice label in message, token overlap."""
    if not lawyers:
        return []
    t = message.lower()
    scored: list[tuple[int, dict]] = []
    for law in lawyers:
        score = 0
        areas_joined = " ".join(law.get("practice_areas") or []).lower()
        for user_needles, area_frags in _PRACTICE_TOPIC_GROUPS:
            if not any(n in t for n in user_needles):
                continue
            if any(af in areas_joined for af in area_frags):
                score += 6
        for raw in law.get("practice_areas") or []:
            a = raw.strip().lower()
            if len(a) >= 5 and a in t:
                score += 5
            for w in re.findall(r"[a-z]+", a):
                if len(w) < 6 or w in _LOOSE_PRACTICE_TOKENS:
                    continue
                if re.search(rf"\b{re.escape(w)}\b", t):
                    score += 3
        scored.append((score, law))
    return scored


def _max_topic_alignment_score(message: str, lawyers: list[dict]) -> int:
    scored = _lawyer_topic_scores(message, lawyers)
    return max((s for s, _ in scored), default=0)


def _prefer_topic_matched_lawyers(message: str, lawyers: list[dict]) -> list[dict]:
    """Prefer partners whose practice areas fit the topic; otherwise keep full nearby list."""
    if not lawyers:
        return []
    scored = _lawyer_topic_scores(message, lawyers)
    best = max((s for s, _ in scored), default=0)
    if best >= 5:
        return [l for s, l in scored if s >= 5]
    return lawyers


def _user_message_indicates_guidance_or_situation(text: str, locale: str = "en") -> bool:
    """True when the user is asking for help or describing a situation (not e.g. 'thanks')."""
    t = text.strip().lower()
    if not t:
        return False
    if "?" in text:
        return True
    if len(t) >= 56:
        return True
    prefixes = (
        "how ",
        "what ",
        "when ",
        "where ",
        "why ",
        "who ",
        "should i",
        "should we",
        "can i ",
        "can we",
        "can my ",
        "could i ",
        "could we",
        "is it ",
        "are my ",
        "are we",
        "are the ",
        "would i ",
        "do i ",
        "do we ",
        "does my ",
        "does the ",
        "i need",
        "i want",
        "i have ",
        "we have ",
        "i was ",
        "i've been",
        "ive been",
        "i am ",
        "i'm ",
        "im ",
        "my ",
        "our ",
        "help me",
        "please ",
        "explain ",
    )
    if any(t.startswith(p) for p in prefixes):
        return True
    if locale in ("fil", "ceb", "tl"):
        if any(
            t.startswith(p)
            for p in (
                "paano",
                "ano ",
                "saan ",
                "kailan ",
                "bakit ",
                "pwed",
                "pano ",
                "paki",
                "unsa",
                "asa ",
                "kanus",
            )
        ):
            return True
    return False


def _backend_should_attach_partner_cards(
    message: str,
    topic_for_match: str,
    nearby_lawyers: list[dict],
    locale: str,
) -> bool:
    """Surface partner cards without the model marker when the matter aligns with nearby practices."""
    if _user_message_seeks_notarial_document_help(message):
        return True
    if not _user_message_indicates_guidance_or_situation(message, locale):
        return False
    return _max_topic_alignment_score(topic_for_match, nearby_lawyers) >= 5


def _topic_context_for_partner_match(message: str, history: list[dict[str, str]]) -> str:
    """Recent user + assistant text so practice matching reflects thread context."""
    parts: list[str] = [message.strip()]
    for msg in reversed(history[-_MAX_HISTORY_MESSAGES:]):
        role = msg.get("role", "")
        if role not in ("user", "human", "model", "assistant"):
            continue
        t = (msg.get("text") or "").strip()
        if t:
            parts.append(t)
    return " ".join(parts)[:2000]


def _suppress_lawyer_cards_for_message(text: str) -> bool:
    """Hide lawyer cards for clear statute / rate-of-pay Q&A (model may still emit the marker)."""
    if _user_message_seeks_nearby_lawyers(text):
        return False
    t = text.lower()
    if any(
        x in t
        for x in (
            "lawyer",
            "abogado",
            "attorney",
            "counsel",
            "litigation",
            "lawsuit",
            "sue ",
            "suing",
            "file a case",
            "file a complaint",
            "nlrc",
        )
    ):
        return False
    labor_or_rate_info = (
        "how much is the premium",
        "how much is premium",
        "how much premium",
        "premium for working",
        "premium for work",
        "holiday pay",
        "holiday premium",
        "regular holiday",
        "special holiday",
        "rest day pay",
        "rest day premium",
        "overtime pay",
        "night differential",
        "service incentive leave",
        " 13th month",
        "thirteenth month",
        "what is the premium",
        "what's the premium",
        "what are the premium",
        "rate for working",
        "pay for working",
    )
    return any(x in t for x in labor_or_rate_info)


def _user_message_seeks_nearby_lawyers(text: str) -> bool:
    """Heuristic: user wants to find / browse lawyers (not merely mentioning 'court')."""
    t = text.lower()
    needles = (
        "near me",
        "lawyers near",
        "lawyer near",
        "find a lawyer",
        "find lawyer",
        "looking for a lawyer",
        "looking for lawyer",
        "need a lawyer",
        "need lawyer",
        "recommend a lawyer",
        "hire a lawyer",
        "abogado",
        "may abogado",
        "law firm",
        "closest lawyer",
        "lawyer in my area",
        "lawyer around",
        "lawyer nearby",
        "any lawyer",
        "locate a lawyer",
        "attorney near",
        "attorneys near",
        "lawyer in the area",
        "lawyers in the area",
        "lawyers in your area",
        "lawyer in your area",
    )
    return any(n in t for n in needles)


async def _build_location_context(
    db: AsyncSession,
    user_lat: float,
    user_lng: float,
    *,
    area_label: str | None = None,
    radius_km: float = 50.0,
    max_lawyers: int = 5,
) -> tuple[str, list[dict]]:
    """
    Returns (context_text, nearby_lawyers_list).
    context_text is injected into the system prompt.
    nearby_lawyers_list is the raw lawyer dicts for use in the API response.
    """
    all_lawyers = await lawyer_service.get_all_complete_lawyers(db)
    with_dist: list[tuple[float, dict]] = []
    for lawyer in all_lawyers:
        lat = lawyer.get("latitude")
        lng = lawyer.get("longitude")
        if lat is None or lng is None:
            continue
        dist = _haversine_km(user_lat, user_lng, lat, lng)
        with_dist.append((dist, lawyer))

    with_dist.sort(key=lambda x: x[0])

    nearby = [(d, l) for d, l in with_dist if d <= radius_km][:max_lawyers]
    if not nearby:
        nearby = [(d, l) for d, l in with_dist if d <= 120.0][:max_lawyers]

    lines = [
        "\n\n## USER LOCATION (from the mobile app)\n"
        "The user's device has shared **approximate GPS** with you for this request only. "
        "**Do not** print raw coordinates, precise pins, or street-level claims. "
        "You **may** tailor answers to their part of the Philippines (courts, agencies, "
        "regional rules, practical next steps).\n"
        "**Never** tell the user you lack their location when this section is present — "
        "you have approximate area context; describe it in plain language (city/province "
        "level), not as surveillance.\n",
    ]
    if area_label:
        lines.append(
            f"- **Inferred general area (best effort):** {area_label}\n"
            "Use this label when referring to where they likely are; it may be off by "
            "a few kilometres.\n"
        )
    else:
        lines.append(
            "- A city/province label could not be resolved this time; still use the "
            "coordinates only internally for regional tailoring — never print them.\n"
        )

    if nearby:
        lines.append("\n### Nearby CLAiR Partner Lawyers")
        for dist_km, lawyer in nearby:
            name = lawyer.get("display_name") or (
                f"Atty. {lawyer.get('first_name', '')} {lawyer.get('last_name', '')}".strip()
            )
            areas = ", ".join(lawyer.get("practice_areas") or []) or "General practice"
            lines.append(f"- **{name}** ({areas}) — approx. {dist_km:.1f} km away")
        lines.append(
            f"\nRead each partner's **practice areas** and compare them to the user's question and "
            f"recent chat context. Include the exact text `{_SUGGEST_MARKER}` when:\n"
            f"- they ask to find, compare, or hire lawyers, want a referral, or need representation; "
            f"**or**\n"
            f"- their matter reasonably fits one or more partners' specialties and local counsel "
            f"would materially help (name why it fits in one sentence).\n"
            f"**Do not** use `{_SUGGEST_MARKER}` for general information, definitions, **statutory "
            f"premium or pay rates**, or when no partner's listed practice areas plausibly match."
        )
    else:
        lines.append(
            "\nNo CLAiR partner lawyers are currently registered near this location."
        )

    nearby_dicts = [lawyer for _, lawyer in nearby]
    return "".join(lines), nearby_dicts


def _build_messages(
    message: str,
    history: list[dict[str, str]],
    rag_context: str,
    locale: str,
    lawyer_feedback_block: str = "",
) -> list[dict[str, str]]:
    """Convert CLAiR history format → Groq messages list, capping history length."""
    system_content = (
        SYSTEM_INSTRUCTION
        + rag_context
        + lawyer_feedback_block
        + _locale_rule(locale)
    )

    messages: list[dict[str, str]] = [{"role": "system", "content": system_content}]

    # Cap history — take the most recent N messages to limit token cost.
    recent = history[-_MAX_HISTORY_MESSAGES:] if len(history) > _MAX_HISTORY_MESSAGES else history
    for msg in recent:
        # Gemini uses "model" as the assistant role; Groq uses "assistant"
        role = "assistant" if msg["role"] == "model" else msg["role"]
        messages.append({"role": role, "content": msg["text"]})

    messages.append({"role": "user", "content": message})
    return messages


def _rag_sources_from_chunks(chunks: list[dict]) -> list[dict]:
    out: list[dict] = []
    for c in chunks:
        sim = c.get("similarity")
        try:
            sim_f = float(sim) if sim is not None else 0.0
        except (TypeError, ValueError):
            sim_f = 0.0
        out.append(
            {
                "number": c.get("number"),
                "title": (c.get("title") or "")[:400],
                "category": c.get("category"),
                "similarity": round(sim_f, 4),
                "source_url": c.get("source_url"),
            }
        )
    return out


async def get_chat_response(
    message: str,
    history: list[dict[str, str]],
    db: AsyncSession | None = None,
    user_lat: float | None = None,
    user_lng: float | None = None,
    locale: str = "en",
) -> tuple[str, list[dict], list[dict], bool, list[dict]]:
    """Returns (reply_text, suggested_lawyers, rag_sources, rag_enabled, tavily_sources).

    suggested_lawyers is non-empty when (a) the model included [[SUGGEST_LAWYERS]] and
    the topic is not suppressed as pure rate/statute Q&A, or (b) the user's message
    clearly asks for nearby lawyers and GPS matched partners, or (c) GPS matched
    partners and the backend infers the question aligns with their listed practice
    areas (topic groups + practice-label token overlap) while the message looks like
    a genuine guidance request — the model may omit the marker, so the server fills cards.

    rag_sources lists retrieved law chunks (same as injected into the prompt).
    rag_enabled is True when SUPABASE_DB_URL and EMBED_SERVICE_URL are set
    (retrieval was attempted; rag_sources may still be empty).

    tavily_sources lists real-time web results from trusted PH legal domains,
    injected when the query is time-sensitive or RAG returned no chunks.
    """
    rag_enabled = bool(settings.SUPABASE_DB_URL and settings.EMBED_SERVICE_URL)

    chunks_task = asyncio.create_task(get_relevant_chunks(message))
    geo_task = None
    if user_lat is not None and user_lng is not None:
        geo_task = asyncio.create_task(reverse_geocode_area_label(user_lat, user_lng))

    chunks = await chunks_task
    rag_sources = _rag_sources_from_chunks(chunks)
    rag_context = format_rag_context(chunks)

    # Supplement with real-time search from trusted Philippine legal domains.
    tavily_results = await search_philippine_law(message, rag_chunk_count=len(chunks))
    rag_context = rag_context + format_tavily_context(tavily_results)

    area_label: str | None = None
    if geo_task is not None:
        area_label = await geo_task

    nearby_lawyers: list[dict] = []
    if db is not None and user_lat is not None and user_lng is not None:
        location_context, nearby_lawyers = await _build_location_context(
            db, user_lat, user_lng, area_label=area_label
        )
        rag_context = rag_context + location_context

    lawyer_feedback_block = ""
    if db is not None:
        lawyer_feedback_block = await build_global_lawyer_feedback_context_block(db)

    messages = _build_messages(
        message, history, rag_context, locale, lawyer_feedback_block
    )

    client = _get_client()
    response = await client.chat.completions.create(
        model=_CHAT_MODEL,
        messages=messages,
        max_tokens=1024,
        temperature=0.7,
    )

    content = response.choices[0].message.content or _FALLBACK_NO_REPLY.get(
        locale, _FALLBACK_NO_REPLY["en"]
    )

    suppress_cards = _suppress_lawyer_cards_for_message(message)
    had_marker = _SUGGEST_MARKER in content
    if had_marker:
        content = content.replace(_SUGGEST_MARKER, "").strip()

    topic_for_partners = _topic_context_for_partner_match(message, history)

    suggested: list[dict] = []
    if nearby_lawyers and not suppress_cards:
        if had_marker:
            suggested = _prefer_topic_matched_lawyers(topic_for_partners, nearby_lawyers)
        elif _user_message_seeks_nearby_lawyers(message):
            # Model often omits the marker; still return cards when intent + GPS match.
            suggested = nearby_lawyers
        elif _backend_should_attach_partner_cards(
            message, topic_for_partners, nearby_lawyers, locale
        ):
            suggested = _prefer_topic_matched_lawyers(topic_for_partners, nearby_lawyers)

    return content, suggested, rag_sources, rag_enabled, tavily_results


_TITLE_SYSTEM = (
    "You label conversations for a Philippine legal-assistant app (like ChatGPT "
    "history titles). Output exactly one line: a short, neutral folder-style topic name.\n"
    "- Length: 3–8 words (prefer 4–6). Plain text only — no quotes, no markdown, "
    "no trailing period.\n"
    "- Capture the main legal subject and intent in generalized form "
    "(e.g. land dispute, eviction, employment termination, BP 22).\n"
    "- Do **not** echo the user's opening or filler ('I need help', 'Can you', "
    "'Hello') — distill the substance only.\n"
    "- Only include places, courts, dates, or personal names if the user "
    "explicitly stated them; never invent or import them from elsewhere.\n"
    "- Avoid sensitive specifics; history titles should be safe and skimmable.\n"
    "Examples: 'Land dispute overview and next steps', "
    "'Tenant rights after eviction notice', 'Reviewing an employment contract'."
)

_TITLE_USER_MAX = 600

# Titles this generic are not useful in the sidebar (prefer a retry or fallback).
_TITLE_TOO_GENERIC: frozenset[str] = frozenset(
    {
        "legal question",
        "legal help",
        "need help",
        "help needed",
        "general question",
        "law question",
        "philippine law",
        "legal inquiry",
        "new conversation",
        "new chat",
    }
)


def _title_too_vague(title: str) -> bool:
    """Reject empty, ultra-short, or useless labels — not ChatGPT-length titles."""
    t = title.strip()
    if not t:
        return True
    words = t.split()
    n = len(words)
    if n < 2:
        return True
    # Allow compact 2-word labels (e.g. "Land law"); block tiny noise.
    if n == 2 and len(t) < 8:
        return True
    if n >= 3 and len(t) < 8:
        return True
    low = t.lower()
    if low in _TITLE_TOO_GENERIC:
        return True
    return False


_TOPIC_FALLBACK_PREFIXES: tuple[str, ...] = (
    "i need help with ",
    "i need help ",
    "can you help me with ",
    "can you help with ",
    "can you help me ",
    "can you help ",
    "please help with ",
    "please help me with ",
    "help me with ",
    "help with ",
    "i would like help with ",
    "i'd like help with ",
)


def _effective_fallback_title(user_message: str, fallback_title: str) -> str:
    """Strip chatty openers so failed model runs do not use the full first line as title."""
    t = user_message.strip()
    if not t:
        return fallback_title[:200]
    low = t.lower()
    for prefix in _TOPIC_FALLBACK_PREFIXES:
        if low.startswith(prefix):
            rest = t[len(prefix) :].strip()
            rest_low = rest.lower()
            for art in ("a ", "an ", "the "):
                if rest_low.startswith(art):
                    rest = rest[len(art) :].strip()
                    break
            rest = rest.strip(" .!?")
            if len(rest) >= 4:
                return (rest[0].upper() + rest[1:])[:200]
            break
    return fallback_title[:200]


async def generate_conversation_title(
    user_message: str,
    _assistant_reply: str,
    *,
    fallback_title: str,
    locale: str = "en",
) -> str:
    """Derive a descriptive history title from the first user message.

    The assistant reply is not passed to the title model: it often contains
    nearby-lawyer locations (GPS/office) that must not be reflected in the title.
    """
    um = user_message.strip()
    if not um:
        return fallback_title[:200]

    def _fb() -> str:
        return _effective_fallback_title(um, fallback_title)

    lang_line = _TITLE_LOCALE_LINE.get(locale, _TITLE_LOCALE_LINE["en"])

    # Use only the user turn here. The assistant reply often includes nearby-lawyer
    # locations (GPS/office addresses) that must not become the conversation title.
    prompt = (
        f"User message:\n{um[:_TITLE_USER_MAX]}\n\n"
        "Reply with the title line only: 3–8 words, topic-style, not a verbatim "
        "copy of their sentence."
    )

    try:
        client = _get_client()
        response = await client.chat.completions.create(
            model=_TITLE_MODEL,
            messages=[
                {
                    "role": "system",
                    "content": f"{_TITLE_SYSTEM}\n\n{lang_line}",
                },
                {"role": "user", "content": prompt},
            ],
            max_tokens=64,
            temperature=0.3,
        )
        raw = (response.choices[0].message.content or "").strip()
        if not raw:
            return _fb()

        one_line = " ".join(raw.split())
        for prefix in ("title:", "conversation:"):
            if one_line.lower().startswith(prefix):
                one_line = one_line[len(prefix):].strip()
        one_line = one_line.strip("\"'\u201c\u201d")
        if len(one_line) > 200:
            one_line = one_line[:197] + "..."

        return one_line if not _title_too_vague(one_line) else _fb()
    except Exception:
        return _fb()
