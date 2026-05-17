import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.core.lawyer_security import get_current_lawyer
from app.models.lawyer_profile import LawyerProfile
from app.models.user import User
from app.schemas.lawyer_ai_assessment import (
    AssessmentFeedbackItemOut,
    AssessmentMessageOut,
    ClientConversationDetailOut,
    ClientConversationListOut,
    ClientConversationSummaryOut,
    ConversationFeedbackListOut,
    LawyerAiFeedbackCreate,
    LawyerAiFeedbackResponse,
    SharedBookingDetailOut,
    SharedBookingSummaryOut,
)
from app.services.lawyer_ai_assessment_service import (
    booking_description_preview,
    client_display_name_for_user,
    lawyer_ai_assessment_service,
)

router = APIRouter(prefix="/lawyer/ai-assessment", tags=["lawyer-ai-assessment"])


@router.get("/client-conversations", response_model=ClientConversationListOut)
async def list_client_conversations(
    current: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
):
    """Client CLAiR chats voluntarily attached while booking with this lawyer."""
    _, profile = current
    rows = await lawyer_ai_assessment_service.list_client_conversations(
        db, lawyer_profile_id=profile.id, limit=limit
    )
    return ClientConversationListOut(
        conversations=[
            ClientConversationSummaryOut(
                id=conv.id,
                title=conv.title,
                updated_at=conv.updated_at,
                client_display_name=client_display_name_for_user(owner),
                latest_shared_booking=SharedBookingSummaryOut(
                    appointment_id=appt.id,
                    shared_at=appt.created_at,
                    appointment_date=appt.appointment_date,
                    appointment_time=appt.appointment_time,
                    appointment_type=appt.appointment_type,
                    status=appt.status,
                ),
            )
            for conv, owner, appt in rows
        ]
    )


@router.get("/client-conversations/{conversation_id}", response_model=ClientConversationDetailOut)
async def get_client_conversation_detail(
    conversation_id: uuid.UUID,
    current: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    user, profile = current
    conv = await lawyer_ai_assessment_service.get_client_conversation(
        db, conversation_id, lawyer_profile_id=profile.id
    )
    if not conv:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found",
        )
    owner = await db.get(User, conv.user_id)
    display = client_display_name_for_user(owner) if owner else "Client"

    feedback_rows = await lawyer_ai_assessment_service.list_my_feedback_for_conversation(
        db, lawyer_user_id=user.id, conversation_id=conversation_id
    )

    shared_rows = (
        await lawyer_ai_assessment_service.list_shared_bookings_for_conversation(
            db,
            lawyer_profile_id=profile.id,
            conversation_id=conversation_id,
        )
    )

    messages = sorted(conv.messages, key=lambda m: m.created_at)
    return ClientConversationDetailOut(
        id=conv.id,
        title=conv.title,
        updated_at=conv.updated_at,
        client_display_name=display,
        messages=[AssessmentMessageOut.model_validate(m) for m in messages],
        my_feedback=[
            AssessmentFeedbackItemOut(
                message_id=f.message_id,
                feedback_type=f.feedback_type,
                issue_codes=list(f.issue_codes) if f.issue_codes else None,
                comment=f.comment,
            )
            for f in feedback_rows
        ],
        shared_bookings=[
            SharedBookingDetailOut(
                appointment_id=b.id,
                shared_at=b.created_at,
                appointment_date=b.appointment_date,
                appointment_time=b.appointment_time,
                appointment_type=b.appointment_type,
                status=b.status,
                description_preview=booking_description_preview(b.description),
            )
            for b in shared_rows
        ],
    )


@router.get(
    "/conversations/{conversation_id}/my-feedback",
    response_model=ConversationFeedbackListOut,
)
async def list_conversation_feedback(
    conversation_id: uuid.UUID,
    current: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Feedback the lawyer submitted on AI replies in a chat they own or a client shared."""
    user, profile = current
    allowed = await lawyer_ai_assessment_service.lawyer_can_assess_conversation(
        db,
        conversation_id=conversation_id,
        lawyer_user_id=user.id,
        lawyer_profile_id=profile.id,
    )
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found",
        )
    rows = await lawyer_ai_assessment_service.list_my_feedback_for_conversation(
        db, lawyer_user_id=user.id, conversation_id=conversation_id
    )
    return ConversationFeedbackListOut(
        feedback=[
            AssessmentFeedbackItemOut(
                message_id=f.message_id,
                feedback_type=f.feedback_type,
                issue_codes=list(f.issue_codes) if f.issue_codes else None,
                comment=f.comment,
            )
            for f in rows
        ]
    )


@router.post("/message-feedback", response_model=LawyerAiFeedbackResponse)
async def submit_message_feedback(
    body: LawyerAiFeedbackCreate,
    current: Annotated[tuple[User, LawyerProfile], Depends(get_current_lawyer)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    user, profile = current
    try:
        row = await lawyer_ai_assessment_service.upsert_feedback(
            db,
            lawyer_user_id=user.id,
            lawyer_profile_id=profile.id,
            body=body,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        ) from e
    return LawyerAiFeedbackResponse(
        message_id=row.message_id,
        feedback_type=row.feedback_type,
        issue_codes=list(row.issue_codes) if row.issue_codes else None,
        comment=row.comment,
    )
