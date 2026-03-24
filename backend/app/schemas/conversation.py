import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ConversationSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    title: str
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
    messages: list[MessageResponse]
    created_at: datetime
    updated_at: datetime | None = None


class ConversationListResponse(BaseModel):
    conversations: list[ConversationSummary]
