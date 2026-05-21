import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, model_validator
from typing import Self

from app.utils.photo_url import photo_url_with_cache_bust


# --- Request schemas ---

class RegisterRequest(BaseModel):
    firebase_token: str
    first_name: str
    last_name: str


class LoginRequest(BaseModel):
    firebase_token: str


class GoogleAuthRequest(BaseModel):
    firebase_token: str


class GoogleCompleteRequest(BaseModel):
    firebase_token: str
    first_name: str
    last_name: str


class GuestAuthRequest(BaseModel):
    firebase_token: str


class UserUpdate(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    photo_url: str | None = None
    location: str | None = None


class FcmTokenRegisterRequest(BaseModel):
    token: str


# --- Response schemas ---

class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    firebase_uid: str
    email: str | None = None
    first_name: str | None = None
    last_name: str | None = None
    photo_url: str | None = None
    location: str | None = None
    auth_provider: str
    is_email_verified: bool
    is_anonymous: bool
    is_active: bool
    created_at: datetime
    updated_at: datetime | None = None

    @model_validator(mode="after")
    def bust_profile_photo_url(self) -> Self:
        """Always bust profile photos from updated_at (stable storage path per user)."""
        busted = photo_url_with_cache_bust(self.photo_url, self.updated_at)
        if busted is not None:
            self.photo_url = busted
        return self


class GoogleAuthResponse(BaseModel):
    user: UserResponse | None = None
    is_new_user: bool = False
