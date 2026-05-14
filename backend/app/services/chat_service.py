import math

from groq import AsyncGroq
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.services.lawyer_service import lawyer_service
from app.services.tavily_service import format_tavily_context, search_philippine_law
from app.services.vector_service import format_rag_context, get_relevant_chunks

# Compact but complete system prompt — every sentence earns its tokens.
SYSTEM_INSTRUCTION = (
    "You are CLAiR, a warm, empathetic AI legal assistant specializing in Philippine law. "
    "Help users fully articulate their legal situation before giving advice.\n\n"
    "## CONVERSATION RULES\n"
    "1. **Ask before advising.** On a new problem, acknowledge warmly then ask 2–3 focused questions "
    "(dates, parties, location, documents, desired outcome) before giving a full explanation.\n"
    "2. **Keep gathering facts** until the picture is complete. Never assume unstated facts.\n"
    "3. **One question at a time** when possible; number them if you must ask several.\n"
    "4. **Summarize first.** Once you have enough details, confirm your understanding before concluding.\n"
    "5. **Invite follow-up** at the end of every substantive answer.\n\n"
    "## LEGAL RULES\n"
    "- Responses are for information only — not legal advice.\n"
    "- Always recommend consulting a licensed attorney before signing documents or taking formal action.\n\n"
    "## FORMAT\n"
    "Use Markdown: **bold** for key terms, numbered lists for steps, bullets for conditions, "
    "### headings for multi-topic answers, > blockquotes for statute citations. "
    "Keep paragraphs short. End with an italicised disclaimer when appropriate."
)

# Keep only the most recent N messages to bound history token cost.
# 8 messages = 4 back-and-forth turns — enough for context without runaway growth.
_MAX_HISTORY_MESSAGES = 8

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


async def _build_location_context(
    db: AsyncSession,
    user_lat: float,
    user_lng: float,
    radius_km: float = 50.0,
    max_lawyers: int = 5,
) -> tuple[str, list[dict]]:
    """
    Returns (context_text, nearby_lawyers_list).
    context_text is injected into the system prompt.
    nearby_lawyers_list is the raw lawyer dicts for use in the API response.
    """
    all_lawyers = await lawyer_service.get_all_complete_lawyers(db)
    nearby: list[tuple[float, dict]] = []
    for lawyer in all_lawyers:
        lat = lawyer.get("latitude")
        lng = lawyer.get("longitude")
        if lat is None or lng is None:
            continue
        dist = _haversine_km(user_lat, user_lng, lat, lng)
        if dist <= radius_km:
            nearby.append((dist, lawyer))

    nearby.sort(key=lambda x: x[0])
    nearby = nearby[:max_lawyers]

    lines = [
        f"\n\n## USER LOCATION\n"
        f"The user is located in the Philippines "
        f"(internal coordinates: {user_lat:.4f}, {user_lng:.4f} — do NOT reveal these to the user). "
        f"Use this to tailor legal answers to the relevant region, local courts, "
        f"and jurisdiction where applicable.",
    ]

    if nearby:
        lines.append("\n### Nearby CLAiR Partner Lawyers")
        for dist_km, lawyer in nearby:
            name = lawyer.get("display_name") or (
                f"Atty. {lawyer.get('first_name', '')} {lawyer.get('last_name', '')}".strip()
            )
            areas = ", ".join(lawyer.get("practice_areas") or []) or "General practice"
            lines.append(f"- **{name}** ({areas}) — approx. {dist_km:.1f} km away")
        lines.append(
            f"\nIf the user asks about finding a lawyer or you recommend any of these "
            f"lawyers, include the exact text `{_SUGGEST_MARKER}` anywhere in your response "
            f"so the app can display their profile cards."
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
) -> list[dict[str, str]]:
    """Convert CLAiR history format → Groq messages list, capping history length."""
    system_content = SYSTEM_INSTRUCTION + rag_context

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
) -> tuple[str, list[dict], list[dict], bool, list[dict]]:
    """Returns (reply_text, suggested_lawyers, rag_sources, rag_enabled, tavily_sources).

    suggested_lawyers is non-empty only when the model included the
    [[SUGGEST_LAWYERS]] marker in its reply and nearby lawyers exist.

    rag_sources lists retrieved law chunks (same as injected into the prompt).
    rag_enabled is True when SUPABASE_DB_URL and EMBED_SERVICE_URL are set
    (retrieval was attempted; rag_sources may still be empty).

    tavily_sources lists real-time web results from trusted PH legal domains,
    injected when the query is time-sensitive or RAG returned no chunks.
    """
    rag_enabled = bool(settings.SUPABASE_DB_URL and settings.EMBED_SERVICE_URL)
    chunks = await get_relevant_chunks(message)
    rag_sources = _rag_sources_from_chunks(chunks)
    rag_context = format_rag_context(chunks)

    # Supplement with real-time search from trusted Philippine legal domains.
    tavily_results = await search_philippine_law(message, rag_chunk_count=len(chunks))
    rag_context = rag_context + format_tavily_context(tavily_results)

    nearby_lawyers: list[dict] = []
    if db is not None and user_lat is not None and user_lng is not None:
        location_context, nearby_lawyers = await _build_location_context(
            db, user_lat, user_lng
        )
        rag_context = rag_context + location_context

    messages = _build_messages(message, history, rag_context)

    client = _get_client()
    response = await client.chat.completions.create(
        model=_CHAT_MODEL,
        messages=messages,
        max_tokens=1024,
        temperature=0.7,
    )

    content = response.choices[0].message.content or (
        "Sorry, I couldn't generate a response. Please try again."
    )

    # Strip the marker and decide whether to surface nearby lawyers.
    suggested: list[dict] = []
    if _SUGGEST_MARKER in content:
        content = content.replace(_SUGGEST_MARKER, "").strip()
        suggested = nearby_lawyers

    return content, suggested, rag_sources, rag_enabled, tavily_results


