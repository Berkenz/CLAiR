import uuid
from datetime import date, datetime
from typing import TYPE_CHECKING

from sqlalchemy import Date, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.database import Base

if TYPE_CHECKING:
    from app.models.conversation import Conversation
    from app.models.direct_message import DirectMessage
    from app.models.lawyer_profile import LawyerProfile
    from app.models.user import User


class Appointment(Base):
    __tablename__ = "appointments"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=func.gen_random_uuid(),
    )
    lawyer_profile_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("lawyer_profiles.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    # Null when created by the lawyer directly from the web portal
    client_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    # Always present — pre-filled from the user record for mobile bookings,
    # or manually entered when the lawyer creates the appointment from the web.
    client_name: Mapped[str] = mapped_column(String(255), nullable=False)
    appointment_date: Mapped[date] = mapped_column(Date, nullable=False)
    appointment_time: Mapped[str] = mapped_column(String(5), nullable=False)  # "HH:MM"
    appointment_type: Mapped[str] = mapped_column(String(100), nullable=False)
    # Client-chosen title; lawyer may rename (case name in portal).
    case_title: Mapped[str | None] = mapped_column(String(500), nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    # Internal notes for lawyer-created (manual) cases; not used for mobile-linked bookings.
    lawyer_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    # [{ "filename": str, "url": str | null, "content_type": str | null }, ...]
    attachments: Mapped[list | None] = mapped_column(JSONB, nullable=True)
    # "pending" (booked by client), "confirmed", "cancelled", "resolved" (manual case closed)
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="pending", server_default="pending"
    )
    rejection_reason: Mapped[str | None] = mapped_column(Text, nullable=True)
    attached_conversation_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("conversations.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    # Supabase Storage path (bucket appointment-attachments) for cached AI PDF; set on first successful generation.
    consultation_summary_pdf_path: Mapped[str | None] = mapped_column(
        String(512), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    # When status became "resolved"; cleared on reopen. Used for post-resolve messaging window.
    resolved_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    # Lawyer portal: order within a status bucket (pending / confirmed / …). Lower = higher in list.
    portal_list_order: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default="0"
    )

    lawyer_profile: Mapped["LawyerProfile"] = relationship(
        "LawyerProfile", back_populates="appointments"
    )
    client_user: Mapped["User | None"] = relationship(
        "User", back_populates="appointments"
    )
    attached_conversation: Mapped["Conversation | None"] = relationship(
        "Conversation",
        foreign_keys=[attached_conversation_id],
    )
    direct_messages: Mapped[list["DirectMessage"]] = relationship(
        "DirectMessage",
        back_populates="appointment",
        cascade="all, delete-orphan",
        order_by="DirectMessage.created_at",
    )

    @property
    def lawyer_display_name(self) -> str | None:
        profile = self.lawyer_profile
        if profile is None:
            return None
        if profile.display_name and profile.display_name.strip():
            return profile.display_name.strip()
        return None

    @property
    def lawyer_photo_url(self) -> str | None:
        profile = self.lawyer_profile
        if profile is None:
            return None
        user = getattr(profile, "user", None)
        if user is None:
            return None
        url = (user.photo_url or "").strip()
        return url or None

    @property
    def client_photo_url(self) -> str | None:
        user = self.client_user
        if user is None:
            return None
        url = (user.photo_url or "").strip()
        return url or None
