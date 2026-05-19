"""Chat/title completions with Groq → Vertex → Gemini Studio → OpenRouter fallbacks."""

from __future__ import annotations

import logging
import os
import re
from typing import Any

import httpx
from google import genai
from google.genai import types as genai_types
from groq import AsyncGroq, RateLimitError

from app.config import settings

logger = logging.getLogger(__name__)

OPENROUTER_CHAT_URL = "https://openrouter.ai/api/v1/chat/completions"

_groq_client: AsyncGroq | None = None
_gemini_client: genai.Client | None = None
_vertex_client: genai.Client | None = None


class AllProvidersRateLimitedError(Exception):
    """Every configured provider returned rate-limit / quota errors."""


def is_rate_limit_error(exc: BaseException) -> bool:
    if isinstance(exc, RateLimitError):
        return True
    if isinstance(exc, httpx.HTTPStatusError) and exc.response.status_code == 429:
        return True
    msg = str(exc).lower()
    return any(
        token in msg
        for token in (
            "429",
            "rate limit",
            "rate_limit",
            "quota",
            "resource exhausted",
            "too many requests",
            "capacity",
        )
    )


def _groq() -> AsyncGroq | None:
    global _groq_client
    if not settings.GROQ_API_KEY:
        return None
    if _groq_client is None:
        _groq_client = AsyncGroq(api_key=settings.GROQ_API_KEY)
    return _groq_client


def _gemini() -> genai.Client | None:
    global _gemini_client
    if not settings.GEMINI_API_KEY:
        return None
    if _gemini_client is None:
        _gemini_client = genai.Client(api_key=settings.GEMINI_API_KEY)
    return _gemini_client


def _ensure_vertex_credentials() -> bool:
    path = (
        settings.GCP_VERTEX_CREDENTIALS_PATH
        or os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    )
    if not path:
        return False
    if not os.path.isfile(path):
        logger.warning("Vertex credentials file not found: %s", path)
        return False
    os.environ.setdefault("GOOGLE_APPLICATION_CREDENTIALS", path)
    return True


def _vertex() -> genai.Client | None:
    global _vertex_client
    if not settings.GCP_PROJECT_ID or not settings.GCP_VERTEX_LOCATION:
        return None
    if not _ensure_vertex_credentials():
        return None
    if _vertex_client is None:
        _vertex_client = genai.Client(
            vertexai=True,
            project=settings.GCP_PROJECT_ID,
            location=settings.GCP_VERTEX_LOCATION,
        )
    return _vertex_client


def _provider_available(name: str) -> bool:
    if name == "groq":
        return bool(settings.GROQ_API_KEY)
    if name == "vertex":
        return _vertex() is not None
    if name == "gemini":
        return bool(settings.GEMINI_API_KEY)
    if name == "openrouter":
        return bool(settings.OPENROUTER_API_KEY)
    return False


_THINKING_TAG_RE = re.compile(
    r"<think(?:ing)?>.*?</think(?:ing)?>",
    re.IGNORECASE | re.DOTALL,
)


def _sanitize_completion(text: str) -> str:
    cleaned = _THINKING_TAG_RE.sub("", text).strip()
    if cleaned.startswith("```"):
        cleaned = re.sub(r"^```\w*\n?", "", cleaned)
        cleaned = re.sub(r"\n?```$", "", cleaned).strip()
    return cleaned


def _split_system_messages(
    messages: list[dict[str, str]],
) -> tuple[str | None, list[dict[str, str]]]:
    system_parts: list[str] = []
    rest: list[dict[str, str]] = []
    for m in messages:
        if m.get("role") == "system":
            system_parts.append(m.get("content") or "")
        else:
            rest.append(m)
    system = "\n\n".join(p for p in system_parts if p.strip()).strip() or None
    return system, rest


async def _complete_groq(
    messages: list[dict[str, str]],
    *,
    model: str,
    max_tokens: int,
    temperature: float,
) -> str:
    client = _groq()
    assert client is not None
    response = await client.chat.completions.create(
        model=model,
        messages=messages,
        max_tokens=max_tokens,
        temperature=temperature,
    )
    return (response.choices[0].message.content or "").strip()


