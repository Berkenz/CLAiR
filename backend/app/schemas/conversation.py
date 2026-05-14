import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ConversationUpdate(BaseModel):
    title: str | None = None
    is_pinned: bool | None = None


class ConversationSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str
    is_pinned: bool = False
    created_at: datetime
    updated_at: datetime | None = None


class MessageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    role: str
    text: str
    created_at: datetime


class ConversationDetail(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str
    is_pinned: bool = False
    messages: list[MessageResponse]
    created_at: datetime
    updated_at: datetime | None = None


class ConversationListResponse(BaseModel):
    conversations: list[ConversationSummary]


class AppointmentSummaryResponse(BaseModel):
    """AI-generated text for booking forms (mobile app)."""

    summary: str
