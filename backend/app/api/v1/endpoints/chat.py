import logging
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.chat import ChatRequest, ChatResponse
from app.services.chat_service import generate_conversation_title, get_chat_response
from app.services.conversation_service import conversation_service

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/chat", tags=["chat"])

# Match conversations.title column (200); used when AI title is rejected or fails
MAX_FALLBACK_TITLE_LENGTH = 200


@router.post("/send", response_model=ChatResponse)
async def send_message(
    body: ChatRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    try:
        is_new_conversation = body.conversation_id is None
        if body.conversation_id:
            conv = await conversation_service.get_conversation(
                db, body.conversation_id, current_user.id
            )
            if not conv:
                raise HTTPException(status_code=404, detail="Conversation not found")
        else:
            conv = await conversation_service.create_conversation(
                db,
                user_id=current_user.id,
                title="New conversation",
            )

        history = [{"role": m.role, "text": m.text} for m in body.history]
        reply = await get_chat_response(message=body.message, history=history)

        await conversation_service.add_message(
            db, conversation_id=conv.id, role="user", text=body.message
        )
        await conversation_service.add_message(
            db, conversation_id=conv.id, role="model", text=reply
        )

        if is_new_conversation:
            stripped = body.message.strip()
            if len(stripped) <= MAX_FALLBACK_TITLE_LENGTH:
                fallback = stripped
            else:
                fallback = f"{stripped[:197]}..."
            generated = await generate_conversation_title(
                body.message,
                reply,
                fallback_title=fallback,
            )
            await conversation_service.update_conversation_title(
                db, conv.id, generated
            )

        await conversation_service.touch_conversation(db, conv.id)

        return ChatResponse(reply=reply, conversation_id=conv.id)

    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Chat error")
        error_msg = str(e)
        if "429" in error_msg or "quota" in error_msg.lower():
            raise HTTPException(
                status_code=429,
                detail="CLAiR is receiving too many requests right now. Please try again in a moment.",
            )
        raise HTTPException(status_code=500, detail="Failed to get a response. Please try again.")
