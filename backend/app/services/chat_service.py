from google import genai
from google.genai import types

from app.config import settings

SYSTEM_INSTRUCTION = (
    "You are CLAiR, a friendly and knowledgeable AI legal assistant "
    "specializing in Philippine law. You help users understand legal concepts, "
    "rights, and procedures in a clear and accessible way. "
    "Always remind users that your responses are for informational purposes only "
    "and do not constitute legal advice. Recommend consulting a licensed attorney "
    "for specific legal matters."
)

_client = None


def _get_client() -> genai.Client:
    global _client
    if _client is None:
        _client = genai.Client(api_key=settings.GEMINI_API_KEY)
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
        model="gemini-2.5-flash",
        contents=contents,
        config=types.GenerateContentConfig(
            system_instruction=SYSTEM_INSTRUCTION,
        ),
    )
    return response.text
