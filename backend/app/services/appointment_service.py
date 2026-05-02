import uuid
from datetime import date

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.appointment import Appointment
from app.models.lawyer_profile import LawyerProfile
from app.models.user import User
from app.schemas.appointment import (
    AppointmentBookRequest,
    AppointmentCreateRequest,
    AppointmentUpdateRequest,
)


class AppointmentService:
    async def book_appointment(
        self,
        db: AsyncSession,
        client_user: User,
        data: AppointmentBookRequest,
    ) -> Appointment:
        """Mobile user books an appointment with a lawyer."""
        client_name = client_user.full_name or client_user.email or "Unknown Client"

        appt = Appointment(
            lawyer_profile_id=data.lawyer_profile_id,
            client_user_id=client_user.id,
            client_name=client_name,
            appointment_date=data.appointment_date,
            appointment_time=data.appointment_time,
            appointment_type=data.appointment_type,
            description=data.description,
            status="pending",
        )
        db.add(appt)
        await db.flush()
        await db.refresh(appt)
        return appt

    async def get_lawyer_appointments(
        self,
        db: AsyncSession,
        lawyer_profile_id: uuid.UUID,
        filter_date: date | None = None,
    ) -> list[Appointment]:
        """Return all appointments for a lawyer, optionally filtered by date."""
        query = select(Appointment).where(
            Appointment.lawyer_profile_id == lawyer_profile_id
        )
        if filter_date is not None:
            query = query.where(Appointment.appointment_date == filter_date)
        query = query.order_by(
            Appointment.appointment_date, Appointment.appointment_time
        )
        result = await db.execute(query)
        return list(result.scalars().all())

    async def get_appointment_by_id(
        self, db: AsyncSession, appointment_id: uuid.UUID
    ) -> Appointment | None:
        result = await db.execute(
            select(Appointment).where(Appointment.id == appointment_id)
        )
        return result.scalar_one_or_none()

    async def create_appointment_for_lawyer(
        self,
        db: AsyncSession,
        lawyer_profile_id: uuid.UUID,
        data: AppointmentCreateRequest,
    ) -> Appointment:
        """Lawyer creates an appointment directly from the web portal."""
        appt = Appointment(
            lawyer_profile_id=lawyer_profile_id,
            client_user_id=None,
            client_name=data.client_name,
            appointment_date=data.appointment_date,
            appointment_time=data.appointment_time,
            appointment_type=data.appointment_type,
            description=data.description,
            status="confirmed",
        )
        db.add(appt)
        await db.flush()
        await db.refresh(appt)
        return appt

    async def update_appointment(
        self,
        db: AsyncSession,
        appt: Appointment,
        data: AppointmentUpdateRequest,
    ) -> Appointment:
        if data.client_name is not None:
            appt.client_name = data.client_name
        if data.appointment_date is not None:
            appt.appointment_date = data.appointment_date
        if data.appointment_time is not None:
            appt.appointment_time = data.appointment_time
        if data.appointment_type is not None:
            appt.appointment_type = data.appointment_type
        if data.description is not None:
            appt.description = data.description
        if data.status is not None:
            appt.status = data.status
        await db.flush()
        await db.refresh(appt)
        return appt

    async def accept_appointment(
        self, db: AsyncSession, appt: Appointment
    ) -> Appointment:
        appt.status = "confirmed"
        appt.rejection_reason = None
        await db.flush()
        await db.refresh(appt)
        return appt

    async def reject_appointment(
        self, db: AsyncSession, appt: Appointment, reason: str
    ) -> Appointment:
        appt.status = "cancelled"
        appt.rejection_reason = reason
        await db.flush()
        await db.refresh(appt)
        return appt

    async def delete_appointment(
        self, db: AsyncSession, appt: Appointment
    ) -> None:
        await db.delete(appt)
        await db.flush()


appointment_service = AppointmentService()