async def _complete_genai(
    client: genai.Client,
    messages: list[dict[str, str]],
    *,
    model: str,
    max_tokens: int,
    temperature: float,
) -> str:
    system_instruction, dialog = _split_system_messages(messages)
    contents: list[genai_types.Content] = []
    for m in dialog:
        role = m.get("role", "user")
        text = m.get("content") or ""
        if not text.strip():
            continue
        if role == "assistant":
            gemini_role = "model"
        else:
            gemini_role = "user"
        contents.append(
            genai_types.Content(
                role=gemini_role,
                parts=[genai_types.Part(text=text)],
            )
        )

    config = genai_types.GenerateContentConfig(
        system_instruction=system_instruction,
        max_output_tokens=max_tokens,
        temperature=temperature,
    )
    response = await client.aio.models.generate_content(
        model=model,
        contents=contents,
        config=config,
    )
    return (response.text or "").strip()


async def _complete_gemini(
    messages: list[dict[str, str]],
    *,
    model: str,
    max_tokens: int,
    temperature: float,
) -> str:
    client = _gemini()
    assert client is not None
    return await _complete_genai(
        client, messages, model=model, max_tokens=max_tokens, temperature=temperature
    )


async def _complete_vertex(
    messages: list[dict[str, str]],
    *,
    model: str,
    max_tokens: int,
    temperature: float,
) -> str:
    client = _vertex()
    assert client is not None
    return await _complete_genai(
        client, messages, model=model, max_tokens=max_tokens, temperature=temperature
    )


async def _complete_openrouter(
    messages: list[dict[str, str]],
    *,
    model: str,
    max_tokens: int,
    temperature: float,
) -> str:
    headers = {
        "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": settings.OPENROUTER_HTTP_REFERER,
        "X-Title": settings.APP_NAME,
    }
    payload: dict[str, Any] = {
        "model": model,
        "messages": messages,
        "max_tokens": max_tokens,
        "temperature": temperature,
    }

    async with httpx.AsyncClient(timeout=httpx.Timeout(180.0, connect=30.0)) as http:
        response = await http.post(
            OPENROUTER_CHAT_URL,
            headers=headers,
            json=payload,
        )
        response.raise_for_status()
        data = response.json()

    choices = data.get("choices") or []
    if not choices:
        raise RuntimeError("OpenRouter returned no choices")
    message = choices[0].get("message") or {}
    return (message.get("content") or "").strip()


async def chat_completion(
    messages: list[dict[str, str]],
    *,
    max_tokens: int = 1024,
    temperature: float = 0.7,
    title: bool = False,
    preferred_groq_model: str | None = None,
) -> str:
    """
    Try Groq, then Vertex AI (GCP), then Gemini Studio, then OpenRouter.
    Only advances when the previous provider hits a rate-limit / quota error.
    """
    if title:
        chain: list[tuple[str, str, Any]] = [
            ("groq", settings.GROQ_TITLE_MODEL, _complete_groq),
            ("vertex", settings.VERTEX_TITLE_MODEL, _complete_vertex),
            ("gemini", settings.GEMINI_TITLE_MODEL, _complete_gemini),
            ("openrouter", settings.OPENROUTER_TITLE_MODEL, _complete_openrouter),
        ]
    else:
        groq_model = preferred_groq_model or settings.GROQ_CHAT_MODEL
        chain = [
            ("groq", groq_model, _complete_groq),
            ("vertex", settings.VERTEX_CHAT_MODEL, _complete_vertex),
            ("gemini", settings.GEMINI_CHAT_MODEL, _complete_gemini),
            ("openrouter", settings.OPENROUTER_CHAT_MODEL, _complete_openrouter),
        ]

    rate_errors: list[str] = []
    skipped: list[str] = []

    for provider, model, complete_fn in chain:
        if not _provider_available(provider):
            skipped.append(provider)
            continue
        try:
            text = await complete_fn(
                messages,
                model=model,
                max_tokens=max_tokens,
                temperature=temperature,
            )
            if text:
                text = _sanitize_completion(text)
            if text:
                if rate_errors:
                    logger.info(
                        "LLM completion via %s model=%s (fallback after rate limits: %s)",
                        provider,
                        model,
                        ", ".join(rate_errors),
                    )
                else:
                    kind = "title" if title else "chat"
                    logger.info(
                        "LLM completion via %s model=%s (%s)",
                        provider,
                        model,
                        kind,
                    )
                return text
            logger.warning("%s returned empty content, trying next provider", provider)
        except Exception as exc:
            if is_rate_limit_error(exc):
                logger.warning(
                    "%s rate limited (%s), trying next provider",
                    provider,
                    exc,
                )
                rate_errors.append(provider)
                continue
            raise

    if not rate_errors and skipped and len(skipped) == len(chain):
        raise AllProvidersRateLimitedError("No LLM API keys configured")
    raise AllProvidersRateLimitedError(
        "All LLM providers are rate limited: "
        + ", ".join(rate_errors or ["unknown"])
    )
