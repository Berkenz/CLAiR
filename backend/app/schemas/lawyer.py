import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, field_validator


# --- Static option lists ---

PRACTICE_AREAS: list[str] = [
    "Administrative Law",
    "Banking & Finance Law",
    "Civil Law",
    "Constitutional Law",
    "Corporate Law",
    "Criminal Law",
    "Environmental Law",
    "Family Law",
    "Immigration Law",
    "Insurance Law",
    "Intellectual Property Law",
    "Labor Law",
    "Real Estate Law",
    "Tax Law",
    "Other",
]

DESIGNATIONS: list[str] = [
    "Associate",
    "Junior Associate",
    "Of Counsel",
    "Paralegal",
    "Senior Associate",
    "Senior Partner",
    "Managing Partner",
    "Associate Partner",
    "Other",
]


# --- Request schemas ---

class LawyerLoginRequest(BaseModel):
    firebase_token: str


class LawyerProfileUpdate(BaseModel):
    first_name: str
    last_name: str
    display_name: str
    designation: str
    practice_areas: list[str]

    @field_validator("practice_areas")
    @classmethod
    def validate_practice_areas(cls, v: list[str]) -> list[str]:
        if not v:
            raise ValueError("At least one practice area is required")
        return v

    @field_validator("first_name", "last_name", "display_name", "designation")
    @classmethod
    def validate_not_blank(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("Field cannot be blank")
        return v.strip()


# --- Response schemas ---

class LawyerProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    display_name: str | None = None
    designation: str | None = None
    practice_areas: list[str] | None = None
    must_change_password: bool
    is_profile_complete: bool
    created_at: datetime
    updated_at: datetime | None = None


class LawyerUserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    firebase_uid: str
    email: str | None = None
    first_name: str | None = None
    last_name: str | None = None
    photo_url: str | None = None
    is_active: bool
    created_at: datetime


class LawyerLoginResponse(BaseModel):
    user: LawyerUserResponse
    profile: LawyerProfileResponse


class OptionsResponse(BaseModel):
    practice_areas: list[str]
    designations: list[str]
