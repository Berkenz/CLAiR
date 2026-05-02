import uuid
from datetime import date, datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.database import Base

if TYPE_CHECKING:
    from app.models.conversation import Conversation
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
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    # "pending" (booked by client), "confirmed", "cancelled"
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
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
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
