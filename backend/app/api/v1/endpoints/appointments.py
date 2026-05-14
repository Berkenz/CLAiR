"""
Appointment endpoints:
  - POST   /appointments            → mobile user books an appointment
  - GET    /lawyer/appointments     → lawyer sees their own appointments
  - POST   /lawyer/appointments     → lawyer manually creates an appointment
  - PUT    /lawyer/appointments/{id}→ lawyer edits an appointment
  - DELETE /lawyer/appointments/{id}→ lawyer deletes an appointment
"""

import logging
import uuid
from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from fastapi.responses import Response
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_current_user, get_db
from app.core.lawyer_security import get_current_lawyer
from app.models.appointment import Appointment
from app.models.conversation import Conversation
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
from app.services.pdf_service import generate_consultation_pdf
from app.services.storage_service import (
    delete_storage_object,
    download_storage_object,
    upload_consultation_summary_pdf,
)

logger = logging.getLogger(__name__)

# ── Mobile-user router (prefix /appointments) ──────────────────────────────
mobile_router = APIRouter(prefix="/appointments", tags=["appointments"])


@mobile_router.post("", response_model=AppointmentResponse, status_code=status.HTTP_201_CREATED)
async def book_appointment(
    lawyer_profile_id: Annotated[uuid.UUID, Form()],
    appointment_date: Annotated[date, Form()],
    appointment_time: Annotated[str, Form()],
    appointment_type: Annotated[str, Form()],
    case_title: Annotated[str | None, Form()] = None,
    description: Annotated[str | None, Form()] = None,
    attached_conversation_id: Annotated[str | None, Form()] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    files: Annotated[list[UploadFile] | None, File()] = None,
):
    """Mobile client books an appointment (multipart: form fields + optional file uploads)."""
    conv_uuid: uuid.UUID | None = None
    if attached_conversation_id and str(attached_conversation_id).strip():
        try:
            conv_uuid = uuid.UUID(str(attached_conversation_id).strip())
        except ValueError as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid attached_conversation_id",
            ) from e

    body = AppointmentBookRequest(
        lawyer_profile_id=lawyer_profile_id,
        appointment_date=appointment_date,
        appointment_time=appointment_time,
        appointment_type=appointment_type,
        case_title=case_title,
        description=description,
        attached_conversation_id=conv_uuid,
    )

    appt = await appointment_service.book_appointment(db, current_user, body)

    uploaded: list[dict] = []
    file_list = files or []
    for uf in file_list:
        raw = await uf.read()
        if not raw:
            continue
        fn = uf.filename or "attachment"
        ct = (uf.content_type or "application/octet-stream").split(";")[0].strip()
        try:
            from app.services.storage_service import upload_appointment_attachment

            url = upload_appointment_attachment(
                client_user_id=str(current_user.id),
                appointment_id=str(appt.id),
                filename=fn,
                content=raw,
                content_type=ct,
            )
            uploaded.append({"filename": fn, "url": url, "content_type": ct})
        except ValueError as e:
            logger.warning("Appointment attachment upload skipped: %s", e)
            uploaded.append({"filename": fn, "url": None, "content_type": ct})

    if uploaded:
        base = list(appt.attachments) if appt.attachments else []
        appt.attachments = base + uploaded
        await db.flush()
        await db.refresh(appt)

    await appointment_service._persist_legacy_split_if_needed(db, appt)
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
    await appointment_service._persist_legacy_split_if_needed(db, appt)
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


@lawyer_router.get("/{appointment_id}/pdf")
async def download_appointment_pdf(
    appointment_id: uuid.UUID,
    current: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """
    Return the CLAiR consultation PDF for an appointment.

    The PDF is generated once (AI summary + layout), stored in Supabase Storage, and
    reused on later requests so content stays stable. If storage is unavailable,
    the PDF is regenerated on every request (non-deterministic LLM output).
    """
    _, profile = current

    appt = await appointment_service.get_appointment_by_id(db, appointment_id)
    if not appt or appt.lawyer_profile_id != profile.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Appointment not found")

    await appointment_service._persist_legacy_split_if_needed(db, appt)

    if not appt.attached_conversation_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No CLAiR conversation was attached to this appointment.",
        )

    pdf_bytes: bytes | None = None
    cached_path = appt.consultation_summary_pdf_path
    if cached_path:
        try:
            pdf_bytes = download_storage_object(cached_path)
        except Exception:
            logger.warning(
                "Cached consultation PDF missing or unreadable; will regenerate (path=%s)",
                cached_path,
                exc_info=True,
            )
            pdf_bytes = None

    conv: Conversation | None = None
    client_user: User | None = None

    if pdf_bytes is None:
        conv_result = await db.execute(
            select(Conversation)
            .where(Conversation.id == appt.attached_conversation_id)
            .options(selectinload(Conversation.messages))
        )
        conv = conv_result.scalar_one_or_none()
        if not conv or not conv.messages:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Attached conversation not found or is empty.",
            )

        client_result = await db.execute(
            select(User).where(User.id == appt.client_user_id)
        )
        client_user = client_result.scalar_one_or_none()
        if not client_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Client user not found.",
            )

        try:
            pdf_bytes = await generate_consultation_pdf(client_user, conv)
        except Exception:
            logger.exception("Appointment PDF generation failed")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to generate PDF. Please try again.",
            ) from None

        try:
            path = upload_consultation_summary_pdf(
                appointment_id=str(appt.id), content=pdf_bytes
            )
            appt.consultation_summary_pdf_path = path
            await db.flush()
        except ValueError as e:
            logger.info("Consultation PDF not cached (storage unavailable): %s", e)

    safe_title = "Consultation"
    if conv is not None:
        safe_title = "".join(
            c if c.isalnum() or c in " -_" else "_" for c in conv.title
        ).strip()[:60] or safe_title
    elif appt.attached_conversation_id:
        title_row = await db.execute(
            select(Conversation.title).where(Conversation.id == appt.attached_conversation_id)
        )
        conv_title = title_row.scalar_one_or_none()
        if conv_title:
            safe_title = "".join(
                c if c.isalnum() or c in " -_" else "_" for c in conv_title
            ).strip()[:60] or safe_title

    assert pdf_bytes is not None
    filename = f"CLAiR_Consultation_{appt.client_name.replace(' ', '_')}_{safe_title}.pdf"

    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


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
