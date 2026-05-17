"""Unit tests for client vs lawyer platform separation."""

import uuid
from unittest.mock import AsyncMock, patch

import pytest
from fastapi import HTTPException

from app.core.platform_auth import (
    CLIENT_ON_LAWYER_PORTAL_DETAIL,
    LAWYER_ON_MOBILE_DETAIL,
    ensure_client_platform_user,
    ensure_lawyer_platform_user,
)
from app.models.user import User


def _user() -> User:
    return User(
        id=uuid.uuid4(),
        firebase_uid="fb-test",
        email="test@example.com",
        auth_provider="email",
    )


@pytest.mark.asyncio
async def test_ensure_client_platform_user_rejects_lawyer():
    user = _user()
    db = AsyncMock()
    with patch(
        "app.core.platform_auth.user_has_lawyer_profile",
        new_callable=AsyncMock,
        return_value=True,
    ):
        with pytest.raises(HTTPException) as exc:
            await ensure_client_platform_user(db, user)
    assert exc.value.status_code == 403
    assert exc.value.detail == LAWYER_ON_MOBILE_DETAIL


@pytest.mark.asyncio
async def test_ensure_lawyer_platform_user_rejects_client():
    user = _user()
    db = AsyncMock()
    with patch(
        "app.core.platform_auth.user_has_lawyer_profile",
        new_callable=AsyncMock,
        return_value=False,
    ):
        with pytest.raises(HTTPException) as exc:
            await ensure_lawyer_platform_user(db, user)
    assert exc.value.status_code == 403
    assert exc.value.detail == CLIENT_ON_LAWYER_PORTAL_DETAIL
