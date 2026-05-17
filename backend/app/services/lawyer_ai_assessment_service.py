import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.appointment import Appointment
from app.models.conversation import Conversation, Message
from app.models.lawyer_ai_message_feedback import LawyerAiMessageFeedback
from app.models.user import User
from app.schemas.lawyer_ai_assessment import LawyerAiFeedbackCreate


def booking_description_preview(description: str | None, max_len: int = 160) -> str | None:
    if not description or not description.strip():
        return None
    text = description.strip().replace("\r\n", "\n")
    first = text.split("\n")[0].strip()
    if len(first) > max_len:
        return first[: max_len - 1].rstrip() + "…"
    return first


def client_display_name_for_user(user: User) -> str:
    parts = [user.first_name or "", user.last_name or ""]
    name = " ".join(p.strip() for p in parts if p and p.strip()).strip()
    if name:
        return name
    if user.email:
        return user.email.split("@")[0]
    return "Anonymous client"


class LawyerAiAssessmentService:
    async def list_client_conversations(
        self,
        db: AsyncSession,
        *,
        lawyer_profile_id: uuid.UUID,
        limit: int = 50,
    ) -> list[tuple[Conversation, User, Appointment]]:
        """Conversations explicitly attached when booking with this lawyer."""
        ranked_appts = (
            select(
                Appointment.attached_conversation_id.label("cid"),
                Appointment.id.label("appointment_id"),
                Appointment.created_at.label("shared_at"),
                Appointment.appointment_date,
                Appointment.appointment_time,
                Appointment.appointment_type,
                Appointment.status,
                func.row_number()
                .over(
                    partition_by=Appointment.attached_conversation_id,
                    order_by=Appointment.created_at.desc(),
                )
                .label("rn"),
            )
            .where(
                Appointment.lawyer_profile_id == lawyer_profile_id,
                Appointment.attached_conversation_id.is_not(None),
            )
        ).subquery()

        filtered = select(ranked_appts).where(ranked_appts.c.rn == 1).subquery()

        stmt = (
            select(Conversation, User, Appointment)
            .join(filtered, filtered.c.cid == Conversation.id)
            .join(Appointment, Appointment.id == filtered.c.appointment_id)
            .join(User, User.id == Conversation.user_id)
            .order_by(filtered.c.shared_at.desc())
            .limit(min(limit, 100))
        )
        result = await db.execute(stmt)
        return list(result.all())

    async def get_client_conversation(
        self,
        db: AsyncSession,
        conversation_id: uuid.UUID,
        lawyer_profile_id: uuid.UUID,
    ) -> Conversation | None:
        stmt = (
            select(Conversation)
            .join(
                Appointment,
                Appointment.attached_conversation_id == Conversation.id,
            )
            .where(
                Conversation.id == conversation_id,
                Appointment.lawyer_profile_id == lawyer_profile_id,
            )
            .options(selectinload(Conversation.messages))
            .limit(1)
        )
        result = await db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_shared_bookings_for_conversation(
        self,
        db: AsyncSession,
        *,
        lawyer_profile_id: uuid.UUID,
        conversation_id: uuid.UUID,
    ) -> list[Appointment]:
        stmt = (
            select(Appointment)
            .where(
                Appointment.lawyer_profile_id == lawyer_profile_id,
                Appointment.attached_conversation_id == conversation_id,
            )
            .order_by(Appointment.created_at.desc())
        )
        result = await db.execute(stmt)
        return list(result.scalars().all())

    async def get_reported_message_ids_for_conversation(
        self,
        db: AsyncSession,
        conversation_id: uuid.UUID,
    ) -> set[uuid.UUID]:
        """Message IDs in this conversation that lawyers reported (client-visible flag)."""
        stmt = (
            select(LawyerAiMessageFeedback.message_id)
            .join(Message, LawyerAiMessageFeedback.message_id == Message.id)
            .where(
                Message.conversation_id == conversation_id,
                LawyerAiMessageFeedback.feedback_type == "report",
            )
        )
        result = await db.execute(stmt)
        return {row[0] for row in result.all()}

    async def list_my_feedback_for_conversation(
        self,
        db: AsyncSession,
        *,
        lawyer_user_id: uuid.UUID,
        conversation_id: uuid.UUID,
    ) -> list[LawyerAiMessageFeedback]:
        stmt = (
            select(LawyerAiMessageFeedback)
            .join(Message, LawyerAiMessageFeedback.message_id == Message.id)
            .where(
                LawyerAiMessageFeedback.lawyer_user_id == lawyer_user_id,
                Message.conversation_id == conversation_id,
            )
        )
        result = await db.execute(stmt)
        return list(result.scalars().all())

    async def lawyer_can_assess_conversation(
        self,
        db: AsyncSession,
        *,
        conversation_id: uuid.UUID,
        lawyer_user_id: uuid.UUID,
        lawyer_profile_id: uuid.UUID,
    ) -> bool:
        own = await db.execute(
            select(Conversation.id).where(
                Conversation.id == conversation_id,
                Conversation.user_id == lawyer_user_id,
            )
        )
        if own.scalar_one_or_none():
            return True
        client = await self.get_client_conversation(
            db, conversation_id, lawyer_profile_id=lawyer_profile_id
        )
        return client is not None

    async def get_verifiable_model_message(
        self,
        db: AsyncSession,
        message_id: uuid.UUID,
        lawyer_profile_id: uuid.UUID,
        lawyer_user_id: uuid.UUID,
    ) -> Message | None:
        client_stmt = (
            select(Message)
            .join(Conversation, Message.conversation_id == Conversation.id)
            .join(
                Appointment,
                Appointment.attached_conversation_id == Conversation.id,
            )
            .where(
                Message.id == message_id,
                Appointment.lawyer_profile_id == lawyer_profile_id,
                Message.role == "model",
            )
        )
        result = await db.execute(client_stmt)
        msg = result.scalar_one_or_none()
        if msg:
            return msg

        own_stmt = (
            select(Message)
            .join(Conversation, Message.conversation_id == Conversation.id)
            .where(
                Message.id == message_id,
                Conversation.user_id == lawyer_user_id,
                Message.role == "model",
            )
        )
        result = await db.execute(own_stmt)
        return result.scalar_one_or_none()

    async def upsert_feedback(
        self,
        db: AsyncSession,
        *,
        lawyer_user_id: uuid.UUID,
        lawyer_profile_id: uuid.UUID,
        body: LawyerAiFeedbackCreate,
    ) -> LawyerAiMessageFeedback:
        msg = await self.get_verifiable_model_message(
            db, body.message_id, lawyer_profile_id, lawyer_user_id
        )
        if not msg:
            raise ValueError("Message not found or not eligible for assessment")

        stmt = select(LawyerAiMessageFeedback).where(
            LawyerAiMessageFeedback.lawyer_user_id == lawyer_user_id,
            LawyerAiMessageFeedback.message_id == body.message_id,
        )
        result = await db.execute(stmt)
        existing = result.scalar_one_or_none()

        issue_codes = body.issue_codes if body.feedback_type == "report" else None
        comment = body.comment.strip() if body.comment else None

        if existing:
            existing.feedback_type = body.feedback_type
            existing.issue_codes = issue_codes
            existing.comment = comment
            await db.flush()
            await db.refresh(existing)
            return existing

        row = LawyerAiMessageFeedback(
            lawyer_user_id=lawyer_user_id,
            message_id=body.message_id,
            feedback_type=body.feedback_type,
            issue_codes=issue_codes,
            comment=comment,
        )
        db.add(row)
        await db.flush()
        await db.refresh(row)
        return row


lawyer_ai_assessment_service = LawyerAiAssessmentService()
