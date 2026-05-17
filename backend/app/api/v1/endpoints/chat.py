import logging
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.chat import ChatRequest, ChatResponse, RagSourceItem, SuggestedLawyer, TavilySourceItem
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
        reply, nearby, rag_sources_raw, rag_enabled, tavily_raw = await get_chat_response(
            message=body.message,
            history=history,
            db=db,
            user_lat=body.user_lat,
            user_lng=body.user_lng,
            locale=body.locale,
        )
        rag_sources = [RagSourceItem(**r) for r in rag_sources_raw]
        tavily_sources = [
            TavilySourceItem(
                title=t.get("title", ""),
                url=t.get("url", ""),
                score=t.get("score", 0.0),
            )
            for t in tavily_raw
        ]
        suggested_lawyers = [
            SuggestedLawyer(
                id=str(l["id"]),
                display_name=l.get("display_name"),
                designation=l.get("designation"),
                practice_areas=l.get("practice_areas") or [],
                first_name=l.get("first_name"),
                last_name=l.get("last_name"),
                photo_url=l.get("photo_url"),
                bio=l.get("bio"),
                office_address=l.get("office_address"),
                office_hours=l.get("office_hours"),
                office_phone=l.get("office_phone"),
                mobile_phone=l.get("mobile_phone"),
                office_email=l.get("office_email"),
                latitude=l.get("latitude"),
                longitude=l.get("longitude"),
            )
            for l in nearby
        ]

        user_msg = await conversation_service.add_message(
            db, conversation_id=conv.id, role="user", text=body.message
        )
        assistant_msg = await conversation_service.add_message(
            db, conversation_id=conv.id, role="model", text=reply
        )

        conversation_title = conv.title
        if is_new_conversation:
            stripped = body.message.strip()
            if len(stripped) <= MAX_FALLBACK_TITLE_LENGTH:
                fallback = stripped
            else:
                fallback = f"{stripped[:197]}..."
            conversation_title = await generate_conversation_title(
                body.message,
                reply,
                fallback_title=fallback,
                locale=body.locale,
            )
            await conversation_service.update_conversation_title(
                db, conv.id, conversation_title
            )

        await conversation_service.touch_conversation(db, conv.id)

        return ChatResponse(
            reply=reply,
            conversation_id=conv.id,
            conversation_title=conversation_title,
            user_message_id=user_msg.id,
            assistant_message_id=assistant_msg.id,
            suggested_lawyers=suggested_lawyers,
            rag_enabled=rag_enabled,
            rag_sources=rag_sources,
            tavily_sources=tavily_sources,
        )

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
