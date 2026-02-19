import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

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


user_service = UserService()
