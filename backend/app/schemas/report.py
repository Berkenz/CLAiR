from pydantic import BaseModel, Field, model_validator


class ReportMessageItem(BaseModel):
    role: str
    text: str


class ConversationReportRequest(BaseModel):
    category: str = Field(..., min_length=1, max_length=200)
    explanation: str = Field(..., min_length=12, max_length=2000)
    conversation_id: str | None = None
    reported_message_excerpt: str | None = None
    messages: list[ReportMessageItem] = Field(default_factory=list, max_length=100)


class ConversationReportResponse(BaseModel):
    ok: bool = True


class UserReportRequest(BaseModel):
    reported_user_id: str | None = None
    reported_lawyer_profile_id: str | None = None
    category: str = Field(..., min_length=1, max_length=200)
    explanation: str = Field(..., min_length=12, max_length=2000)

    @model_validator(mode="after")
    def _require_one_target(self):
        if not self.reported_user_id and not self.reported_lawyer_profile_id:
            raise ValueError(
                "Provide either reported_user_id or reported_lawyer_profile_id"
            )
        return self


class UserReportResponse(BaseModel):
    ok: bool = True
