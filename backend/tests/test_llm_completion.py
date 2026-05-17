import httpx
import pytest
from groq import RateLimitError

from app.services.llm_completion import is_rate_limit_error


def test_is_rate_limit_groq():
    assert is_rate_limit_error(RateLimitError("rate limit", response=None, body=None))


def test_is_rate_limit_http_429():
    request = httpx.Request("POST", "https://example.com")
    response = httpx.Response(429, request=request)
    assert is_rate_limit_error(httpx.HTTPStatusError("429", request=request, response=response))


def test_is_rate_limit_message_heuristic():
    assert is_rate_limit_error(Exception("Error 429: quota exceeded"))


def test_is_not_rate_limit():
    assert not is_rate_limit_error(ValueError("invalid api key"))
