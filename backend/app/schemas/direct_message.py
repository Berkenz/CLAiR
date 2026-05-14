import uuid
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class DirectMessageCreate(BaseModel):
    content: str = Field(..., min_length=1, max_length=4000)


class DirectMessageResponse(BaseModel):
    id: uuid.UUID
    appointment_id: uuid.UUID
    sender_type: Literal["client", "lawyer"]
    content: str | None
    attachment_url: str | None
    attachment_name: str | None
    attachment_content_type: str | None
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class DirectMessageListResponse(BaseModel):
    messages: list[DirectMessageResponse]
    unread_count: int
