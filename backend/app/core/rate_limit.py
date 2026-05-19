"""API rate limiting (slowapi + limits)."""

from __future__ import annotations

import logging
from typing import Annotated

from fastapi import Depends, HTTPException, Request, status
from limits import parse
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.config import settings
from app.core.security import get_current_user
from app.models.user import User

logger = logging.getLogger(__name__)

limiter = Limiter(key_func=get_remote_address)


async def enforce_chat_rate_limit(
    request: Request,
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    """
    Per-user chat send limits (runs after Firebase auth).
    Anonymous: 5/min; registered: 15/min (configurable).
    """
    if not settings.CHAT_RATE_LIMIT_ENABLED:
        return

    limit_str = (
        settings.CHAT_RATE_LIMIT_ANONYMOUS
        if current_user.is_anonymous
        else settings.CHAT_RATE_LIMIT_REGISTERED
    )
    scope = "anon" if current_user.is_anonymous else "reg"
    key = f"chat:{scope}:{current_user.id}"

    try:
        allowed = limiter.limiter.hit(parse(limit_str), key)
    except Exception:
        logger.exception("Rate limit check failed; allowing request")
        return

    if not allowed:
        logger.warning(
            "Chat rate limit exceeded user_id=%s anonymous=%s",
            current_user.id,
            current_user.is_anonymous,
        )
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=(
                "You're sending messages too quickly. "
                "Please wait a moment and try again."
            ),
        )
