import uuid

from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    role: str = Field(..., pattern="^(user|model)$")
    text: str


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=4000)
    history: list[ChatMessage] = Field(default_factory=list)
    conversation_id: uuid.UUID | None = None
    user_lat: float | None = None
    user_lng: float | None = None


class SuggestedLawyer(BaseModel):
    id: str
    display_name: str | None = None
    designation: str | None = None
    practice_areas: list[str] = Field(default_factory=list)
    bio: str | None = None
    office_address: str | None = None
    office_hours: dict | None = None
    office_phone: str | None = None
    mobile_phone: str | None = None
    office_email: str | None = None
    latitude: float | None = None
    longitude: float | None = None


class ChatResponse(BaseModel):
    reply: str
    conversation_id: uuid.UUID
    conversation_title: str
    suggested_lawyers: list[SuggestedLawyer] = Field(default_factory=list)
