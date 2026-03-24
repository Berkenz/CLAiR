import uuid

from sqlalchemy import select, func as sa_func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.conversation import Conversation, Message


class ConversationService:
    async def create_conversation(
        self,
        db: AsyncSession,
        *,
        user_id: uuid.UUID,
        title: str,
    ) -> Conversation:
        conversation = Conversation(user_id=user_id, title=title)
        db.add(conversation)
        await db.flush()
        await db.refresh(conversation)
        return conversation

    async def add_message(
        self,
        db: AsyncSession,
        *,
        conversation_id: uuid.UUID,
        role: str,
        text: str,
    ) -> Message:
        message = Message(conversation_id=conversation_id, role=role, text=text)
        db.add(message)
        await db.flush()
        return message

    async def update_conversation_title(
        self,
        db: AsyncSession,
        conversation_id: uuid.UUID,
        title: str,
    ) -> None:
        result = await db.execute(
            select(Conversation).where(Conversation.id == conversation_id)
        )
        conv = result.scalar_one_or_none()
        if conv:
            conv.title = title[:200]
            await db.flush()

    async def touch_conversation(
        self, db: AsyncSession, conversation_id: uuid.UUID
    ) -> None:
        result = await db.execute(
            select(Conversation).where(Conversation.id == conversation_id)
        )
        conv = result.scalar_one_or_none()
        if conv:
            conv.updated_at = sa_func.now()
            await db.flush()

    async def list_conversations(
        self,
        db: AsyncSession,
        user_id: uuid.UUID,
    ) -> list[Conversation]:
        result = await db.execute(
            select(Conversation)
            .where(Conversation.user_id == user_id)
            .order_by(Conversation.updated_at.desc())
        )
        return list(result.scalars().all())

    async def get_conversation(
        self,
        db: AsyncSession,
        conversation_id: uuid.UUID,
        user_id: uuid.UUID,
    ) -> Conversation | None:
        result = await db.execute(
            select(Conversation)
            .where(
                Conversation.id == conversation_id,
                Conversation.user_id == user_id,
            )
            .options(selectinload(Conversation.messages))
        )
        return result.scalar_one_or_none()

    async def delete_conversation(
        self,
        db: AsyncSession,
        conversation_id: uuid.UUID,
        user_id: uuid.UUID,
    ) -> bool:
        result = await db.execute(
            select(Conversation).where(
                Conversation.id == conversation_id,
                Conversation.user_id == user_id,
            )
        )
        conv = result.scalar_one_or_none()
        if not conv:
            return False
        await db.delete(conv)
        await db.flush()
        return True


conversation_service = ConversationService()