_TITLE_SYSTEM = (
    "Write one conversation title for a Philippine legal assistant chat. "
    "Plain text only — no quotes, no markdown, no trailing period. "
    "Include the legal issue and concrete facts (parties, incident type, property, claim). "
    "Example: 'Tenant eviction notice in Metro Manila — rights and procedures'. "
    "Never output a single word or a generic label."
)

_TITLE_USER_MAX = 600


def _title_too_vague(title: str) -> bool:
    t = title.strip()
    words = t.split()
    return not t or len(words) < 4 or len(t) < 18


async def generate_conversation_title(
    user_message: str,
    assistant_reply: str,
    *,
    fallback_title: str,
) -> str:
    """Derive a descriptive history title from the first user turn and assistant reply."""
    um = user_message.strip()
    if not um:
        return fallback_title[:200]

    prompt = (
        f"User message:\n{um[:_TITLE_USER_MAX]}\n\n"
        f"Assistant reply:\n{assistant_reply.strip()[:_TITLE_USER_MAX]}\n\n"
        "Write the title line only."
    )

    try:
        client = _get_client()
        response = await client.chat.completions.create(
            model=_TITLE_MODEL,
            messages=[
                {"role": "system", "content": _TITLE_SYSTEM},
                {"role": "user", "content": prompt},
            ],
            max_tokens=64,
            temperature=0.3,
        )
        raw = (response.choices[0].message.content or "").strip()
        if not raw:
            return fallback_title[:200]

        one_line = " ".join(raw.split())
        for prefix in ("title:", "conversation:"):
            if one_line.lower().startswith(prefix):
                one_line = one_line[len(prefix):].strip()
        one_line = one_line.strip("\"'\u201c\u201d")
        if len(one_line) > 200:
            one_line = one_line[:197] + "..."

        return one_line if not _title_too_vague(one_line) else fallback_title[:200]
    except Exception:
        return fallback_title[:200]
