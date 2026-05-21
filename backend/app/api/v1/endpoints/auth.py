from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.core.firebase import verify_firebase_token
from app.core.platform_auth import (
    ensure_client_platform_user,
    ensure_email_available_for_client,
)
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
        await ensure_client_platform_user(db, existing)
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="User already registered",
        )

    await ensure_email_available_for_client(db, email)

    existing_by_email = await user_service.get_user_by_email(db, email)
    if existing_by_email:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists",
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

    await ensure_client_platform_user(db, user)

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
        await ensure_client_platform_user(db, user)
        return GoogleAuthResponse(
            user=UserResponse.model_validate(user),
            is_new_user=False,
        )

    if email := decoded.get("email"):
        await ensure_email_available_for_client(db, email)

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
        await ensure_client_platform_user(db, existing)
        return existing

    if email:
        await ensure_email_available_for_client(db, email)
        existing_by_email = await user_service.get_user_by_email(db, email)
        if existing_by_email:
            await ensure_client_platform_user(db, existing_by_email)
            if existing_by_email.firebase_uid == firebase_uid:
                existing_by_email.first_name = body.first_name
                existing_by_email.last_name = body.last_name
                if photo_url:
                    existing_by_email.photo_url = photo_url
                await db.flush()
                await db.refresh(existing_by_email)
                return existing_by_email
            if existing_by_email.auth_provider == "email":
                # Same person: email/password account completing Google registration.
                existing_by_email.firebase_uid = firebase_uid
                existing_by_email.auth_provider = "google"
                existing_by_email.is_email_verified = True
                existing_by_email.first_name = body.first_name
                existing_by_email.last_name = body.last_name
                if photo_url:
                    existing_by_email.photo_url = photo_url
                await db.flush()
                await db.refresh(existing_by_email)
                return existing_by_email
            # Stale row (e.g. account was deleted in Firebase but DB user remained).
            await user_service.delete_user(db, existing_by_email)

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


@router.delete("/account", status_code=status.HTTP_204_NO_CONTENT)
async def delete_account(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """
    Permanently delete the authenticated user and cascaded data (conversations,
    messages, notifications, etc.). The client must delete the Firebase user
    after this call succeeds.
    """
    import logging

    from sqlalchemy.exc import SQLAlchemyError

    from app.core.platform_auth import ensure_client_platform_user

    logger = logging.getLogger(__name__)

    await ensure_client_platform_user(db, current_user)
    try:
        await user_service.delete_user(db, current_user)
    except SQLAlchemyError:
        logger.exception("Failed to delete user %s", current_user.id)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not delete your account. Please try again.",
        ) from None
