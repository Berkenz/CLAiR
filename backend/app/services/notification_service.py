import uuid
from typing import Any

from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user_notification import UserNotification


async def create_notification(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    notification_type: str,
    title: str,
    body: str | None = None,
    payload: dict[str, Any] | None = None,
) -> UserNotification:
    row = UserNotification(
        user_id=user_id,
        notification_type=notification_type,
        title=title,
        body=body,
        payload=payload,
        is_read=False,
    )
    db.add(row)
    await db.flush()
    await db.refresh(row)
    return row


async def list_notifications_for_user(
    db: AsyncSession, user_id: uuid.UUID, *, limit: int = 100
) -> tuple[list[UserNotification], int]:
    count_result = await db.execute(
        select(func.count())
        .select_from(UserNotification)
        .where(UserNotification.user_id == user_id, UserNotification.is_read.is_(False))
    )
    unread = int(count_result.scalar_one() or 0)

    rows_result = await db.execute(
        select(UserNotification)
        .where(UserNotification.user_id == user_id)
        .order_by(UserNotification.created_at.desc())
        .limit(limit)
    )
    rows = list(rows_result.scalars().all())
    return rows, unread


async def mark_read(
    db: AsyncSession, *, user_id: uuid.UUID, notification_id: uuid.UUID
) -> UserNotification | None:
    row = await db.get(UserNotification, notification_id)
    if row is None or row.user_id != user_id:
        return None
    row.is_read = True
    await db.flush()
    await db.refresh(row)
    return row


async def mark_all_read(db: AsyncSession, *, user_id: uuid.UUID) -> int:
    result = await db.execute(
        select(UserNotification).where(
            UserNotification.user_id == user_id,
            UserNotification.is_read.is_(False),
        )
    )
    rows = list(result.scalars().all())
    for r in rows:
        r.is_read = True
    await db.flush()
    return len(rows)


async def delete_notification(
    db: AsyncSession, *, user_id: uuid.UUID, notification_id: uuid.UUID
) -> bool:
    result = await db.execute(
        delete(UserNotification).where(
            UserNotification.id == notification_id,
            UserNotification.user_id == user_id,
        )
    )
    await db.flush()
    return int(result.rowcount or 0) > 0


async def delete_all_notifications(db: AsyncSession, *, user_id: uuid.UUID) -> int:
    result = await db.execute(
        delete(UserNotification).where(UserNotification.user_id == user_id)
    )
    await db.flush()
    return int(result.rowcount or 0)
