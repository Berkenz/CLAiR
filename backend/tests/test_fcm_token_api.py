"""FCM token registration API and notification → push hook."""

import uuid
from unittest.mock import patch

import pytest
from httpx import ASGITransport, AsyncClient

from app.api.deps import get_current_user
from app.main import app
from app.models.user import User
from app.services import notification_service


@pytest.fixture
def client_user() -> User:
    return User(
        id=uuid.uuid4(),
        firebase_uid="fcm-test-uid",
        email="fcm@test.com",
        auth_provider="email",
        is_anonymous=False,
        is_active=True,
    )


@pytest.mark.asyncio
async def test_register_and_clear_fcm_token(override_get_db, async_session, client_user):
    async_session.add(client_user)
    await async_session.flush()

    app.dependency_overrides[get_current_user] = lambda: client_user
    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            put = await client.put(
                "/api/v1/users/me/fcm-token",
                json={"token": "fake-device-token-123"},
            )
            assert put.status_code == 204

            delete = await client.delete("/api/v1/users/me/fcm-token")
            assert delete.status_code == 204

        await async_session.refresh(client_user)
        assert client_user.fcm_token is None
    finally:
        app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_create_notification_triggers_push(
    override_get_db, async_session, client_user
):
    client_user.fcm_token = "fake-device-token-123"
    async_session.add(client_user)
    await async_session.flush()

    with patch(
        "app.services.notification_service.push_notification_service.send_push_to_user",
        return_value=True,
    ) as mock_push:
        await notification_service.create_notification(
            async_session,
            user_id=client_user.id,
            notification_type="appointment_accepted",
            title="Appointment accepted",
            body="Your lawyer accepted.",
            payload={"appointment_id": str(uuid.uuid4())},
        )

    mock_push.assert_called_once()
    call_kwargs = mock_push.call_args.kwargs
    assert call_kwargs["notification_type"] == "appointment_accepted"
    assert call_kwargs["title"] == "Appointment accepted"


@pytest.mark.asyncio
async def test_guest_cannot_register_fcm_token(override_get_db, async_session):
    guest = User(
        id=uuid.uuid4(),
        firebase_uid="guest-uid",
        email=None,
        auth_provider="anonymous",
        is_anonymous=True,
        is_active=True,
    )
    async_session.add(guest)
    await async_session.flush()

    app.dependency_overrides[get_current_user] = lambda: guest
    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            res = await client.put(
                "/api/v1/users/me/fcm-token",
                json={"token": "should-fail"},
            )
        assert res.status_code == 400
    finally:
        app.dependency_overrides.pop(get_current_user, None)
