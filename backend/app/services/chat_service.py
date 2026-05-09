from groq import AsyncGroq

from app.config import settings
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


async def get_chat_response(
    message: str,
    history: list[dict[str, str]],
) -> str:
    chunks = await get_relevant_chunks(message)
    rag_context = format_rag_context(chunks)

    messages = _build_messages(message, history, rag_context)

    client = _get_client()
    response = await client.chat.completions.create(
        model=_CHAT_MODEL,
        messages=messages,
        max_tokens=1024,
        temperature=0.7,
    )

    content = response.choices[0].message.content
    return content or "Sorry, I couldn't generate a response. Please try again."


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
