import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


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


class GoogleAuthResponse(BaseModel):
    user: UserResponse | None = None
    is_new_user: bool = False
