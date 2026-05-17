import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.core.lawyer_security import get_current_lawyer
from app.models.lawyer_profile import LawyerProfile
from app.models.user import User
from app.schemas.notification import NotificationListResponse, NotificationResponse
from app.services import notification_service

router = APIRouter(prefix="/lawyer/notifications", tags=["lawyer-notifications"])

LawyerDep = Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)]
DbDep = Annotated[AsyncSession, Depends(get_db)]


class UnreadCountResponse(BaseModel):
    unread_count: int


@router.get("", response_model=NotificationListResponse)
async def list_lawyer_notifications(lawyer: LawyerDep, db: DbDep):
    user, _ = lawyer
    rows, unread = await notification_service.list_notifications_for_user(db, user.id)
    return NotificationListResponse(
        notifications=[NotificationResponse.model_validate(r) for r in rows],
        unread_count=unread,
    )


@router.get("/unread-count", response_model=UnreadCountResponse)
async def get_unread_count(lawyer: LawyerDep, db: DbDep):
    user, _ = lawyer
    _, unread = await notification_service.list_notifications_for_user(db, user.id, limit=0)
    return UnreadCountResponse(unread_count=unread)


@router.patch("/{notification_id}/read", response_model=NotificationResponse)
async def mark_notification_read(
    notification_id: uuid.UUID, lawyer: LawyerDep, db: DbDep
):
    user, _ = lawyer
    row = await notification_service.mark_read(db, user_id=user.id, notification_id=notification_id)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    return NotificationResponse.model_validate(row)


@router.patch("/read-all", status_code=status.HTTP_204_NO_CONTENT)
async def mark_all_read(lawyer: LawyerDep, db: DbDep):
    user, _ = lawyer
    await notification_service.mark_all_read(db, user_id=user.id)


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
async def delete_all(lawyer: LawyerDep, db: DbDep):
    user, _ = lawyer
    await notification_service.delete_all_notifications(db, user_id=user.id)


@router.delete("/{notification_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_one(notification_id: uuid.UUID, lawyer: LawyerDep, db: DbDep):
    user, _ = lawyer
    ok = await notification_service.delete_notification(db, user_id=user.id, notification_id=notification_id)
    if not ok:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
