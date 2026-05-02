import uuid
from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator


class AssessmentMessageOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    role: str
    text: str
    created_at: datetime


class AssessmentFeedbackItemOut(BaseModel):
    message_id: uuid.UUID
    feedback_type: str
    issue_codes: list[str] | None = None
    comment: str | None = None


class SharedBookingSummaryOut(BaseModel):
    """Latest booking row that attached this conversation (list view)."""

    appointment_id: uuid.UUID
    shared_at: datetime
    appointment_date: date
    appointment_time: str
    appointment_type: str
    status: str


class SharedBookingDetailOut(SharedBookingSummaryOut):
    """One booking that referenced this shared conversation (detail may list several)."""

    description_preview: str | None = None


class ClientConversationSummaryOut(BaseModel):
    id: uuid.UUID
    title: str
    updated_at: datetime | None = None
    client_display_name: str
    latest_shared_booking: SharedBookingSummaryOut


class ClientConversationListOut(BaseModel):
    conversations: list[ClientConversationSummaryOut]


class ClientConversationDetailOut(BaseModel):
    id: uuid.UUID
    title: str
    updated_at: datetime | None = None
    client_display_name: str
    messages: list[AssessmentMessageOut]
    my_feedback: list[AssessmentFeedbackItemOut]
    shared_bookings: list[SharedBookingDetailOut]


class LawyerAiFeedbackCreate(BaseModel):
    message_id: uuid.UUID
    feedback_type: Literal["commend", "report"]
    issue_codes: list[str] = Field(default_factory=list)
    comment: str | None = Field(None, max_length=4000)

    @model_validator(mode="after")
    def report_needs_issues(self) -> "LawyerAiFeedbackCreate":
        if self.feedback_type == "report" and not self.issue_codes:
            raise ValueError("At least one issue code is required for reports")
        return self


class LawyerAiFeedbackResponse(BaseModel):
    message_id: uuid.UUID
    feedback_type: str
    issue_codes: list[str] | None = None
    comment: str | None = None
