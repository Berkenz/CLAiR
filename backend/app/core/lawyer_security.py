from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.firebase import verify_firebase_token
from app.database import get_db
from app.models.lawyer_profile import LawyerProfile
from app.models.user import User
from app.services.lawyer_service import lawyer_service
from app.services.user_service import user_service

_security = HTTPBearer(auto_error=False)


async def get_current_lawyer(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_security)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> tuple[User, LawyerProfile]:
    """
    Dependency for lawyer-only endpoints.

    Verifies the Firebase ID token, resolves the DB user, and confirms a
    lawyer profile exists (created on first login via /lawyer/auth/login).
    Returns (user, lawyer_profile). Raises 401 / 403 on any failure.
    """
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )

    decoded = verify_firebase_token(credentials.credentials)

    firebase_uid: str | None = decoded.get("uid")
    if not firebase_uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token: missing uid",
        )

    user = await user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found. Please log in again.",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account has been deactivated.",
        )

    profile = await lawyer_service.get_profile_by_user_id(db, user.id)
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Lawyer profile not found. Please log in via /lawyer/auth/login first.",
        )

    return user, profile
