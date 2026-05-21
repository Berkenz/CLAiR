from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.core.firebase import verify_firebase_token
from app.core.platform_auth import ensure_lawyer_platform_user
from app.core.lawyer_security import get_current_lawyer
from app.models.lawyer_profile import LawyerProfile
from app.models.user import User
from app.schemas.lawyer import LawyerLoginRequest, LawyerLoginResponse
from app.services.lawyer_service import invalidate_lawyers_directory_cache, lawyer_service
from app.services.user_service import user_service

router = APIRouter(prefix="/lawyer/auth", tags=["lawyer-auth"])


@router.post("/login", response_model=LawyerLoginResponse)
async def lawyer_login(
    body: LawyerLoginRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """
    Lawyer portal login.

    The client authenticates with Firebase first (email + password), then sends
    the ID token here. On first login for admin-provisioned Firebase users, the
    backend creates the DB user row and lawyer profile. Mobile client accounts
    cannot use this endpoint — they need separate lawyer credentials.
    """
    decoded = verify_firebase_token(body.firebase_token)

    firebase_uid: str = decoded["uid"]
    email: str | None = decoded.get("email")

    user = await user_service.get_user_by_firebase_uid(db, firebase_uid)
    user_created = False

    if not user:
        if not email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Firebase token must contain an email.",
            )
        user = await user_service.create_user(
            db,
            firebase_uid=firebase_uid,
            email=email,
            auth_provider="email",
            is_email_verified=decoded.get("email_verified", False),
        )
        user_created = True

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This account has been deactivated. Contact your administrator.",
        )

    if user_created:
        profile = await lawyer_service.get_or_create_profile(db, user)
    else:
        await ensure_lawyer_platform_user(db, user)
        profile = await lawyer_service.get_profile_by_user_id(db, user.id)
        assert profile is not None

    return LawyerLoginResponse.model_validate({"user": user, "profile": profile})


@router.post("/confirm-password-change", response_model=LawyerLoginResponse)
async def confirm_password_change(
    current: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """
    Called by the lawyer portal after the lawyer has successfully changed their
    password in Firebase. Clears the must_change_password flag on the profile.
    """
    user, profile = current
    profile = await lawyer_service.confirm_password_change(db, profile)
    return LawyerLoginResponse.model_validate({"user": user, "profile": profile})


@router.delete("/account", status_code=status.HTTP_204_NO_CONTENT)
async def delete_lawyer_account(
    current: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """
    Permanently delete the authenticated lawyer and cascaded data (profile,
    appointments, messages, notifications, etc.). The client must delete the
    Firebase user after this call succeeds.
    """
    user, profile = current
    await ensure_lawyer_platform_user(db, user)
    await user_service.delete_lawyer_user(db, user, profile)
    invalidate_lawyers_directory_cache()
