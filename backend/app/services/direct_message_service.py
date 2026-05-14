"""Service layer for direct client↔lawyer messaging tied to an appointment."""

import uuid
from datetime import datetime, timezone

from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.appointment import Appointment
from app.models.direct_message import DirectMessage
from app.models.lawyer_profile import LawyerProfile


async def get_appointment_for_client(
    db: AsyncSession,
    appointment_id: uuid.UUID,
    client_user_id: uuid.UUID,
) -> Appointment | None:
    result = await db.execute(
        select(Appointment)
        .options(
            selectinload(Appointment.lawyer_profile).selectinload(LawyerProfile.user),
            selectinload(Appointment.client_user),
        )
        .where(
            Appointment.id == appointment_id,
            Appointment.client_user_id == client_user_id,
            Appointment.status == "confirmed",
        )
    )
    return result.scalar_one_or_none()


async def get_appointment_for_lawyer(
    db: AsyncSession,
    appointment_id: uuid.UUID,
    lawyer_profile_id: uuid.UUID,
) -> Appointment | None:
    result = await db.execute(
        select(Appointment)
        .options(
            selectinload(Appointment.lawyer_profile).selectinload(LawyerProfile.user),
            selectinload(Appointment.client_user),
        )
        .where(
            Appointment.id == appointment_id,
            Appointment.lawyer_profile_id == lawyer_profile_id,
            Appointment.status == "confirmed",
        )
    )
    return result.scalar_one_or_none()


async def list_messages(
    db: AsyncSession,
    appointment_id: uuid.UUID,
    since: datetime | None = None,
    limit: int = 200,
) -> list[DirectMessage]:
    stmt = (
        select(DirectMessage)
        .where(DirectMessage.appointment_id == appointment_id)
        .order_by(DirectMessage.created_at.asc())
        .limit(limit)
    )
    if since is not None:
        stmt = stmt.where(DirectMessage.created_at > since)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def count_unread(
    db: AsyncSession,
    appointment_id: uuid.UUID,
    reader_type: str,
) -> int:
    """Count messages sent by the *other* side that are not yet read."""
    sender_type = "lawyer" if reader_type == "client" else "client"
    result = await db.execute(
        select(func.count())
        .select_from(DirectMessage)
        .where(
            DirectMessage.appointment_id == appointment_id,
            DirectMessage.sender_type == sender_type,
            DirectMessage.is_read.is_(False),
        )
    )
    return int(result.scalar_one() or 0)


async def send_message(
    db: AsyncSession,
    *,
    appointment_id: uuid.UUID,
    sender_type: str,
    content: str | None = None,
    attachment_url: str | None = None,
    attachment_name: str | None = None,
    attachment_content_type: str | None = None,
) -> DirectMessage:
    msg = DirectMessage(
        appointment_id=appointment_id,
        sender_type=sender_type,
        content=content,
        attachment_url=attachment_url,
        attachment_name=attachment_name,
        attachment_content_type=attachment_content_type,
        is_read=False,
    )
    db.add(msg)
    await db.flush()
    await db.refresh(msg)
    return msg


async def mark_read_for(
    db: AsyncSession,
    appointment_id: uuid.UUID,
    reader_type: str,
) -> int:
    """Mark all messages sent by the other side as read. Returns count updated."""
    sender_type = "lawyer" if reader_type == "client" else "client"
    result = await db.execute(
        update(DirectMessage)
        .where(
            DirectMessage.appointment_id == appointment_id,
            DirectMessage.sender_type == sender_type,
            DirectMessage.is_read.is_(False),
        )
        .values(is_read=True)
    )
    return result.rowcount  # type: ignore[return-value]
