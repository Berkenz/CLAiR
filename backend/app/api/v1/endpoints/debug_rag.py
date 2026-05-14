"""DEBUG-only RAG diagnostics (no auth — do not enable DEBUG in production)."""

from fastapi import APIRouter, HTTPException, Query

from app.config import settings
from app.services.vector_service import rag_self_test

router = APIRouter(prefix="/debug", tags=["debug"])


@router.get("/rag")
async def debug_rag(
    q: str = Query(
        ...,
        min_length=3,
        description="Sample user question to test retrieval (e.g. penalties under anti-hazing law)",
    ),
):
    """
    Returns whether vector DB + embed service work and sample chunks for *q*.

    Only available when ``DEBUG=true`` in settings (typically from ``.env``).
    """
    if not settings.DEBUG:
        raise HTTPException(status_code=404, detail="Not found")
    return await rag_self_test(q)
