import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.schemas.user import UserUpdate


class UserService:
    async def get_or_create_user(
        self,
        db: AsyncSession,
        firebase_uid: str,
        email: str,
        display_name: str | None = None,
        photo_url: str | None = None,
    ) -> User:
        """Get existing user by firebase_uid or create a new one."""
        user = await self.get_user_by_firebase_uid(db, firebase_uid)
        if user:
            return user

        user = User(
            firebase_uid=firebase_uid,
            email=email,
            display_name=display_name,
            photo_url=photo_url,
        )
        db.add(user)
        await db.flush()
        await db.refresh(user)
        return user

    async def get_user_by_firebase_uid(
        self, db: AsyncSession, firebase_uid: str
    ) -> User | None:
        """Get user by Firebase UID."""
        result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
        return result.scalar_one_or_none()

    async def update_user(
        self, db: AsyncSession, user_id: uuid.UUID, update_data: UserUpdate
    ) -> User:
        """Update user profile."""
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


user_service = UserService()
