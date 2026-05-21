"""File storage: Supabase Storage (legacy) or Google Cloud Storage (recommended)."""

from __future__ import annotations

import logging
import uuid

from supabase import Client, create_client

from app.config import settings

logger = logging.getLogger(__name__)

BUCKET = "profile-photos"
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/webp", "image/gif"}

APPOINTMENT_BUCKET = "appointment-attachments"
_MAX_APPOINTMENT_FILE = 12 * 1024 * 1024  # 12 MB per file
_APPOINTMENT_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "image/gif",
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
}

CHAT_BUCKET = "chat-attachments"
_MAX_CHAT_FILE = 12 * 1024 * 1024  # 12 MB
_CHAT_ALLOWED_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "image/gif",
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
}


def _use_gcs() -> bool:
    if (settings.STORAGE_BACKEND or "supabase").strip().lower() != "gcs":
        return False
    from app.services.gcs_storage import gcs_configured, gcs_credentials_available

    if not gcs_configured():
        logger.warning(
            "STORAGE_BACKEND=gcs but GCS_BUCKET_NAME/GCS_PROJECT_ID missing; "
            "using Supabase storage"
        )
        return False
    if not gcs_credentials_available():
        logger.warning(
            "STORAGE_BACKEND=gcs but GCP credentials missing; using Supabase storage"
        )
        return False
    return True


def upload_http_exception(exc: Exception) -> HTTPException:
    """Map storage failures to a client-safe HTTP error."""
    from fastapi import HTTPException
    from google.cloud.exceptions import Forbidden

    logger.exception("Storage upload failed")
    if isinstance(exc, ValueError):
        return HTTPException(status_code=400, detail=str(exc))
    if isinstance(exc, Forbidden):
        return HTTPException(
            status_code=503,
            detail="File storage is not configured correctly on the server.",
        )
    msg = str(exc).lower()
    if any(
        token in msg
        for token in (
            "credentials",
            "permission",
            "403",
            "could not automatically determine credentials",
        )
    ):
        return HTTPException(
            status_code=503,
            detail="File uploads are unavailable. Server storage is not configured.",
        )
    return HTTPException(
        status_code=503,
        detail="Could not upload file. Please try again later.",
    )


def _gcs_prefix(bucket_name: str) -> str:
    """Folder prefix inside the single GCS bucket (mirrors Supabase bucket names)."""
    return f"{bucket_name}/"


def _get_supabase_client() -> Client:
    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        raise ValueError(
            "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set for Supabase storage"
        )
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)


def upload_profile_photo(user_id: str, content: bytes, content_type: str) -> str:
    """Upload profile photo and return the canonical public URL (no cache-bust param)."""
    if content_type not in ALLOWED_CONTENT_TYPES:
        raise ValueError(f"Invalid content type. Allowed: {ALLOWED_CONTENT_TYPES}")

    if len(content) > MAX_FILE_SIZE:
        raise ValueError(f"File too large. Max size: {MAX_FILE_SIZE // (1024 * 1024)}MB")

    ext = {
        "image/jpeg": "jpg",
        "image/jpg": "jpg",
        "image/png": "png",
        "image/webp": "webp",
        "image/gif": "gif",
    }.get(content_type, "jpg")

    path = f"{user_id}.{ext}"

    if _use_gcs():
        from app.services.gcs_storage import upload_bytes

        base_url = upload_bytes(
            object_path=f"{_gcs_prefix(BUCKET)}{path}",
            content=content,
            content_type=content_type,
        )
    else:
        client = _get_supabase_client()
        client.storage.from_(BUCKET).upload(
            path,
            content,
            file_options={"content-type": content_type, "upsert": "true"},
        )
        base_url = client.storage.from_(BUCKET).get_public_url(path)

    return base_url.strip()


def upload_appointment_attachment(
    *,
    client_user_id: str,
    appointment_id: str,
    filename: str,
    content: bytes,
    content_type: str,
) -> str:
    """Upload one appointment file; return public URL."""
    ct = (content_type or "application/octet-stream").split(";")[0].strip().lower()
    if ct not in _APPOINTMENT_TYPES:
        raise ValueError(
            f"Unsupported file type for appointments: {content_type!r}. "
            f"Allowed: {sorted(_APPOINTMENT_TYPES)}"
        )

    if len(content) > _MAX_APPOINTMENT_FILE:
        raise ValueError(f"File too large (max {_MAX_APPOINTMENT_FILE // (1024 * 1024)} MB)")

    safe = "".join(c if c.isalnum() or c in "._-" else "_" for c in filename)[:180]
    if not safe:
        safe = "attachment"

    uniq = uuid.uuid4().hex[:12]
    path = f"{client_user_id}/{appointment_id}/{uniq}_{safe}"

    if _use_gcs():
        from app.services.gcs_storage import upload_bytes

        return upload_bytes(
            object_path=f"{_gcs_prefix(APPOINTMENT_BUCKET)}{path}",
            content=content,
            content_type=ct,
        )

    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        raise ValueError("Supabase is not configured for file uploads")

    client = _get_supabase_client()
    client.storage.from_(APPOINTMENT_BUCKET).upload(
        path,
        content,
        file_options={"content-type": ct, "upsert": "true"},
    )
    return client.storage.from_(APPOINTMENT_BUCKET).get_public_url(path)


