"""
Direct messaging between clients and their lawyers, tied to an appointment
(confirmed, or resolved within 24 hours of resolve time).

Client routes  (Firebase user token):
  GET    /appointments/{id}/messages           → list messages (polling)
  POST   /appointments/{id}/messages           → send text message
  POST   /appointments/{id}/messages/upload    → send attachment
  PATCH  /appointments/{id}/messages/read      → mark incoming as read

Lawyer routes  (Firebase lawyer token):
  GET    /lawyer/appointments/{id}/messages
  POST   /lawyer/appointments/{id}/messages
  POST   /lawyer/appointments/{id}/messages/upload
  PATCH  /lawyer/appointments/{id}/messages/read
"""

import logging
import uuid
from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.core.lawyer_security import get_current_lawyer
from app.models.lawyer_profile import LawyerProfile
from app.models.user import User
from app.schemas.direct_message import DirectMessageCreate, DirectMessageListResponse, DirectMessageResponse
from app.services import direct_message_service, notification_service
from app.services.storage_service import upload_chat_attachment

logger = logging.getLogger(__name__)

# ── Shared helpers ─────────────────────────────────────────────────────────────

_MAX_UPLOAD_BYTES = 12 * 1024 * 1024  # 12 MB
_MESSAGING_AFTER_RESOLVE = timedelta(hours=24)


def _resolved_messaging_closes_at_utc(appt) -> datetime | None:
    """End of the post-resolve window for new messages (UTC), or None if not applicable."""
    if getattr(appt, "status", None) != "resolved":
        return None
    ref = getattr(appt, "resolved_at", None) or getattr(appt, "updated_at", None)
    if ref is None:
        return None
    if ref.tzinfo is None:
        ref = ref.replace(tzinfo=timezone.utc)
    else:
        ref = ref.astimezone(timezone.utc)
    return ref + _MESSAGING_AFTER_RESOLVE


def _require_messaging_open(appt) -> None:
    """Allow messaging for confirmed cases, and for 24 hours after resolve."""
    st = getattr(appt, "status", None)
    if st == "confirmed":
        return
    if st == "resolved":
        deadline = _resolved_messaging_closes_at_utc(appt)
        now = datetime.now(timezone.utc)
        if deadline is not None and now <= deadline:
            return
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This case is resolved and the 24-hour messaging window has ended.",
        )
    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail="Messaging is not available for this appointment.",
    )


def _to_response(msg) -> DirectMessageResponse:
    return DirectMessageResponse.model_validate(msg)


# ── Client router ──────────────────────────────────────────────────────────────

client_router = APIRouter(prefix="/appointments", tags=["direct-messages"])


@client_router.get("/{appointment_id}/messages", response_model=DirectMessageListResponse)
async def client_list_messages(
    appointment_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    since: datetime | None = Query(
        default=None,
        description="ISO-8601 timestamp; returns only messages created after this point.",
    ),
):
    appt = await direct_message_service.get_appointment_for_client(
        db, appointment_id, current_user.id
    )
    if appt is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Appointment not found or not available for messaging.",
        )

    messages = await direct_message_service.list_messages(db, appointment_id, since=since)
    unread = await direct_message_service.count_unread(db, appointment_id, reader_type="client")
    return DirectMessageListResponse(
        messages=[_to_response(m) for m in messages],
        unread_count=unread,
    )


