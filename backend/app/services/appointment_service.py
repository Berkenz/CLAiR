import uuid
from datetime import date, datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.appointment import Appointment
from app.models.conversation import Conversation
from app.models.lawyer_profile import LawyerProfile
from app.models.user import User
from app.schemas.appointment import (
    CLIENT_APPOINTMENT_CANCEL_REASONS,
    CLIENT_CANCEL_REASON_STORAGE_PREFIX,
    AppointmentBookRequest,
    AppointmentCreateRequest,
    AppointmentClientCancelRequest,
    AppointmentUpdateRequest,
)
from app.services.appointment_legacy import migrate_legacy_appointment_if_needed
from app.services.storage_service import delete_storage_object


class AppointmentService:
    async def reload_appointment_for_response(
        self, db: AsyncSession, appointment_id: uuid.UUID
    ) -> Appointment:
        """Reload row with lawyer_profile eager-loaded (required for AppointmentResponse serialization)."""
        result = await db.execute(
            select(Appointment)
            .where(Appointment.id == appointment_id)
            .options(
                selectinload(Appointment.lawyer_profile).selectinload(LawyerProfile.user),
                selectinload(Appointment.client_user),
            )
        )
        return result.scalar_one()

    async def _persist_legacy_split_if_needed(
        self, db: AsyncSession, appt: Appointment | None
    ) -> None:
        if appt is None:
            return
        if migrate_legacy_appointment_if_needed(appt):
            await db.flush()
            await db.refresh(appt)

    async def book_appointment(
        self,
        db: AsyncSession,
        client_user: User,
        data: AppointmentBookRequest,
    ) -> Appointment:
        """Mobile user books an appointment with a lawyer."""
        client_name = client_user.full_name or client_user.email or "Unknown Client"

        attached_id = data.attached_conversation_id
        if attached_id is not None:
            conv_row = await db.execute(
                select(Conversation).where(
                    Conversation.id == attached_id,
                    Conversation.user_id == client_user.id,
                )
            )
            if conv_row.scalar_one_or_none() is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid conversation or you do not own this conversation.",
                )

        title = (data.case_title or "").strip() or "Consultation request"

        appt = Appointment(
            lawyer_profile_id=data.lawyer_profile_id,
            client_user_id=client_user.id,
            client_name=client_name,
            appointment_date=data.appointment_date,
            appointment_time=data.appointment_time,
            appointment_type=data.appointment_type,
            case_title=title[:500],
            description=data.description,
            attachments=[],
            attached_conversation_id=attached_id,
            status="pending",
        )
        db.add(appt)
        await db.flush()
        await db.refresh(appt)
        return await self.reload_appointment_for_response(db, appt.id)

    async def get_lawyer_appointments(
        self,
        db: AsyncSession,
        lawyer_profile_id: uuid.UUID,
        filter_date: date | None = None,
    ) -> list[Appointment]:
        """Return all appointments for a lawyer, optionally filtered by date."""
        query = (
            select(Appointment)
            .where(Appointment.lawyer_profile_id == lawyer_profile_id)
            .options(
                selectinload(Appointment.lawyer_profile).selectinload(LawyerProfile.user),
                selectinload(Appointment.client_user),
            )
        )
        if filter_date is not None:
            query = query.where(Appointment.appointment_date == filter_date)
        query = query.order_by(
            Appointment.appointment_date, Appointment.appointment_time
        )
        result = await db.execute(query)
        rows = list(result.scalars().all())
        for appt in rows:
            await self._persist_legacy_split_if_needed(db, appt)
        return rows

    async def get_client_appointments(
        self,
        db: AsyncSession,
        client_user_id: uuid.UUID,
        filter_date: date | None = None,
    ) -> list[Appointment]:
        """Return all appointments for a mobile client, optionally filtered by date."""
        query = (
            select(Appointment)
            .where(Appointment.client_user_id == client_user_id)
            .options(
                selectinload(Appointment.lawyer_profile).selectinload(LawyerProfile.user),
                selectinload(Appointment.client_user),
            )
        )
        if filter_date is not None:
            query = query.where(Appointment.appointment_date == filter_date)
        query = query.order_by(
            Appointment.appointment_date.desc(), Appointment.appointment_time.desc()
        )
        result = await db.execute(query)
        rows = list(result.scalars().all())
        for appt in rows:
            await self._persist_legacy_split_if_needed(db, appt)
        return rows

    async def get_appointment_by_id(
        self, db: AsyncSession, appointment_id: uuid.UUID
    ) -> Appointment | None:
        result = await db.execute(
            select(Appointment)
            .where(Appointment.id == appointment_id)
            .options(
                selectinload(Appointment.lawyer_profile).selectinload(LawyerProfile.user),
                selectinload(Appointment.client_user),
            )
        )
        return result.scalar_one_or_none()

    async def create_appointment_for_lawyer(
        self,
        db: AsyncSession,
        lawyer_profile_id: uuid.UUID,
        data: AppointmentCreateRequest,
    ) -> Appointment:
        """Lawyer creates an appointment directly from the web portal."""
        title = (data.case_title or "").strip() or "Consultation request"
        appt = Appointment(
            lawyer_profile_id=lawyer_profile_id,
            client_user_id=None,
            client_name=data.client_name,
            appointment_date=data.appointment_date,
            appointment_time=data.appointment_time,
            appointment_type=data.appointment_type,
            case_title=title[:500],
            description=data.description,
            attachments=[],
            status="confirmed",
        )
        db.add(appt)
        await db.flush()
        await db.refresh(appt)
        return await self.reload_appointment_for_response(db, appt.id)

    def _validate_lawyer_portal_status_change(self, appt: Appointment, new_status: str) -> None:
        """Allow resolve / reopen from portal; block other arbitrary status edits."""
        if new_status == appt.status:
            return
        if new_status == "resolved":
            if appt.status != "confirmed":
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Only an active (confirmed) case can be marked resolved.",
                )
            return
        if new_status == "confirmed" and appt.status == "resolved":
            return
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This status change is not supported. Use accept or reject for client requests.",
        )

    async def update_appointment(
        self,
        db: AsyncSession,
        appt: Appointment,
        data: AppointmentUpdateRequest,
    ) -> Appointment:
        # Resolved case: only allow reopen (status → confirmed), alone — app or manual.
        if appt.status == "resolved":
            dump = data.model_dump(exclude_unset=True)
            if not dump:
                return await self.reload_appointment_for_response(db, appt.id)
            if set(dump.keys()) != {"status"} or dump.get("status") != "confirmed":
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="This case is resolved. Reopen it (set status to confirmed) to make other changes.",
                )
            appt.status = "confirmed"
            appt.resolved_at = None
            await db.flush()
            await db.refresh(appt)
            return await self.reload_appointment_for_response(db, appt.id)

        if data.client_name is not None:
            appt.client_name = data.client_name
        if data.appointment_date is not None:
            appt.appointment_date = data.appointment_date
        if data.appointment_time is not None:
            appt.appointment_time = data.appointment_time
        if data.appointment_type is not None:
            appt.appointment_type = data.appointment_type
        if data.case_title is not None:
            t = data.case_title.strip()
            appt.case_title = t[:500] if t else None
        if data.description is not None:
            appt.description = data.description
        if data.lawyer_notes is not None:
            if appt.client_user_id is not None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Case notes are only stored for manually added cases.",
                )
            appt.lawyer_notes = data.lawyer_notes
        if data.status is not None and data.status != appt.status:
            self._validate_lawyer_portal_status_change(appt, data.status)
            appt.status = data.status
            if data.status == "resolved":
                appt.resolved_at = datetime.now(timezone.utc)
        await db.flush()
        await db.refresh(appt)
        return await self.reload_appointment_for_response(db, appt.id)

    async def add_manual_case_document(
        self,
        db: AsyncSession,
        appt: Appointment,
        *,
        filename: str,
        content: bytes,
        content_type: str,
    ) -> Appointment:
        """Append one attachment to a manual (lawyer-created) case."""
        if appt.client_user_id is not None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Case documents can only be uploaded for manually added cases.",
            )
        if appt.status != "confirmed":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Upload is only allowed while the case is active. Reopen the case to add files.",
            )
        from app.services.storage_service import upload_manual_case_document

        try:
            url = upload_manual_case_document(
                appointment_id=str(appt.id),
                filename=filename,
                content=content,
                content_type=content_type,
            )
        except ValueError as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(e),
            ) from e

        ct = (content_type or "application/octet-stream").split(";")[0].strip() or None
        fn = (filename or "attachment").strip() or "attachment"
        row = {"filename": fn, "url": url, "content_type": ct}
        base = list(appt.attachments) if appt.attachments else []
        appt.attachments = base + [row]
        await db.flush()
        await db.refresh(appt)
        return await self.reload_appointment_for_response(db, appt.id)

    async def accept_appointment(
        self, db: AsyncSession, appt: Appointment
    ) -> Appointment:
        appt.status = "confirmed"
        appt.rejection_reason = None
        await db.flush()
        await db.refresh(appt)
        await self._persist_legacy_split_if_needed(db, appt)
        return await self.reload_appointment_for_response(db, appt.id)

    async def reject_appointment(
        self, db: AsyncSession, appt: Appointment, reason: str
    ) -> Appointment:
        appt.status = "cancelled"
        appt.rejection_reason = reason
        await db.flush()
        await db.refresh(appt)
        await self._persist_legacy_split_if_needed(db, appt)
        return await self.reload_appointment_for_response(db, appt.id)

    def _format_client_cancellation_text(self, body: AppointmentClientCancelRequest) -> str:
        label = CLIENT_APPOINTMENT_CANCEL_REASONS[body.reason]
        prefix = CLIENT_CANCEL_REASON_STORAGE_PREFIX
        if body.reason == "other" and body.other_details:
            return f"{prefix} {label} — {body.other_details.strip()}"
        return f"{prefix} {label}"

    async def cancel_appointment_by_client(
        self,
        db: AsyncSession,
        client_user_id: uuid.UUID,
        appointment_id: uuid.UUID,
        body: AppointmentClientCancelRequest,
    ) -> Appointment:
        """Soft-cancel: status cancelled + reason visible to the lawyer."""
        appt = await self.get_appointment_by_id(db, appointment_id)
        if appt is None or appt.client_user_id != client_user_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Appointment not found",
            )
        if appt.status == "cancelled":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This appointment is already cancelled",
            )
        if appt.status not in ("pending", "confirmed"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This appointment cannot be cancelled",
            )
        appt.status = "cancelled"
        appt.rejection_reason = self._format_client_cancellation_text(body)
        await db.flush()
        await db.refresh(appt)
        await self._persist_legacy_split_if_needed(db, appt)
        return await self.reload_appointment_for_response(db, appt.id)

    async def delete_appointment(
        self, db: AsyncSession, appt: Appointment
    ) -> None:
        if appt.consultation_summary_pdf_path:
            delete_storage_object(appt.consultation_summary_pdf_path)
        await db.delete(appt)
        await db.flush()

    async def reorder_portal_appointments(
        self,
        db: AsyncSession,
        lawyer_profile_id: uuid.UUID,
        appointment_ids: list[uuid.UUID],
    ) -> None:
        """Assign portal_list_order 0..n-1 to the given appointments (same lawyer, same status)."""
        if not appointment_ids:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="appointment_ids must not be empty",
            )
        seen: set[uuid.UUID] = set()
        ordered_unique: list[uuid.UUID] = []
        for aid in appointment_ids:
            if aid in seen:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Duplicate appointment id in reorder list",
                )
            seen.add(aid)
            ordered_unique.append(aid)

        result = await db.execute(
            select(Appointment).where(
                Appointment.lawyer_profile_id == lawyer_profile_id,
                Appointment.id.in_(ordered_unique),
            )
        )
        rows = list(result.scalars().all())
        if len(rows) != len(ordered_unique):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="One or more appointments were not found",
            )
        by_id = {r.id: r for r in rows}
        statuses = {by_id[i].status for i in ordered_unique}
        if len(statuses) != 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="All reordered cases must share the same status",
            )
        for i, aid in enumerate(ordered_unique):
            by_id[aid].portal_list_order = i
        await db.flush()


appointment_service = AppointmentService()
