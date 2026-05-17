"""Background conversation title generation (does not block /chat/send)."""

from __future__ import annotations

import asyncio
import logging
import uuid

from app.database import AsyncSessionLocal
from app.services.chat_service import generate_conversation_title
from app.services.conversation_service import conversation_service

logger = logging.getLogger(__name__)


def schedule_conversation_title(
    conversation_id: uuid.UUID,
    user_message: str,
    *,
    fallback_title: str,
    locale: str = "en",
) -> None:
    """Fire-and-forget: refine conversation title in the database."""

    async def _run() -> None:
        async with AsyncSessionLocal() as db:
            try:
                title = await generate_conversation_title(
                    user_message,
                    "",
                    fallback_title=fallback_title,
                    locale=locale,
                )
                await conversation_service.update_conversation_title(
                    db, conversation_id, title
                )
                await db.commit()
            except Exception:
                logger.exception(
                    "Background title generation failed for conversation %s",
                    conversation_id,
                )

    asyncio.create_task(_run())
