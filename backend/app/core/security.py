from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.firebase import verify_firebase_token
from app.models.user import User
from app.services.user_service import user_service

security = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(security)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    """Extract Bearer token, verify with Firebase, then look up or create user in DB."""
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = credentials.credentials
    decoded = verify_firebase_token(token)

    firebase_uid = decoded.get("uid")
    if not firebase_uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token: missing uid",
        )

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

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is deactivated",
        )

    return user
