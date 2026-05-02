"""
Appointment endpoints:
  - POST   /appointments            → mobile user books an appointment
  - GET    /lawyer/appointments     → lawyer sees their own appointments
  - POST   /lawyer/appointments     → lawyer manually creates an appointment
  - PUT    /lawyer/appointments/{id}→ lawyer edits an appointment
  - DELETE /lawyer/appointments/{id}→ lawyer deletes an appointment
"""

import uuid
from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.core.lawyer_security import get_current_lawyer
from app.models.lawyer_profile import LawyerProfile
from app.models.user import User
from app.schemas.appointment import (
    APPOINTMENT_TYPES,
    AppointmentBookRequest,
    AppointmentCreateRequest,
    AppointmentListResponse,
    AppointmentRejectRequest,
    AppointmentResponse,
    AppointmentUpdateRequest,
)
from app.services.appointment_service import appointment_service

# ── Mobile-user router (prefix /appointments) ──────────────────────────────
mobile_router = APIRouter(prefix="/appointments", tags=["appointments"])


@mobile_router.post("", response_model=AppointmentResponse, status_code=status.HTTP_201_CREATED)
async def book_appointment(
    body: AppointmentBookRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Mobile client books an appointment with a lawyer."""
    appt = await appointment_service.book_appointment(db, current_user, body)
    return appt


@mobile_router.get("/types", response_model=list[str])
async def get_appointment_types(
    _: Annotated[User, Depends(get_current_user)],
):
    """Return the list of valid appointment types."""
    return APPOINTMENT_TYPES


# ── Lawyer-portal router (prefix /lawyer/appointments) ─────────────────────
lawyer_router = APIRouter(prefix="/lawyer/appointments", tags=["lawyer-appointments"])


@lawyer_router.get("", response_model=AppointmentListResponse)
async def list_appointments(
    current: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
    date: Annotated[date | None, Query(alias="date")] = None,
):
    """Return this lawyer's appointments, optionally filtered by date."""
    _, profile = current
    appts = await appointment_service.get_lawyer_appointments(db, profile.id, date)
    return AppointmentListResponse(appointments=appts)


@lawyer_router.post("", response_model=AppointmentResponse, status_code=status.HTTP_201_CREATED)
async def create_appointment(
    body: AppointmentCreateRequest,
    current: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Lawyer manually creates an appointment from the web portal."""
    _, profile = current
    appt = await appointment_service.create_appointment_for_lawyer(db, profile.id, body)
    return appt


@lawyer_router.put("/{appointment_id}", response_model=AppointmentResponse)
async def update_appointment(
    appointment_id: uuid.UUID,
    body: AppointmentUpdateRequest,
    current: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Lawyer edits an appointment."""
    _, profile = current
    appt = await appointment_service.get_appointment_by_id(db, appointment_id)
    if not appt or appt.lawyer_profile_id != profile.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Appointment not found")
    updated = await appointment_service.update_appointment(db, appt, body)
    return updated


@lawyer_router.post("/{appointment_id}/accept", response_model=AppointmentResponse)
async def accept_appointment(
    appointment_id: uuid.UUID,
    current: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Lawyer accepts a pending appointment request."""
    _, profile = current
    appt = await appointment_service.get_appointment_by_id(db, appointment_id)
    if not appt or appt.lawyer_profile_id != profile.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Appointment not found")
    if appt.status != "pending":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Only pending appointments can be accepted")
    return await appointment_service.accept_appointment(db, appt)


@lawyer_router.post("/{appointment_id}/reject", response_model=AppointmentResponse)
async def reject_appointment(
    appointment_id: uuid.UUID,
    body: AppointmentRejectRequest,
    current: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Lawyer rejects a pending appointment request with a reason."""
    _, profile = current
    appt = await appointment_service.get_appointment_by_id(db, appointment_id)
    if not appt or appt.lawyer_profile_id != profile.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Appointment not found")
    if appt.status != "pending":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Only pending appointments can be rejected")
    return await appointment_service.reject_appointment(db, appt, body.reason)


@lawyer_router.delete("/{appointment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_appointment(
    appointment_id: uuid.UUID,
    current: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Lawyer deletes an appointment."""
    _, profile = current
    appt = await appointment_service.get_appointment_by_id(db, appointment_id)
    if not appt or appt.lawyer_profile_id != profile.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Appointment not found")
    await appointment_service.delete_appointment(db, appt)
