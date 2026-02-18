from typing import Annotated

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.user import UserResponse
from app.services.user_service import user_service
from app.core.firebase import verify_firebase_token
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/auth", tags=["auth"])


class GoogleAuthRequest(BaseModel):
    id_token: str


@router.post("/google", response_model=UserResponse)
async def auth_google(
    body: GoogleAuthRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    """Accept Firebase ID token, verify it, create or get user in DB, return UserResponse."""
    decoded = verify_firebase_token(body.id_token)
    firebase_uid = decoded.get("uid", "")
    email = decoded.get("email") or ""
    display_name = decoded.get("name")
    photo_url = decoded.get("picture")

    user = await user_service.get_or_create_user(
        db=db,
        firebase_uid=firebase_uid,
        email=email,
        display_name=display_name,
        photo_url=photo_url,
    )
    return user


@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user: Annotated[User, Depends(get_current_user)],
) -> User:
    """Return the current authenticated user's info."""
    return current_user
