import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, field_validator

APPOINTMENT_TYPES: list[str] = [
    "Initial Consultation",
    "Document Review",
    "Follow-Up",
    "Hearing Preparation",
    "Deposition",
    "Settlement Discussion",
    "Case Update",
    "Other",
]

APPOINTMENT_STATUSES: list[str] = ["pending", "confirmed", "cancelled"]


# --- Mobile client: book an appointment ---

class AppointmentBookRequest(BaseModel):
    lawyer_profile_id: uuid.UUID
    appointment_date: date
    appointment_time: str   # "HH:MM"
    appointment_type: str
    description: str | None = None

    @field_validator("appointment_time")
    @classmethod
    def validate_time(cls, v: str) -> str:
        parts = v.split(":")
        if len(parts) != 2 or not parts[0].isdigit() or not parts[1].isdigit():
            raise ValueError("Time must be in HH:MM format")
        h, m = int(parts[0]), int(parts[1])
        if not (0 <= h <= 23 and 0 <= m <= 59):
            raise ValueError("Invalid time value")
        return v

    @field_validator("appointment_type")
    @classmethod
    def validate_type(cls, v: str) -> str:
        if v not in APPOINTMENT_TYPES:
            raise ValueError(f"Invalid appointment type")
        return v


# --- Lawyer web portal: create or update ---

class AppointmentCreateRequest(BaseModel):
    client_name: str
    appointment_date: date
    appointment_time: str
    appointment_type: str
    description: str | None = None

    @field_validator("client_name")
    @classmethod
    def validate_client_name(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Client name cannot be blank")
        return v.strip()

    @field_validator("appointment_time")
    @classmethod
    def validate_time(cls, v: str) -> str:
        parts = v.split(":")
        if len(parts) != 2 or not parts[0].isdigit() or not parts[1].isdigit():
            raise ValueError("Time must be in HH:MM format")
        h, m = int(parts[0]), int(parts[1])
        if not (0 <= h <= 23 and 0 <= m <= 59):
            raise ValueError("Invalid time value")
        return v

    @field_validator("appointment_type")
    @classmethod
    def validate_type(cls, v: str) -> str:
        if v not in APPOINTMENT_TYPES:
            raise ValueError("Invalid appointment type")
        return v


class AppointmentUpdateRequest(BaseModel):
    client_name: str | None = None
    appointment_date: date | None = None
    appointment_time: str | None = None
    appointment_type: str | None = None
    description: str | None = None
    status: str | None = None

    @field_validator("appointment_time")
    @classmethod
    def validate_time(cls, v: str | None) -> str | None:
        if v is None:
            return v
        parts = v.split(":")
        if len(parts) != 2 or not parts[0].isdigit() or not parts[1].isdigit():
            raise ValueError("Time must be in HH:MM format")
        h, m = int(parts[0]), int(parts[1])
        if not (0 <= h <= 23 and 0 <= m <= 59):
            raise ValueError("Invalid time value")
        return v

    @field_validator("status")
    @classmethod
    def validate_status(cls, v: str | None) -> str | None:
        if v is not None and v not in APPOINTMENT_STATUSES:
            raise ValueError("Invalid status")
        return v


# --- Responses ---

class AppointmentRejectRequest(BaseModel):
    reason: str

    @field_validator("reason")
    @classmethod
    def validate_reason(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Rejection reason cannot be blank")
        return v.strip()


class AppointmentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    lawyer_profile_id: uuid.UUID
    client_user_id: uuid.UUID | None
    client_name: str
    appointment_date: date
    appointment_time: str
    appointment_type: str
    description: str | None
    status: str
    rejection_reason: str | None
    created_at: datetime
    updated_at: datetime | None


class AppointmentListResponse(BaseModel):
    appointments: list[AppointmentResponse]
