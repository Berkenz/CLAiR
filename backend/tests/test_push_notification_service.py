"""FCM push notification service."""

import uuid
from unittest.mock import MagicMock, patch

import pytest

from app.config import settings
from app.services import push_notification_service


@pytest.mark.asyncio
async def test_send_push_skips_when_disabled(monkeypatch):
    monkeypatch.setattr(settings, "PUSH_NOTIFICATIONS_ENABLED", False)
    db = MagicMock()
    sent = await push_notification_service.send_push_to_user(
        db,
        user_id=uuid.uuid4(),
        title="Test",
        body="Body",
        notification_type="appointment_accepted",
    )
    assert sent is False


@pytest.mark.asyncio
async def test_send_push_skips_non_client_types(monkeypatch):
    monkeypatch.setattr(settings, "PUSH_NOTIFICATIONS_ENABLED", True)
    db = MagicMock()
    sent = await push_notification_service.send_push_to_user(
        db,
        user_id=uuid.uuid4(),
        title="Test",
        body="Body",
        notification_type="new_appointment",
    )
    assert sent is False


@pytest.mark.asyncio
async def test_send_push_success(monkeypatch):
    monkeypatch.setattr(settings, "PUSH_NOTIFICATIONS_ENABLED", True)
    user_id = uuid.uuid4()
    user = MagicMock()
    user.is_anonymous = False
    user.fcm_token = "device-token-abc"

    db = MagicMock()

    with (
        patch(
            "app.services.push_notification_service.user_service.get_user_by_id",
            return_value=user,
        ),
        patch(
            "app.services.push_notification_service.init_firebase",
        ),
        patch(
            "app.services.push_notification_service.messaging.send",
            return_value="msg-id",
        ) as mock_send,
    ):
        sent = await push_notification_service.send_push_to_user(
            db,
            user_id=user_id,
            title="Appointment accepted",
            body="Your lawyer accepted.",
            notification_type="appointment_accepted",
            payload={"appointment_id": str(uuid.uuid4())},
        )

    assert sent is True
    mock_send.assert_called_once()
