import uuid

from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    role: str = Field(..., pattern="^(user|model)$")
    text: str


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=4000)
    history: list[ChatMessage] = Field(default_factory=list)
    conversation_id: uuid.UUID | None = None


class ChatResponse(BaseModel):
    reply: str
    conversation_id: uuid.UUID
