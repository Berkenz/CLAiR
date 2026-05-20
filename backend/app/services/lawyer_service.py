import time
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.config import settings
from app.models.lawyer_profile import LawyerProfile
from app.models.user import User
from app.schemas.lawyer import LawyerProfileUpdate
from app.utils.photo_url import photo_url_with_cache_bust

_lawyers_directory_cache: tuple[float, list[dict]] | None = None


def invalidate_lawyers_directory_cache() -> None:
    """Clear in-memory lawyer list cache (e.g. after a profile photo upload)."""
    global _lawyers_directory_cache
    _lawyers_directory_cache = None


class LawyerService:
    async def get_profile_by_user_id(
        self, db: AsyncSession, user_id: uuid.UUID
    ) -> LawyerProfile | None:
        result = await db.execute(
            select(LawyerProfile).where(LawyerProfile.user_id == user_id)
        )
        return result.scalar_one_or_none()

    async def get_or_create_profile(
        self, db: AsyncSession, user: User
    ) -> LawyerProfile:
        """
        Returns the existing LawyerProfile for the user, or creates a new one
        with must_change_password=True and is_profile_complete=False.
        Called on every lawyer login so first-timers get a profile automatically.
        """
        profile = await self.get_profile_by_user_id(db, user.id)
        if profile:
            return profile

        profile = LawyerProfile(user_id=user.id)
        db.add(profile)
        await db.flush()
        await db.refresh(profile)
        return profile

    async def confirm_password_change(
        self, db: AsyncSession, profile: LawyerProfile
    ) -> LawyerProfile:
        """Clear the must_change_password flag after the lawyer sets a new password."""
        profile.must_change_password = False
        await db.flush()
        await db.refresh(profile)
        return profile

    async def update_profile(
        self,
        db: AsyncSession,
        user: User,
        profile: LawyerProfile,
        data: LawyerProfileUpdate,
    ) -> tuple[User, LawyerProfile]:
        """
        Update user name fields and lawyer profile fields together.
        Marks is_profile_complete=True when all required wizard fields are present.
        """
        user.first_name = data.first_name
        user.middle_name = data.middle_name
        user.last_name = data.last_name
        user.name_suffix = data.name_suffix

        profile.display_name = data.display_name
        profile.designation = data.designation
        profile.practice_areas = data.practice_areas
        profile.ibp_roll_number = data.ibp_roll_number
        profile.year_admitted = data.year_admitted
        profile.ibp_chapter = data.ibp_chapter
        profile.ptr_number = data.ptr_number
        profile.mcle_compliance_number = data.mcle_compliance_number
        profile.law_school = data.law_school
        profile.firm_name = data.firm_name
        profile.office_phone = data.office_phone
        profile.mobile_phone = data.mobile_phone
        profile.office_email = data.office_email
        profile.office_address = data.office_address
        profile.bio = data.bio
        if data.office_hours is not None:
            profile.office_hours = data.office_hours
        profile.latitude = data.latitude
        profile.longitude = data.longitude

        def _filled(s: str | None) -> bool:
            return bool(s and str(s).strip())

        profile.is_profile_complete = bool(
            _filled(data.first_name)
            and _filled(data.last_name)
            and _filled(data.display_name)
            and _filled(data.designation)
            and bool(data.practice_areas)
            and _filled(data.ibp_roll_number)
            and _filled(data.year_admitted)
            and _filled(data.ibp_chapter)
        )

        await db.flush()
        await db.refresh(user)
        await db.refresh(profile)
        return user, profile

    async def get_user_with_profile(
        self, db: AsyncSession, firebase_uid: str
    ) -> User | None:
        result = await db.execute(
            select(User)
            .options(selectinload(User.lawyer_profile))
            .where(User.firebase_uid == firebase_uid)
        )
        return result.scalar_one_or_none()

    async def get_all_complete_lawyers(
        self, db: AsyncSession
    ) -> list[dict]:
        """Return all lawyers whose profiles are marked complete, for the mobile directory."""
        global _lawyers_directory_cache
        now = time.monotonic()
        if (
            _lawyers_directory_cache is not None
            and now - _lawyers_directory_cache[0]
            < settings.LAWYER_DIRECTORY_CACHE_TTL_SECONDS
        ):
            return _lawyers_directory_cache[1]

        result = await db.execute(
            select(LawyerProfile, User)
            .join(User, LawyerProfile.user_id == User.id)
            .where(LawyerProfile.is_profile_complete == True)  # noqa: E712
            .where(User.is_active == True)  # noqa: E712
            .order_by(LawyerProfile.created_at.desc())
        )
        rows = result.all()
        lawyers = [
            {
                "id": profile.id,
                "display_name": profile.display_name,
                "designation": profile.designation,
                "practice_areas": profile.practice_areas,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "photo_url": photo_url_with_cache_bust(user.photo_url, user.updated_at),
                "bio": profile.bio,
                "office_address": profile.office_address,
                "office_hours": profile.office_hours,
                "office_phone": profile.office_phone,
                "mobile_phone": profile.mobile_phone,
                "office_email": profile.office_email,
                "latitude": profile.latitude,
                "longitude": profile.longitude,
            }
            for profile, user in rows
        ]
        _lawyers_directory_cache = (now, lawyers)
        return lawyers


    async def get_profile_by_id(
        self, db: AsyncSession, profile_id: uuid.UUID
    ) -> LawyerProfile | None:
        result = await db.execute(
            select(LawyerProfile).where(LawyerProfile.id == profile_id)
        )
        return result.scalar_one_or_none()


lawyer_service = LawyerService()
