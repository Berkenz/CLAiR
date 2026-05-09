import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import ARRAY, JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.database import Base

if TYPE_CHECKING:
    from app.models.appointment import Appointment


class LawyerProfile(Base):
    __tablename__ = "lawyer_profiles"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=func.gen_random_uuid(),
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )
    display_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    designation: Mapped[str | None] = mapped_column(String(255), nullable=True)
    practice_areas: Mapped[list[str] | None] = mapped_column(
        ARRAY(String), nullable=True
    )
    ibp_roll_number: Mapped[str | None] = mapped_column(String(64), nullable=True)
    year_admitted: Mapped[str | None] = mapped_column(String(8), nullable=True)
    ibp_chapter: Mapped[str | None] = mapped_column(String(255), nullable=True)
    ptr_number: Mapped[str | None] = mapped_column(String(128), nullable=True)
    mcle_compliance_number: Mapped[str | None] = mapped_column(String(128), nullable=True)
    law_school: Mapped[str | None] = mapped_column(String(255), nullable=True)
    firm_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    office_phone: Mapped[str | None] = mapped_column(String(64), nullable=True)
    mobile_phone: Mapped[str | None] = mapped_column(String(64), nullable=True)
    office_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    office_address: Mapped[str | None] = mapped_column(Text, nullable=True)
    bio: Mapped[str | None] = mapped_column(Text, nullable=True)
    office_hours: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    latitude: Mapped[float | None] = mapped_column(nullable=True)
    longitude: Mapped[float | None] = mapped_column(nullable=True)
    must_change_password: Mapped[bool] = mapped_column(
        Boolean, default=True, nullable=False, server_default="true"
    )
    is_profile_complete: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False, server_default="false"
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    user: Mapped["User"] = relationship("User", back_populates="lawyer_profile")  # type: ignore[name-defined]
    appointments: Mapped[list["Appointment"]] = relationship(
        "Appointment", back_populates="lawyer_profile"
    )
