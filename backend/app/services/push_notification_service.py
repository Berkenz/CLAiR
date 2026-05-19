"""Firebase Cloud Messaging (mobile push)."""

from __future__ import annotations

import logging
import uuid
from typing import Any

from firebase_admin import messaging
from firebase_admin.exceptions import FirebaseError
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.firebase import init_firebase
from app.services.user_service import user_service

logger = logging.getLogger(__name__)

_ANDROID_CHANNEL_ID = "clair_notifications"

# Client-facing types we push to the mobile app.
_CLIENT_PUSH_TYPES = frozenset(
    {
        "appointment_accepted",
        "appointment_rejected",
        "appointment_resolved",
        "new_direct_message",
    }
)


def _stringify_data(data: dict[str, Any]) -> dict[str, str]:
    out: dict[str, str] = {}
    for key, value in data.items():
        if value is None:
            continue
        out[str(key)] = str(value)
    return out


async def send_push_to_user(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    title: str,
    body: str | None,
    notification_type: str,
    payload: dict[str, Any] | None = None,
) -> bool:
    """
    Send FCM to the user's registered device token, if any.
    Returns True when a message was sent successfully.
    """
    if not settings.PUSH_NOTIFICATIONS_ENABLED:
        return False
    if notification_type not in _CLIENT_PUSH_TYPES:
        return False

    user = await user_service.get_user_by_id(db, user_id)
    if user is None or user.is_anonymous or not user.fcm_token:
        return False

    token = user.fcm_token.strip()
    if not token:
        return False

    data = _stringify_data(
        {
            "notification_type": notification_type,
            "appointment_id": (payload or {}).get("appointment_id", ""),
        }
    )

    try:
        init_firebase()
        message = messaging.Message(
            token=token,
            notification=messaging.Notification(
                title=title,
                body=body or "",
            ),
            data=data,
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id=_ANDROID_CHANNEL_ID,
                ),
            ),
        )
        messaging.send(message)
        logger.info(
            "FCM sent user_id=%s type=%s",
            user_id,
            notification_type,
        )
        return True
    except messaging.UnregisteredError:
        logger.info("FCM token unregistered; clearing user_id=%s", user_id)
        await user_service.set_fcm_token(db, user_id, None)
        return False
    except FirebaseError as e:
        logger.warning(
            "FCM send failed user_id=%s type=%s: %s",
            user_id,
            notification_type,
            e,
        )
        return False
    except Exception:
        logger.exception(
            "Unexpected FCM error user_id=%s type=%s",
            user_id,
            notification_type,
        )
        return False
