import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class UserBase(BaseModel):
    email: str
    display_name: str | None = None
    photo_url: str | None = None


class UserCreate(BaseModel):
    firebase_uid: str
    email: str
    display_name: str | None = None
    photo_url: str | None = None


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    firebase_uid: str
    email: str
    display_name: str | None = None
    photo_url: str | None = None
    is_active: bool
    created_at: datetime
    updated_at: datetime | None = None


class UserUpdate(BaseModel):
    display_name: str | None = None
    photo_url: str | None = None