@client_router.post(
    "/{appointment_id}/messages",
    response_model=DirectMessageResponse,
    status_code=status.HTTP_201_CREATED,
)
async def client_send_message(
    appointment_id: uuid.UUID,
    body: DirectMessageCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    appt = await direct_message_service.get_appointment_for_client(
        db, appointment_id, current_user.id
    )
    if appt is None:
        raise HTTPException(status_code=404, detail="Appointment not found or not available for messaging.")

    _require_messaging_open(appt)

    msg = await direct_message_service.send_message(
        db,
        appointment_id=appointment_id,
        sender_type="client",
        content=body.content,
    )
    await db.commit()

    # Notify the lawyer
    try:
        await notification_service.create_notification(
            db,
            user_id=appt.lawyer_profile.user_id,
            notification_type="new_direct_message",
            title="New message from client",
            body=f"{current_user.full_name or 'Client'}: {body.content[:80]}",
            payload={"appointment_id": str(appointment_id)},
        )
        await db.commit()
    except Exception:
        logger.warning("Failed to create lawyer notification for direct message", exc_info=True)

    return _to_response(msg)


@client_router.post(
    "/{appointment_id}/messages/upload",
    response_model=DirectMessageResponse,
    status_code=status.HTTP_201_CREATED,
)
async def client_upload_attachment(
    appointment_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    file: UploadFile = File(...),
    caption: str | None = Form(default=None),
):
    appt = await direct_message_service.get_appointment_for_client(
        db, appointment_id, current_user.id
    )
    if appt is None:
        raise HTTPException(status_code=404, detail="Appointment not found or not available for messaging.")

    _require_messaging_open(appt)

    raw = await file.read()
    if len(raw) > _MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="File too large (max 12 MB).")

    try:
        url = upload_chat_attachment(
            appointment_id=str(appointment_id),
            sender_type="client",
            filename=file.filename or "attachment",
            content=raw,
            content_type=file.content_type or "application/octet-stream",
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    msg = await direct_message_service.send_message(
        db,
        appointment_id=appointment_id,
        sender_type="client",
        content=caption,
        attachment_url=url,
        attachment_name=file.filename,
        attachment_content_type=file.content_type,
    )
    await db.commit()

    try:
        await notification_service.create_notification(
            db,
            user_id=appt.lawyer_profile.user_id,
            notification_type="new_direct_message",
            title="New file from client",
            body=f"{current_user.full_name or 'Client'} sent a file: {file.filename or 'attachment'}",
            payload={"appointment_id": str(appointment_id)},
        )
        await db.commit()
    except Exception:
        logger.warning("Failed to create lawyer notification for attachment", exc_info=True)

    return _to_response(msg)


@client_router.patch(
    "/{appointment_id}/messages/read",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def client_mark_read(
    appointment_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    appt = await direct_message_service.get_appointment_for_client(
        db, appointment_id, current_user.id
    )
    if appt is None:
        raise HTTPException(status_code=404, detail="Appointment not found.")

    await direct_message_service.mark_read_for(db, appointment_id, reader_type="client")
    await db.commit()


# ── Lawyer router ──────────────────────────────────────────────────────────────

lawyer_router = APIRouter(prefix="/lawyer/appointments", tags=["direct-messages"])


@lawyer_router.get("/{appointment_id}/messages", response_model=DirectMessageListResponse)
async def lawyer_list_messages(
    appointment_id: uuid.UUID,
    lawyer_auth: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
    since: datetime | None = Query(default=None),
):
    _, profile = lawyer_auth
    appt = await direct_message_service.get_appointment_for_lawyer(
        db, appointment_id, profile.id
    )
    if appt is None:
        raise HTTPException(status_code=404, detail="Appointment not found or not available for messaging.")

    messages = await direct_message_service.list_messages(db, appointment_id, since=since)
    unread = await direct_message_service.count_unread(db, appointment_id, reader_type="lawyer")
    return DirectMessageListResponse(
        messages=[_to_response(m) for m in messages],
        unread_count=unread,
    )


@lawyer_router.post(
    "/{appointment_id}/messages",
    response_model=DirectMessageResponse,
    status_code=status.HTTP_201_CREATED,
)
async def lawyer_send_message(
    appointment_id: uuid.UUID,
    body: DirectMessageCreate,
    lawyer_auth: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    user, profile = lawyer_auth
    appt = await direct_message_service.get_appointment_for_lawyer(
        db, appointment_id, profile.id
    )
    if appt is None:
        raise HTTPException(status_code=404, detail="Appointment not found or not available for messaging.")

    _require_messaging_open(appt)

    msg = await direct_message_service.send_message(
        db,
        appointment_id=appointment_id,
        sender_type="lawyer",
        content=body.content,
    )
    await db.commit()

    # Notify the client (if they have a user account)
    if appt.client_user_id:
        try:
            lawyer_name = profile.display_name or "Your lawyer"
            await notification_service.create_notification(
                db,
                user_id=appt.client_user_id,
                notification_type="new_direct_message",
                title=f"New message from {lawyer_name}",
                body=body.content[:80],
                payload={"appointment_id": str(appointment_id)},
            )
            await db.commit()
        except Exception:
            logger.warning("Failed to create client notification for direct message", exc_info=True)

    return _to_response(msg)


@lawyer_router.post(
    "/{appointment_id}/messages/upload",
    response_model=DirectMessageResponse,
    status_code=status.HTTP_201_CREATED,
)
async def lawyer_upload_attachment(
    appointment_id: uuid.UUID,
    lawyer_auth: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
    file: UploadFile = File(...),
    caption: str | None = Form(default=None),
):
    user, profile = lawyer_auth
    appt = await direct_message_service.get_appointment_for_lawyer(
        db, appointment_id, profile.id
    )
    if appt is None:
        raise HTTPException(status_code=404, detail="Appointment not found or not available for messaging.")

    _require_messaging_open(appt)

    raw = await file.read()
    if len(raw) > _MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="File too large (max 12 MB).")

    try:
        url = upload_chat_attachment(
            appointment_id=str(appointment_id),
            sender_type="lawyer",
            filename=file.filename or "attachment",
            content=raw,
            content_type=file.content_type or "application/octet-stream",
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    msg = await direct_message_service.send_message(
        db,
        appointment_id=appointment_id,
        sender_type="lawyer",
        content=caption,
        attachment_url=url,
        attachment_name=file.filename,
        attachment_content_type=file.content_type,
    )
    await db.commit()

    if appt.client_user_id:
        try:
            lawyer_name = profile.display_name or "Your lawyer"
            await notification_service.create_notification(
                db,
                user_id=appt.client_user_id,
                notification_type="new_direct_message",
                title=f"New file from {lawyer_name}",
                body=f"Sent a file: {file.filename or 'attachment'}",
                payload={"appointment_id": str(appointment_id)},
            )
            await db.commit()
        except Exception:
            logger.warning("Failed to create client notification for attachment", exc_info=True)

    return _to_response(msg)


@lawyer_router.patch(
    "/{appointment_id}/messages/read",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def lawyer_mark_read(
    appointment_id: uuid.UUID,
    lawyer_auth: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    _, profile = lawyer_auth
    appt = await direct_message_service.get_appointment_for_lawyer(
        db, appointment_id, profile.id
    )
    if appt is None:
        raise HTTPException(status_code=404, detail="Appointment not found.")

    await direct_message_service.mark_read_for(db, appointment_id, reader_type="lawyer")
    await db.commit()
