import uuid

from typing import Literal

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
    locale: Literal["en", "fil", "ceb"] = "en"


class SuggestedLawyer(BaseModel):
    id: str
    display_name: str | None = None
    designation: str | None = None
    practice_areas: list[str] = Field(default_factory=list)
    first_name: str | None = None
    last_name: str | None = None
    photo_url: str | None = None
    bio: str | None = None
    office_address: str | None = None
    office_hours: dict | None = None
    office_phone: str | None = None
    mobile_phone: str | None = None
    office_email: str | None = None
    latitude: float | None = None
    longitude: float | None = None


class RagSourceItem(BaseModel):
    """One retrieved law chunk surfaced to the client for transparency / QA."""

    number: str | None = None
    title: str = ""
    category: str | None = None
    similarity: float = 0.0
    source_url: str | None = None


class TavilySourceItem(BaseModel):
    """One real-time result from a trusted Philippine legal/government website."""

    title: str = ""
    url: str = ""
    score: float = 0.0


class ChatResponse(BaseModel):
    reply: str
    conversation_id: uuid.UUID | None = None
    conversation_title: str = ""
    user_message_id: uuid.UUID | None = None
    assistant_message_id: uuid.UUID | None = None
    suggested_lawyers: list[SuggestedLawyer] = Field(default_factory=list)
    # RAG transparency: same retrieval as injected into the LLM prompt.
    rag_enabled: bool = False
    rag_sources: list[RagSourceItem] = Field(default_factory=list)
    # Real-time web search results from trusted PH legal domains (Tavily).
    tavily_sources: list[TavilySourceItem] = Field(default_factory=list)
