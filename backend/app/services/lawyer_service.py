import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.lawyer_profile import LawyerProfile
from app.models.user import User
from app.schemas.lawyer import LawyerProfileUpdate


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
        Marks is_profile_complete=True when all required fields are populated.
        """
        user.first_name = data.first_name
        user.last_name = data.last_name

        profile.display_name = data.display_name
        profile.designation = data.designation
        profile.practice_areas = data.practice_areas

        profile.is_profile_complete = bool(
            data.first_name.strip()
            and data.last_name.strip()
            and data.display_name.strip()
            and data.designation.strip()
            and data.practice_areas
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


lawyer_service = LawyerService()
