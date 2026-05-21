import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.lawyer_profile import LawyerProfile
from app.models.user import User
from app.schemas.user import UserUpdate


class UserService:
    async def create_user(
        self,
        db: AsyncSession,
        *,
        firebase_uid: str,
        email: str | None = None,
        first_name: str | None = None,
        last_name: str | None = None,
        photo_url: str | None = None,
        auth_provider: str = "email",
        is_email_verified: bool = False,
        is_anonymous: bool = False,
    ) -> User:
        user = User(
            firebase_uid=firebase_uid,
            email=email,
            first_name=first_name,
            last_name=last_name,
            photo_url=photo_url,
            auth_provider=auth_provider,
            is_email_verified=is_email_verified,
            is_anonymous=is_anonymous,
        )
        db.add(user)
        await db.flush()
        await db.refresh(user)
        return user

    async def get_user_by_firebase_uid(
        self, db: AsyncSession, firebase_uid: str
    ) -> User | None:
        result = await db.execute(
            select(User).where(User.firebase_uid == firebase_uid)
        )
        return result.scalar_one_or_none()

    async def get_user_by_email(
        self, db: AsyncSession, email: str
    ) -> User | None:
        result = await db.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()

    async def update_user(
        self, db: AsyncSession, user_id: uuid.UUID, update_data: UserUpdate
    ) -> User:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if user is None:
            raise ValueError("User not found")

        update_dict = update_data.model_dump(exclude_unset=True)
        for key, value in update_dict.items():
            setattr(user, key, value)

        await db.flush()
        await db.refresh(user)
        return user

    async def set_email_verified(self, db: AsyncSession, user: User) -> User:
        user.is_email_verified = True
        await db.flush()
        await db.refresh(user)
        return user

    async def get_user_by_id(
        self, db: AsyncSession, user_id: uuid.UUID
    ) -> User | None:
        result = await db.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    async def set_fcm_token(
        self, db: AsyncSession, user_id: uuid.UUID, token: str | None
    ) -> User | None:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if user is None:
            return None
        user.fcm_token = token
        await db.flush()
        await db.refresh(user)
        return user

    async def delete_user(self, db: AsyncSession, user: User) -> None:
        """
        Remove the user row. Related rows with ON DELETE CASCADE are removed too
        (conversations, messages, notifications, etc.).
        """
        await db.delete(user)
        await db.flush()

    async def delete_lawyer_user(
        self, db: AsyncSession, user: User, profile: LawyerProfile
    ) -> None:
        """
        Remove a lawyer account. Deletes the profile first so SQLAlchemy does not
        try to null out lawyer_profiles.user_id when the user row is removed.
        """
        await db.delete(profile)
        await db.flush()
        await db.delete(user)
        await db.flush()


user_service = UserService()
