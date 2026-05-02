from google.genai import Client, types

from app.config import settings

SYSTEM_INSTRUCTION = (
    "You are CLAiR, a warm, empathetic, and knowledgeable AI legal assistant "
    "specializing in Philippine law. Your primary goal is to help users fully "
    "articulate their legal situation so that both you and any lawyer they consult "
    "later have a complete, accurate picture of their case.\n\n"
    "## HOW TO CONDUCT THE CONVERSATION\n\n"
    "1. **Ask before you advise.** When a user first describes their problem, do NOT "
    "immediately launch into a full legal explanation. Instead, acknowledge their "
    "situation warmly, then ask 2–3 focused follow-up questions to gather missing "
    "details (e.g., dates, parties involved, location, documents, what has already "
    "been done, what outcome they want).\n\n"
    "2. **Keep digging until the picture is complete.** After each user reply, "
    "evaluate whether you have enough facts. If anything important is still unclear "
    "— timeline, relationships between parties, amounts of money, type of property, "
    "prior agreements, etc. — ask about it before moving on. Never assume facts not "
    "stated by the user.\n\n"
    "3. **Ask one focused question at a time when possible.** If you must ask "
    "multiple questions, group them logically and number them so the user can answer "
    "each clearly.\n\n"
    "4. **Summarize before concluding.** Once you have enough details, briefly "
    "summarize the situation back to the user ('Based on what you've shared: ...') "
    "and confirm you have it right before giving your full legal explanation.\n\n"
    "5. **Offer to go deeper.** At the end of a substantive answer, always invite "
    "the user to share more or ask follow-up questions (e.g., 'Is there anything "
    "else about this situation you'd like me to clarify?' or 'Can you tell me more "
    "about [specific detail]?').\n\n"
    "## LEGAL GUIDANCE RULES\n\n"
    "- Always remind users that your responses are for informational purposes only "
    "and do not constitute legal advice.\n"
    "- Recommend consulting a licensed attorney for specific legal matters, "
    "especially before signing documents or taking formal legal action.\n\n"
    "## FORMAT YOUR RESPONSES using Markdown for readability:\n"
    "- Use **bold** to highlight key legal terms, important phrases, and article/section references.\n"
    "- Use numbered lists (1. 2. 3.) for sequential steps or procedures.\n"
    "- Use bullet points (-) for non-sequential items, rights, or conditions.\n"
    "- Use ### headings to separate major sections when the answer covers multiple topics.\n"
    "- Use > blockquotes when citing specific legal provisions or statutes.\n"
    "- Keep paragraphs concise — prefer short paragraphs over long walls of text.\n"
    "- End with a brief disclaimer in italics when appropriate."
)

_client = None


def _get_client() -> Client:
    global _client
    if _client is None:
        _client = Client(api_key=settings.GEMINI_API_KEY)
    return _client


async def get_chat_response(
    message: str,
    history: list[dict[str, str]],
) -> str:
    client = _get_client()

    contents = []
    for msg in history:
        contents.append(
            types.Content(
                role=msg["role"],
                parts=[types.Part(text=msg["text"])],
            )
        )
    contents.append(
        types.Content(role="user", parts=[types.Part(text=message)])
    )

    response = await client.aio.models.generate_content(
        model="gemini-3.1-flash-lite-preview",
        contents=contents,
        config=types.GenerateContentConfig(
            system_instruction=SYSTEM_INSTRUCTION,
        ),
    )

    if response.text:
        return response.text

    parts = []
    for candidate in (response.candidates or []):
        for part in (candidate.content.parts or []):
            if part.text:
                parts.append(part.text)
    return "\n".join(parts) if parts else "Sorry, I couldn't generate a response. Please try again."


_TITLE_SYSTEM = (
    "You write conversation titles for a Philippine legal assistant (CLAiR). "
    "Output exactly one line: plain text only, no quotes, no markdown, no trailing period.\n"
    "Rules:\n"
    "- NEVER output a single word or generic label (e.g. do not use only 'car', 'law', 'help').\n"
    "- Use short phrases needed to describe what happened and the legal angle.\n"
    "- Include concrete facts from the user: parties, incident type, injury, property, or claim.\n"
    "- Example good titles: 'Car accident where motorcycle struck my vehicle — liability and claims'; "
    "'Tenant eviction notice in Metro Manila — rights and procedures'.\n"
    "- If details are only in the assistant reply, pull them into the title.\n"
    "- Use sentence-style phrasing; Title Case is optional."
)

_TITLE_USER_MAX = 800


def _title_too_vague(title: str) -> bool:
    """Reject one-word or overly short titles the model sometimes returns."""
    t = title.strip()
    if not t:
        return True
    words = t.split()
    if len(words) == 1:
        return True
    if len(t) < 18:
        return True
    if len(words) < 4:
        return True
    return False


async def generate_conversation_title(
    user_message: str,
    assistant_reply: str,
    *,
    fallback_title: str,
) -> str:
    """Derive a descriptive history title from the first user turn and assistant reply."""
    um = user_message.strip()
    ar = assistant_reply.strip()
    if not um:
        return fallback_title[:200]

    preview_user = um[:_TITLE_USER_MAX]
    preview_reply = ar[:_TITLE_USER_MAX]
    prompt = (
        "Write one descriptive conversation title for the chat history list.\n"
        "It must summarize the user's situation (who/what/when type details), not a single keyword.\n\n"
        f"User message:\n{preview_user}\n\n"
        f"Assistant reply (for context):\n{preview_reply}\n\n"
        "Reply with the title line only."
    )

    try:
        client = _get_client()
        response = await client.aio.models.generate_content(
            model="gemini-3.1-flash-lite-preview",
            contents=[
                types.Content(
                    role="user",
                    parts=[types.Part(text=prompt)],
                )
            ],
            config=types.GenerateContentConfig(
                system_instruction=_TITLE_SYSTEM,
                temperature=0.35,
                max_output_tokens=128,
            ),
        )
        raw = (response.text or "").strip()
        if not raw:
            parts: list[str] = []
            for candidate in (response.candidates or []):
                for part in (candidate.content.parts or []):
                    if part.text:
                        parts.append(part.text.strip())
            raw = " ".join(parts).strip()
        if not raw:
            return fallback_title[:200]

        one_line = " ".join(raw.split())
        for prefix in ("title:", "conversation:"):
            if one_line.lower().startswith(prefix):
                one_line = one_line[len(prefix) :].strip()
        one_line = one_line.strip("\"'“”")
        if len(one_line) > 200:
            one_line = one_line[:197] + "..."

        if _title_too_vague(one_line):
            return fallback_title[:200]

        return one_line or fallback_title[:200]
    except Exception:
        return fallback_title[:200]
