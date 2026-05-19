"""Chat per-user rate limits."""

import uuid

import pytest
from fastapi import HTTPException
from limits import parse
from starlette.requests import Request

from app.config import settings
from app.core.rate_limit import enforce_chat_rate_limit, limiter
from app.models.user import User


def _fake_request() -> Request:
    scope = {
        "type": "http",
        "method": "POST",
        "path": "/api/v1/chat/send",
        "headers": [],
        "query_string": b"",
    }
    return Request(scope)


def _fake_user(*, anonymous: bool = False) -> User:
    return User(
        id=uuid.uuid4(),
        firebase_uid="test-uid",
        email=None,
        is_anonymous=anonymous,
        is_active=True,
    )


@pytest.mark.asyncio
async def test_registered_user_allows_within_limit(monkeypatch):
    monkeypatch.setattr(settings, "CHAT_RATE_LIMIT_ENABLED", True)
    monkeypatch.setattr(settings, "CHAT_RATE_LIMIT_REGISTERED", "3/minute")
    user = _fake_user(anonymous=False)
    request = _fake_request()

    for _ in range(3):
        await enforce_chat_rate_limit(request, user)


@pytest.mark.asyncio
async def test_registered_user_blocks_over_limit(monkeypatch):
    monkeypatch.setattr(settings, "CHAT_RATE_LIMIT_ENABLED", True)
    monkeypatch.setattr(settings, "CHAT_RATE_LIMIT_REGISTERED", "3/minute")
    user = _fake_user(anonymous=False)
    request = _fake_request()

    for _ in range(3):
        await enforce_chat_rate_limit(request, user)

    with pytest.raises(HTTPException) as exc:
        await enforce_chat_rate_limit(request, user)
    assert exc.value.status_code == 429


@pytest.mark.asyncio
async def test_anonymous_stricter_limit(monkeypatch):
    monkeypatch.setattr(settings, "CHAT_RATE_LIMIT_ENABLED", True)
    monkeypatch.setattr(settings, "CHAT_RATE_LIMIT_ANONYMOUS", "2/minute")
    user = _fake_user(anonymous=True)
    request = _fake_request()

    await enforce_chat_rate_limit(request, user)
    await enforce_chat_rate_limit(request, user)

    with pytest.raises(HTTPException) as exc:
        await enforce_chat_rate_limit(request, user)
    assert exc.value.status_code == 429


def test_limit_strings_parse():
    assert parse(settings.CHAT_RATE_LIMIT_REGISTERED) is not None
    assert parse(settings.CHAT_RATE_LIMIT_ANONYMOUS) is not None
