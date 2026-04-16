from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.core.lawyer_security import get_current_lawyer
from app.models.lawyer_profile import LawyerProfile
from app.models.user import User
from app.schemas.lawyer import (
    DESIGNATIONS,
    PRACTICE_AREAS,
    LawyerLoginResponse,
    LawyerProfileUpdate,
    OptionsResponse,
)
from app.services.lawyer_service import lawyer_service

router = APIRouter(prefix="/lawyer", tags=["lawyer-profile"])


@router.get("/options", response_model=OptionsResponse)
async def get_options():
    """Return the predefined lists for practice areas and designations."""
    return OptionsResponse(practice_areas=PRACTICE_AREAS, designations=DESIGNATIONS)


@router.get("/profile", response_model=LawyerLoginResponse)
async def get_profile(
    current: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
):
    """Return the authenticated lawyer's user info and profile."""
    user, profile = current
    return LawyerLoginResponse.model_validate({"user": user, "profile": profile})


@router.put("/profile", response_model=LawyerLoginResponse)
async def update_profile(
    body: LawyerProfileUpdate,
    current: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """
    Save (or update) the lawyer's profile.

    Required on first login after the password has been changed.
    Sets is_profile_complete=True when all required fields are present.
    Custom designations / practice areas are accepted alongside the
    predefined values.
    """
    user, profile = current

    if profile.must_change_password:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must change your password before completing your profile.",
        )

    user, profile = await lawyer_service.update_profile(db, user, profile, body)
    return LawyerLoginResponse.model_validate({"user": user, "profile": profile})
