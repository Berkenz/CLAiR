import logging

from fastapi import APIRouter, HTTPException

from app.schemas.chat import ChatRequest, ChatResponse
from app.services.chat_service import get_chat_response

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/chat", tags=["chat"])


@router.post("/send", response_model=ChatResponse)
async def send_message(body: ChatRequest):
    try:
        history = [{"role": m.role, "text": m.text} for m in body.history]
        reply = await get_chat_response(message=body.message, history=history)
        return ChatResponse(reply=reply)
    except Exception as e:
        logger.exception("Chat error")
        error_msg = str(e)
        if "429" in error_msg or "quota" in error_msg.lower():
            raise HTTPException(
                status_code=429,
                detail="CLAiR is receiving too many requests right now. Please try again in a moment.",
            )
        raise HTTPException(status_code=500, detail="Failed to get a response. Please try again.")
