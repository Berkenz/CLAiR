import asyncio
import logging
import math
import re

logger = logging.getLogger(__name__)

from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.services.llm_completion import (
    AllProvidersRateLimitedError,
    chat_completion,
)
from app.services.lawyer_chat_feedback_context import (
    build_global_lawyer_feedback_context_block,
)
from app.services.lawyer_service import lawyer_service
from app.services.reverse_geocode import reverse_geocode_area_label
from app.services.tavily_service import format_tavily_context, search_philippine_law
from app.services.rag_router_service import should_retrieve_legal_context
from app.services.scope_router_service import (
    ScopeTier,
    classify_message_scope,
    generate_off_topic_redirect,
    is_greeting_or_small_talk,
)
from app.services.vector_service import (
    align_rag_sources_with_citations,
    format_rag_context,
    get_relevant_chunks,
)

# Compact but complete system prompt — every sentence earns its tokens.
SYSTEM_INSTRUCTION = (
    "You are CLAiR, a warm, empathetic AI legal assistant specializing in Philippine law. "
    "Use the user's message and prior turns to infer intent; give the most helpful answer you can "
    "with the information you have.\n\n"
    "## SCOPE\n"
    "You specialize in **Philippine legal information**: rights, laws, procedures, documents, "
    "agencies, and when to consult a lawyer. **Also answer** questions about what CLAiR can do "
    "and its sources honestly.\n"
    "For **borderline** topics (related but not mainly legal), give a **short** helpful answer "
    "if you can, then warmly guide the user toward a **Philippine legal** question you can handle.\n"
    "Far off-topic turns are handled separately — you will not see them here.\n"
    "**Greetings and thanks are in scope** — reply warmly (e.g. hi, hey, kumusta, salamat). "
    "Never open a greeting with refusal language or lead with *I cannot provide legal advice*; "
    "save disclaimers for substantive legal answers only.\n\n"
    "## CONVERSATION RULES\n"
    "1. **Answer first.** Lead with a clear, substantive explanation (law, typical process, options, "
    "risks) grounded in the provided context chunks and chat history. Even when the user is vague "
    "('I need help', 'what should I do'), still give useful general guidance before asking for more. "
    "Fill reasonable gaps with general Philippine-law guidance and label uncertainty plainly "
    "(e.g. 'Typically…', 'This can depend on…').\n"
    "2. **Invite the next turn.** After your main answer, when more context would improve the next "
    "reply, close with a warm invitation to continue — not a hollow line like 'let me know if there's "
    "anything else'. Use a lead-in such as **If you want, tell me:** (plain text, not inside bullets), "
    "then **2–3 markdown bullet lines** (`- **prompt?**`) — one question per bullet, never one bold "
    "span covering multiple questions. Put a space before and after every `**` marker next to a word. "
    "Only ask what would materially change your next reply. **Do not** ask about something the user "
    "already stated (e.g. if they said an institution requires an affidavit of loss, do not ask what "
    "that institution requires or whether they reported it there — ask about missing details such as "
    "documents on hand, notary access, draft wording, or deadlines). Skip this block for greetings, "
    "thanks, or when they already gave enough detail for a complete answer.\n"
    "3. **Do not stall.** Never reply with *only* questions when you can already offer useful "
    "information. Do not use a generic questionnaire unrelated to their matter.\n"
    "4. **No invented facts.** Do not assert specific dates, amounts, or party names the user did "
    "not state; use hypotheticals or ranges where helpful.\n"
    "5. **Optional recap.** If the situation is complex, briefly mirror what you understood before "
    "your main answer; otherwise skip straight to substance.\n"
    "6. **Location (internal only unless relevant).** When approximate GPS context is provided, "
    "use it silently to match nearby partners and regional tailoring. **Do not** mention the "
    "user's city or region in greetings, small talk, or general answers. Only reference their "
    "area when it clearly matters — e.g. nearby lawyer referrals, which local court or office "
    "to visit, or location-specific procedures — or if they ask where they are / what's local.\n\n"
    "## LEGAL RULES\n"
    "- Responses are for information only — not legal advice.\n"
    "- Always recommend consulting a licensed attorney before signing documents or taking formal action.\n"
    "- When citing a **specific** Republic Act, Presidential Decree, or case number, use only laws "
    "that appear under **RETRIEVED PHILIPPINE LEGAL TEXT** in this prompt. If none apply, explain "
    "the topic in general terms without inventing a statute number. Always include the law number "
    "in your answer when you rely on retrieved text (e.g. **Republic Act No. 7610**) so sources "
    "match what the user sees.\n\n"
    "## PARTNER LAWYERS (only when the prompt lists nearby CLAiR partners)\n"
    "Infer the user's matter from their message and **recent turns**. If it plausibly involves work that "
    "matches a listed partner's **practice areas** (and showing local counsel would help — not for "
    "pure abstract trivia or pay-rate math you can answer from statute alone), include "
    "`[[SUGGEST_LAWYERS]]` once and write **1–2 sentences in the reply** naming the partner "
    "(e.g. **Atty. [Name]**), their **listed** practice areas, and why they fit this question. "
    "Never show a profile card without that in-chat introduction — the card alone is not enough. "
    "If at least one nearby partner's practice areas fit the matter, prefer recommending them "
    "over only saying 'consult a lawyer' in general.\n"
    "When naming a partner, cite **only** the practice areas shown in the nearby list — "
    "never claim a specialty (e.g. Labor Law) that is not listed for that lawyer. "
    "If you name a specific partner, you **must** include `[[SUGGEST_LAWYERS]]` once so "
    "the app can show their profile card.\n"
    "For **affidavit of loss**, notarization, or simple document procedures: explain the usual "
    "process first; recommend a partner only when notarial/legal help is genuinely useful, and "
    "always introduce them in prose as above.\n\n"
    "## FORMAT\n"
    "Use Markdown: **bold** for key terms, numbered lists for steps, bullets for conditions, "
    "### headings for multi-topic answers, > blockquotes for statute citations. "
    "Keep paragraphs short. On substantive replies: main answer → optional lawyer mention → "
    "**conversation invitation** (rule 2) → italic disclaimer last. "
    "End with an italicised disclaimer when appropriate. "
    "Put the disclaimer on its **own line**, separated from lists by a **blank line**. "
    "Never make the disclaimer a bullet or numbered list item, and never append it "
    "to the last list item on the same line."
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

_GREETING_REPLY: dict[str, str] = {
    "en": (
        "Hey! I'm **CLAiR**, your Philippine legal information assistant. "
        "I can help with your rights, legal procedures, documents, and finding lawyers "
        "near you.\n\n"
        "**What would you like help with today?**"
    ),
    "fil": (
        "Kumusta! Ako si **CLAiR**, ang iyong legal na assistant para sa batas ng Pilipinas. "
        "Makakatulong ako sa mga karapatan, proseso, dokumento, at paghahanap ng abogado.\n\n"
        "**Ano ang legal na tanong mo ngayon?**"
    ),
    "ceb": (
        "Kumusta! Ako si **CLAiR**, imong assistant sa legal nga impormasyon sa Pilipinas. "
        "Makatabang ko sa imong katungod, proseso, dokumento, ug pagpangita og abogado.\n\n"
        "**Unsa ang imong legal nga pangutana karon?**"
    ),
}


def _greeting_reply(locale: str) -> str:
    return _GREETING_REPLY.get(locale, _GREETING_REPLY["en"])


_PIVOT_TURN_RULE: dict[str, str] = {
    "en": (
        "\n\n## THIS TURN (borderline — not primarily legal)\n"
        "The user's message is **somewhat related** but **not a legal question**. "
        "Give a **brief, honest** answer (at most 3–4 sentences) if you can, then pivot to "
        "**Philippine legal** topics you handle (rights, procedures, documents, lawyers). "
        "Do **not** give an outright refusal or a long essay on the non-legal topic."
    ),
    "fil": (
        "\n\n## TURN NA ITO (borderline — hindi pangunahing legal)\n"
        "Ang tanong ay **may kaugnayan** ngunit **hindi legal**. Magbigay ng **maikli at tapat** "
        "na sagot kung kaya, pagkatapos ay akayin sa **legal na paksa sa Pilipinas**."
    ),
    "ceb": (
        "\n\n## KINI NGA TURN (borderline — dili primarily legal)\n"
        "Ang mensahe **may kalabutan** pero **dili legal**. Hatagi og **mubo nga tinuod** nga tubag "
        "kung mahimo, unya itudlo sa **legal nga tema sa Pilipinas**."
    ),
}

_TITLE_LOCALE_LINE: dict[str, str] = {
    "en": "Write the title in English.",
    "fil": "Isulat ang pamagat sa Filipino.",
    "ceb": "Isulat ang pamagat sa Cebuano.",
}


def _locale_rule(locale: str) -> str:
    return _LOCALE_REPLY_RULES.get(locale, _LOCALE_REPLY_RULES["en"])

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
        frozenset(
            {
                "estate",
                "estate settlement",
                "settlement of estate",
                "extrajudicial settlement",
                "without a will",
                "no will",
                "probate",
                "succession",
                "inheritance",
                "deceased",
                "heir",
                "heirs",
                "last will",
                "testament",
                "intestate",
            }
        ),
        frozenset({"estate", "succession", "probate", "civil", "family", "real estate"}),
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
    """Return only partners whose listed practice areas fit the topic."""
    if not lawyers:
        return []
    scored = _lawyer_topic_scores(message, lawyers)
    matched = [l for s, l in scored if s >= 5]
    return matched


def _lawyers_named_in_reply(content: str, lawyers: list[dict]) -> list[dict]:
    """Partners the model named in prose — show profile cards even without [[SUGGEST_LAWYERS]]."""
    if not content or not lawyers:
        return []
    t = content.lower()
    out: list[dict] = []
    seen: set[str] = set()
    for law in lawyers:
        lid = str(law.get("id") or "")
        if not lid or lid in seen:
            continue
        names: list[str] = []
        dn = (law.get("display_name") or "").strip()
        if dn:
            names.append(dn.lower())
        fn = (law.get("first_name") or "").strip()
        ln = (law.get("last_name") or "").strip()
        if fn or ln:
            names.append(f"atty. {fn} {ln}".strip().lower())
        if ln and len(ln) >= 3:
            names.append(f"atty. {ln}".lower())
        for name in names:
            if len(name) >= 5 and name in t:
                seen.add(lid)
                out.append(law)
                break
    return out


def _finalize_suggested_lawyers(
    *,
    content: str,
    message: str,
    history: list[dict[str, str]],
    nearby_lawyers: list[dict],
    had_marker: bool,
    suppress_cards: bool,
    locale: str,
) -> list[dict]:
    if not nearby_lawyers or suppress_cards:
        return []

    topic_for_partners = _topic_context_for_partner_match(message, history)
    matched = _prefer_topic_matched_lawyers(topic_for_partners, nearby_lawyers)

    named = _lawyers_named_in_reply(content, nearby_lawyers)
    if named:
        return named

    if _user_message_seeks_nearby_lawyers(message):
        return matched if matched else nearby_lawyers[:5]

    if had_marker:
        return matched

    return []


def _user_message_indicates_guidance_or_situation(text: str, locale: str = "en") -> bool:
    """True when the user is asking for help or describing a situation (not e.g. 'thanks')."""
    t = text.strip().lower()
    if not t:
        return False
    if "?" in text:
        return True
    if len(t) >= 40:
        return True
    if any(
        hint in t
        for hint in (
            "estate",
            "inheritance",
            "succession",
            "probate",
            "will",
            "lawyer",
            "abogado",
            "attorney",
            "legal",
            "contract",
            "property",
            "tenant",
            "employ",
            "termination",
            "dispute",
        )
    ):
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
    user_message: str = "",
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
        "\n\n## USER LOCATION (from the mobile app — internal context)\n"
        "The user's device shared **approximate GPS** for this request only. "
        "**Do not** print raw coordinates, precise pins, or street-level claims.\n"
        "Use this **internally** to tailor Philippine-law answers and match nearby partners. "
        "**Do not** say things like 'Since you're in [city]…' or 'you're likely in [area]…' "
        "on every reply — especially not on **hello**, thanks, or broad legal explanations.\n"
        "Mention their general area **only when** it clearly helps: recommending a nearby "
        "partner, which local court/agency to go to, or location-specific steps — or if they "
        "ask about local rules or 'near me'.\n"
        "You still have location context; do not claim you don't know where they are if this "
        "section is present — just keep location **out of the visible reply** unless relevant.\n",
    ]
    if area_label:
        lines.append(
            f"- **Inferred general area (for your use only):** {area_label}\n"
            "(May be off by a few kilometres; do not repeat this label unless one of the "
            "cases above applies.)\n"
        )
    else:
        lines.append(
            "- A city/province label could not be resolved; use coordinates only internally — "
            "never print them.\n"
        )

    if nearby:
        lines.append("\n### Nearby CLAiR Partner Lawyers")
        for dist_km, lawyer in nearby:
            name = lawyer.get("display_name") or (
                f"Atty. {lawyer.get('first_name', '')} {lawyer.get('last_name', '')}".strip()
            )
            areas = ", ".join(lawyer.get("practice_areas") or []) or "General practice"
            lines.append(f"- **{name}** ({areas}) — approx. {dist_km:.1f} km away")
        partner_rules = (
            f"\nRead each partner's **practice areas** and compare them to the user's question and "
            f"recent chat context. Include the exact text `{_SUGGEST_MARKER}` when:\n"
            f"- they ask to find, compare, or hire lawyers, want a referral, or need representation; "
            f"**or**\n"
            f"- their matter reasonably fits one or more partners' specialties and local counsel "
            f"would materially help.\n"
            f"**Do not** use `{_SUGGEST_MARKER}` only for general definitions or **statutory "
            f"premium/pay-rate math** you can answer without counsel.\n"
            f"When you use `{_SUGGEST_MARKER}`, write **1–2 sentences** naming the partner, their "
            f"**listed** specialties, and why they fit — never rely on the profile card alone."
        )
        if _user_message_seeks_notarial_document_help(user_message):
            partner_rules += (
                "\nFor **affidavit of loss / notarization**: explain the usual steps first; "
                "suggest a partner only if their listed areas include notarial/civil/documentation "
                "work, and introduce them in prose as above."
            )
        lines.append(partner_rules)
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
    *,
    pivot_turn: bool = False,
) -> list[dict[str, str]]:
    """Convert CLAiR history format → Groq messages list, capping history length."""
    pivot_block = _PIVOT_TURN_RULE.get(locale, _PIVOT_TURN_RULE["en"]) if pivot_turn else ""
    system_content = (
        SYSTEM_INSTRUCTION
        + pivot_block
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

    if is_greeting_or_small_talk(message):
        return _greeting_reply(locale), [], [], rag_enabled, []

    history_for_scope = [
        {"role": m["role"], "text": m["text"]}
        for m in history[-_MAX_HISTORY_MESSAGES:]
    ]
    scope_tier = await classify_message_scope(message, history_for_scope)
    if scope_tier == ScopeTier.REJECT:
        redirect = await generate_off_topic_redirect(
            message, history_for_scope, locale
        )
        return redirect, [], [], rag_enabled, []
    pivot_turn = scope_tier == ScopeTier.PIVOT

    geo_task: asyncio.Task[str | None] | None = None
    if user_lat is not None and user_lng is not None:
        geo_task = asyncio.create_task(reverse_geocode_area_label(user_lat, user_lng))

    async def _lawyer_feedback() -> str:
        if db is None:
            return ""
        return await build_global_lawyer_feedback_context_block(db)

    async def _location_bundle() -> tuple[str, list[dict]]:
        if db is None or user_lat is None or user_lng is None:
            return "", []
        area_label = await geo_task if geo_task is not None else None
        return await _build_location_context(
            db,
            user_lat,
            user_lng,
            user_message=message,
            area_label=area_label,
        )

    history_for_rag = [
        {"role": m["role"], "text": m["text"]}
        for m in history[-_MAX_HISTORY_MESSAGES:]
    ]
    router_task = asyncio.create_task(
        should_retrieve_legal_context(message, history_for_rag)
    )
    feedback_task = asyncio.create_task(_lawyer_feedback())
    location_task = asyncio.create_task(_location_bundle())

    should_rag = await router_task

    async def _fetch_chunks() -> list[dict]:
        return await get_relevant_chunks(
            message,
            history=history_for_rag,
            retrieve=should_rag,
        )

    chunks_task = asyncio.create_task(_fetch_chunks())

    chunks = await chunks_task
    rag_sources = _rag_sources_from_chunks(chunks)
    rag_context = format_rag_context(chunks)
    logger.info(
        "RAG turn: chunks=%d sources=%d should_rag=%s",
        len(chunks),
        len(rag_sources),
        should_rag,
    )

    tavily_task = asyncio.create_task(
        search_philippine_law(message, rag_chunk_count=len(chunks))
    )

    tavily_results, lawyer_feedback_block, (location_context, nearby_lawyers) = (
        await asyncio.gather(tavily_task, feedback_task, location_task)
    )
    rag_context = (
        rag_context
        + format_tavily_context(tavily_results)
        + location_context
    )

    messages = _build_messages(
        message,
        history,
        rag_context,
        locale,
        lawyer_feedback_block,
        pivot_turn=pivot_turn,
    )

    preferred_groq: str | None = None
    if settings.CHAT_USE_FAST_MODEL_FOR_SHORT:
        if (
            len(message) <= settings.CHAT_FAST_MODEL_MAX_CHARS
            and len(history) <= settings.CHAT_FAST_MODEL_MAX_HISTORY
        ):
            preferred_groq = settings.GROQ_FAST_CHAT_MODEL

    try:
        content = await chat_completion(
            messages,
            max_tokens=settings.CHAT_MAX_TOKENS,
            temperature=0.7,
            preferred_groq_model=preferred_groq,
        )
    except AllProvidersRateLimitedError:
        raise
    if not content:
        content = _FALLBACK_NO_REPLY.get(locale, _FALLBACK_NO_REPLY["en"])

    suppress_cards = _suppress_lawyer_cards_for_message(message)
    had_marker = _SUGGEST_MARKER in content
    if had_marker:
        content = content.replace(_SUGGEST_MARKER, "").strip()

    suggested = _finalize_suggested_lawyers(
        content=content,
        message=message,
        history=history,
        nearby_lawyers=nearby_lawyers,
        had_marker=had_marker,
        suppress_cards=suppress_cards,
        locale=locale,
    )

    # Align UI sources with laws cited in the reply (fetch by RA/PD number even when
    # the RAG router skipped vector search — e.g. model cited RA 10173 from context).
    if settings.CHAT_ALIGN_RAG_SOURCES:
        injected_sources = list(rag_sources)
        aligned = await align_rag_sources_with_citations(injected_sources, content)
        rag_sources = aligned if aligned else injected_sources

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
        raw = await chat_completion(
            [
                {
                    "role": "system",
                    "content": f"{_TITLE_SYSTEM}\n\n{lang_line}",
                },
                {"role": "user", "content": prompt},
            ],
            max_tokens=64,
            temperature=0.3,
            title=True,
        )
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
    except AllProvidersRateLimitedError:
        return _fb()
    except Exception:
        return _fb()
