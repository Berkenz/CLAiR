"""Separate client (mobile) and lawyer (web portal) accounts."""

from __future__ import annotations

import uuid

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.services.lawyer_service import lawyer_service

LAWYER_ON_MOBILE_DETAIL = (
    "This email is registered for the CLAiR lawyer portal. "
    "Use the lawyer web app to sign in, or create a new client account with a different email here."
)

CLIENT_ON_LAWYER_PORTAL_DETAIL = (
    "This email is registered on the CLAiR mobile app. "
    "Lawyer portal access requires separate credentials from your administrator."
)

EMAIL_USED_BY_LAWYER_DETAIL = (
    "This email is already registered for the lawyer portal. "
    "Please use a different email to create a client account."
)

EMAIL_USED_BY_CLIENT_DETAIL = (
    "This email is already registered on the mobile app. "
    "Contact your administrator for lawyer portal credentials."
)


async def user_has_lawyer_profile(db: AsyncSession, user_id: uuid.UUID) -> bool:
    profile = await lawyer_service.get_profile_by_user_id(db, user_id)
    return profile is not None


async def ensure_client_platform_user(db: AsyncSession, user: User) -> None:
    """Reject mobile/client auth when the account is a lawyer."""
    if await user_has_lawyer_profile(db, user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=LAWYER_ON_MOBILE_DETAIL,
        )


async def ensure_lawyer_platform_user(db: AsyncSession, user: User) -> None:
    """Reject lawyer portal auth when the account is client-only (no lawyer profile)."""
    if not await user_has_lawyer_profile(db, user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=CLIENT_ON_LAWYER_PORTAL_DETAIL,
        )


async def ensure_email_available_for_client(
    db: AsyncSession, email: str
) -> None:
    """Reject client registration when email belongs to an existing lawyer account."""
    from app.services.user_service import user_service

    existing = await user_service.get_user_by_email(db, email)
    if existing and await user_has_lawyer_profile(db, existing.id):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=EMAIL_USED_BY_LAWYER_DETAIL,
        )
