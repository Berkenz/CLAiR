import io
import logging
from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.chat import ChatRequest, ChatResponse, RagSourceItem, SuggestedLawyer, TavilySourceItem
from app.services.chat_service import get_chat_response
from app.services.chat_title_tasks import schedule_conversation_title
from app.services.llm_completion import AllProvidersRateLimitedError
from app.services.conversation_service import conversation_service
from app.services.message_metadata import build_assistant_metadata

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/chat", tags=["chat"])

# Match conversations.title column (200); used when AI title is rejected or fails
MAX_FALLBACK_TITLE_LENGTH = 200


async def _guest_chat_response(
    body: ChatRequest,
    db: AsyncSession,
) -> ChatResponse:
    """Ephemeral guest turn — no conversations or messages persisted."""
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
    return ChatResponse(
        reply=reply,
        conversation_id=None,
        conversation_title="",
        user_message_id=None,
        assistant_message_id=None,
        suggested_lawyers=suggested_lawyers,
        rag_enabled=rag_enabled,
        rag_sources=rag_sources,
        tavily_sources=tavily_sources,
    )


@router.post("/send", response_model=ChatResponse)
async def send_message(
    body: ChatRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    try:
        if current_user.is_anonymous:
            return await _guest_chat_response(body, db)

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

        user_msg = await conversation_service.add_message(
            db, conversation_id=conv.id, role="user", text=body.message
        )
        await db.flush()

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

        assistant_msg = await conversation_service.add_message(
            db,
            conversation_id=conv.id,
            role="model",
            text=reply,
            metadata=build_assistant_metadata(
                suggested_lawyers=nearby,
                rag_sources=rag_sources_raw,
                rag_enabled=rag_enabled,
            ),
        )

        conversation_title = conv.title
        if is_new_conversation:
            stripped = body.message.strip()
            if len(stripped) <= MAX_FALLBACK_TITLE_LENGTH:
                fallback = stripped
            else:
                fallback = f"{stripped[:197]}..."
            conversation_title = fallback
            await conversation_service.update_conversation_title(
                db, conv.id, conversation_title
            )
            schedule_conversation_title(
                conv.id,
                body.message,
                fallback_title=fallback,
                locale=body.locale,
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
    except AllProvidersRateLimitedError:
        raise HTTPException(
            status_code=429,
            detail="CLAiR is receiving too many requests right now. Please try again in a moment.",
        )
    except Exception as e:
        logger.exception("Chat error")
        error_msg = str(e)
        if "429" in error_msg or "quota" in error_msg.lower():
            raise HTTPException(
                status_code=429,
                detail="CLAiR is receiving too many requests right now. Please try again in a moment.",
            )
        raise HTTPException(status_code=500, detail="Failed to get a response. Please try again.")


_MAX_EXTRACT_CHARS = 6_000
_SUPPORTED_EXTENSIONS = {"txt", "pdf", "docx", "doc", "md"}


@router.post("/extract-file")
async def extract_file_text(
    file: Annotated[UploadFile, File()],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Extract plain text from an uploaded document so the AI can read it."""
    filename = file.filename or "file"
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""

    if ext not in _SUPPORTED_EXTENSIONS:
        raise HTTPException(
            status_code=415,
            detail=f"Unsupported file type '.{ext}'. Supported: {', '.join(sorted(_SUPPORTED_EXTENSIONS))}.",
        )

    content = await file.read()

    try:
        if ext in ("txt", "md"):
            text = content.decode("utf-8", errors="replace")

        elif ext == "pdf":
            try:
                from pypdf import PdfReader  # type: ignore
            except ImportError:
                raise HTTPException(status_code=500, detail="PDF extraction library not installed.")
            reader = PdfReader(io.BytesIO(content))
            pages = [page.extract_text() or "" for page in reader.pages]
            text = "\n\n".join(p for p in pages if p.strip())

        elif ext in ("docx", "doc"):
            try:
                import docx  # type: ignore
            except ImportError:
                raise HTTPException(status_code=500, detail="DOCX extraction library not installed.")
            doc = docx.Document(io.BytesIO(content))
            text = "\n".join(p.text for p in doc.paragraphs)

        else:
            text = ""

        text = text.strip()
        if not text:
            raise HTTPException(
                status_code=422,
                detail="No text could be extracted from this file. It may be scanned or image-only.",
            )

        if len(text) > _MAX_EXTRACT_CHARS:
            text = text[:_MAX_EXTRACT_CHARS] + f"\n\n[Document truncated at {_MAX_EXTRACT_CHARS:,} characters to stay within limits. Ask follow-up questions if you need analysis of a specific section.]"

        return {"text": text, "filename": filename}

    except HTTPException:
        raise
    except Exception as e:
        logger.exception("File extraction error")
        raise HTTPException(status_code=500, detail=f"Failed to extract file content: {e}")