def upload_manual_case_document(
    *,
    appointment_id: str,
    filename: str,
    content: bytes,
    content_type: str,
) -> str:
    """Upload a document for a lawyer-created (manual) case."""
    ct = (content_type or "application/octet-stream").split(";")[0].strip().lower()
    if ct not in _APPOINTMENT_TYPES:
        raise ValueError(
            f"Unsupported file type for appointments: {content_type!r}. "
            f"Allowed: {sorted(_APPOINTMENT_TYPES)}"
        )

    if len(content) > _MAX_APPOINTMENT_FILE:
        raise ValueError(f"File too large (max {_MAX_APPOINTMENT_FILE // (1024 * 1024)} MB)")

    safe = "".join(c if c.isalnum() or c in "._-" else "_" for c in filename)[:180]
    if not safe:
        safe = "attachment"

    uniq = uuid.uuid4().hex[:12]
    path = f"manual-cases/{appointment_id}/{uniq}_{safe}"

    if _use_gcs():
        from app.services.gcs_storage import upload_bytes

        return upload_bytes(
            object_path=f"{_gcs_prefix(APPOINTMENT_BUCKET)}{path}",
            content=content,
            content_type=ct,
        )

    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        raise ValueError("Supabase is not configured for file uploads")

    client = _get_supabase_client()
    client.storage.from_(APPOINTMENT_BUCKET).upload(
        path,
        content,
        file_options={"content-type": ct, "upsert": "true"},
    )
    return client.storage.from_(APPOINTMENT_BUCKET).get_public_url(path)


def upload_consultation_summary_pdf(*, appointment_id: str, content: bytes) -> str:
    """
    Persist a generated consultation PDF (upsert).
    Returns storage object path for later download (not a public URL).
    """
    if len(content) > 8 * 1024 * 1024:
        raise ValueError("PDF too large to cache (max 8 MB)")

    path = f"consultation-summaries/{appointment_id}.pdf"

    if _use_gcs():
        from app.services.gcs_storage import upload_bytes

        upload_bytes(
            object_path=f"{_gcs_prefix(APPOINTMENT_BUCKET)}{path}",
            content=content,
            content_type="application/pdf",
        )
        return path

    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        raise ValueError("Supabase is not configured for PDF caching")

    client = _get_supabase_client()
    client.storage.from_(APPOINTMENT_BUCKET).upload(
        path,
        content,
        file_options={"content-type": "application/pdf", "upsert": "true"},
    )
    return path


def upload_chat_attachment(
    *,
    appointment_id: str,
    sender_type: str,
    filename: str,
    content: bytes,
    content_type: str,
) -> str:
    """Upload a direct-message attachment; return public URL."""
    ct = (content_type or "application/octet-stream").split(";")[0].strip().lower()
    if ct not in _CHAT_ALLOWED_TYPES:
        raise ValueError(
            f"Unsupported file type: {content_type!r}. "
            f"Allowed: {sorted(_CHAT_ALLOWED_TYPES)}"
        )

    if len(content) > _MAX_CHAT_FILE:
        raise ValueError(f"File too large (max {_MAX_CHAT_FILE // (1024 * 1024)} MB)")

    safe = "".join(c if c.isalnum() or c in "._-" else "_" for c in filename)[:180]
    if not safe:
        safe = "attachment"

    uniq = uuid.uuid4().hex[:12]
    path = f"{appointment_id}/{sender_type}/{uniq}_{safe}"

    if _use_gcs():
        from app.services.gcs_storage import upload_bytes

        return upload_bytes(
            object_path=f"{_gcs_prefix(CHAT_BUCKET)}{path}",
            content=content,
            content_type=ct,
        )

    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        raise ValueError("Supabase is not configured for file uploads")

    client = _get_supabase_client()
    client.storage.from_(CHAT_BUCKET).upload(
        path,
        content,
        file_options={"content-type": ct, "upsert": "true"},
    )
    return client.storage.from_(CHAT_BUCKET).get_public_url(path)


def download_storage_object(path: str) -> bytes:
    """Download raw bytes for a cached PDF path (relative to appointment-attachments)."""
    if _use_gcs():
        from app.services.gcs_storage import download_bytes

        return download_bytes(f"{_gcs_prefix(APPOINTMENT_BUCKET)}{path}")

    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        raise ValueError("Supabase is not configured")
    client = _get_supabase_client()
    return client.storage.from_(APPOINTMENT_BUCKET).download(path)


def delete_storage_object(path: str) -> None:
    """Remove one object; ignore missing."""
    if _use_gcs():
        from app.services.gcs_storage import delete_object

        try:
            delete_object(f"{_gcs_prefix(APPOINTMENT_BUCKET)}{path}")
        except Exception:
            logger.exception("GCS delete failed for %s", path)
        return

    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        return
    try:
        client = _get_supabase_client()
        client.storage.from_(APPOINTMENT_BUCKET).remove([path])
    except Exception:
        pass
