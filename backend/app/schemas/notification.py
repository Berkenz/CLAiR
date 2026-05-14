import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class NotificationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    notification_type: str
    title: str
    body: str | None
    payload: dict | None
    is_read: bool
    created_at: datetime


class NotificationListResponse(BaseModel):
    notifications: list[NotificationResponse]
    unread_count: int
