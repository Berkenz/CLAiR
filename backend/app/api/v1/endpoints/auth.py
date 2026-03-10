from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.core.firebase import verify_firebase_token
from app.models.user import User
from app.schemas.user import (
    GoogleAuthRequest,
    GoogleAuthResponse,
    GoogleCompleteRequest,
    GuestAuthRequest,
    LoginRequest,
    RegisterRequest,
    UserResponse,
)
from app.services.user_service import user_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=UserResponse)
async def register(
    body: RegisterRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """
    Register a new user with email/password.
    The Flutter client creates the Firebase user first, then calls this
    endpoint with the Firebase ID token plus first/last name.
    """
    decoded = verify_firebase_token(body.firebase_token)
    firebase_uid = decoded["uid"]
    email = decoded.get("email")

    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Firebase token must contain an email",
        )

    existing = await user_service.get_user_by_firebase_uid(db, firebase_uid)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User already registered",
        )

    user = await user_service.create_user(
        db,
        firebase_uid=firebase_uid,
        email=email,
        first_name=body.first_name,
        last_name=body.last_name,
        auth_provider="email",
        is_email_verified=decoded.get("email_verified", False),
    )
    return user


@router.post("/login", response_model=UserResponse)
async def login(
    body: LoginRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """
    Login with email/password.
    The Flutter client authenticates with Firebase first, then sends
    the ID token here. Backend looks up the user in the database.
    """
    decoded = verify_firebase_token(body.firebase_token)
    firebase_uid = decoded["uid"]

    user = await user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found. Please register first.",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is deactivated",
        )

    if decoded.get("email_verified") and not user.is_email_verified:
        user = await user_service.set_email_verified(db, user)

    if user.auth_provider == "email" and not user.is_email_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Please verify your email before logging in.",
        )

    return user


@router.post("/google", response_model=GoogleAuthResponse)
async def google_auth(
    body: GoogleAuthRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """
    Google Sign-In flow.
    Returns the existing user if found, or signals that the user
    needs to complete registration (provide first/last name).
    """
    decoded = verify_firebase_token(body.firebase_token)
    firebase_uid = decoded["uid"]

    user = await user_service.get_user_by_firebase_uid(db, firebase_uid)
    if user:
        return GoogleAuthResponse(
            user=UserResponse.model_validate(user),
            is_new_user=False,
        )

    return GoogleAuthResponse(user=None, is_new_user=True)


@router.post("/google/complete", response_model=UserResponse)
async def google_complete(
    body: GoogleCompleteRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """
    Complete Google Sign-In registration.
    Called after /auth/google returns is_new_user=true.
    The user provides their first and last name.
    """
    decoded = verify_firebase_token(body.firebase_token)
    firebase_uid = decoded["uid"]
    email = decoded.get("email")
    photo_url = decoded.get("picture")

    existing = await user_service.get_user_by_firebase_uid(db, firebase_uid)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User already registered",
        )

    user = await user_service.create_user(
        db,
        firebase_uid=firebase_uid,
        email=email,
        first_name=body.first_name,
        last_name=body.last_name,
        photo_url=photo_url,
        auth_provider="google",
        is_email_verified=True,
    )
    return user


@router.post("/guest", response_model=UserResponse)
async def guest_auth(
    body: GuestAuthRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """
    Continue as guest (anonymous Firebase auth).
    Creates an anonymous user record in the database.
    """
    decoded = verify_firebase_token(body.firebase_token)
    firebase_uid = decoded["uid"]

    existing = await user_service.get_user_by_firebase_uid(db, firebase_uid)
    if existing:
        return existing

    user = await user_service.create_user(
        db,
        firebase_uid=firebase_uid,
        auth_provider="anonymous",
        is_anonymous=True,
    )
    return user


@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Return the current authenticated user's info."""
    return current_user
