import logging
from typing import Annotated
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.conversation import (
    AppointmentSummaryResponse,
    ConversationDetail,
    ConversationListResponse,
    ConversationSummary,
    ConversationUpdate,
    MessageResponse,
)
from app.services.conversation_service import conversation_service
from app.services.lawyer_ai_assessment_service import lawyer_ai_assessment_service
from app.services.pdf_service import (
    generate_appointment_description_summary,
    generate_consultation_pdf,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/conversations", tags=["conversations"])


@router.get("", response_model=ConversationListResponse)
async def list_conversations(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    conversations = await conversation_service.list_conversations(db, current_user.id)
    return ConversationListResponse(
        conversations=[
            ConversationSummary.model_validate(c) for c in conversations
        ]
    )


@router.get("/{conversation_id}", response_model=ConversationDetail)
async def get_conversation(
    conversation_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    conv = await conversation_service.get_conversation(
        db, conversation_id, current_user.id
    )
    if not conv:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found",
        )

    reported_ids = await lawyer_ai_assessment_service.get_reported_message_ids_for_conversation(
        db, conv.id
    )
    ordered_messages = sorted(conv.messages, key=lambda m: m.created_at)
    return ConversationDetail(
        id=conv.id,
        title=conv.title,
        is_pinned=conv.is_pinned,
        created_at=conv.created_at,
        updated_at=conv.updated_at,
        messages=[
            MessageResponse(
                id=m.id,
                role=m.role,
                text=m.text,
                created_at=m.created_at,
                lawyer_reported=m.id in reported_ids,
            )
            for m in ordered_messages
        ],
    )


@router.patch("/{conversation_id}", response_model=ConversationSummary)
async def update_conversation(
    conversation_id: uuid.UUID,
    body: ConversationUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    conv = await conversation_service.update_conversation(
        db,
        conversation_id,
        current_user.id,
        title=body.title,
        is_pinned=body.is_pinned,
    )
    if not conv:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found",
        )
    return ConversationSummary.model_validate(conv)


@router.get("/{conversation_id}/pdf")
async def generate_pdf(
    conversation_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    if current_user.is_anonymous:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="PDF generation is only available for registered users.",
        )

    conv = await conversation_service.get_conversation(
        db, conversation_id, current_user.id
    )
    if not conv:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found",
        )

    if not conv.messages:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot generate PDF for an empty conversation.",
        )

    try:
        pdf_bytes = await generate_consultation_pdf(current_user, conv)
    except Exception:
        logger.exception("PDF generation failed")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate PDF. Please try again.",
        )

    safe_title = "".join(
        c if c.isalnum() or c in " -_" else "_"
        for c in conv.title
    ).strip()[:60]
    filename = f"CLAiR_{safe_title}.pdf"

    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.post(
    "/{conversation_id}/appointment-summary",
    response_model=AppointmentSummaryResponse,
)
async def summarize_conversation_for_appointment(
    conversation_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Generate an AI summary of a saved CLAiR conversation for a lawyer booking description."""
    if current_user.is_anonymous:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sign in to use AI summarization.",
        )

    conv = await conversation_service.get_conversation(
        db, conversation_id, current_user.id
    )
    if not conv:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found",
        )
    if not conv.messages:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot summarize an empty conversation.",
        )

    try:
        summary = await generate_appointment_description_summary(conv.messages)
    except Exception:
        logger.exception("Appointment summary generation failed")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Could not generate a summary. Please try again.",
        )

    return AppointmentSummaryResponse(summary=summary)


@router.delete("/{conversation_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_conversation(
    conversation_id: uuid.UUID,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    deleted = await conversation_service.delete_conversation(
        db, conversation_id, current_user.id
    )
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found",
        )
