"""Supabase Storage service for profile photos."""

import uuid

from supabase import create_client, Client

from app.config import settings

BUCKET = "profile-photos"
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/webp", "image/gif"}


def _get_client() -> Client:
    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        raise ValueError(
            "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set for profile photo upload"
        )
    return create_client(
        settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY
    )


def upload_profile_photo(user_id: str, content: bytes, content_type: str) -> str:
    """
    Upload profile photo to Supabase Storage and return the public URL.
    """
    if content_type not in ALLOWED_CONTENT_TYPES:
        raise ValueError(f"Invalid content type. Allowed: {ALLOWED_CONTENT_TYPES}")

    if len(content) > MAX_FILE_SIZE:
        raise ValueError(f"File too large. Max size: {MAX_FILE_SIZE // (1024*1024)}MB")

    ext = {
        "image/jpeg": "jpg",
        "image/jpg": "jpg",
        "image/png": "png",
        "image/webp": "webp",
        "image/gif": "gif",
    }.get(content_type, "jpg")

    path = f"{user_id}.{ext}"
    client = _get_client()

    client.storage.from_(BUCKET).upload(
        path,
        content,
        file_options={"content-type": content_type, "upsert": "true"},
    )

    return client.storage.from_(BUCKET).get_public_url(path)


# ── Appointment attachments (client booking → lawyer portal) ─────────────────

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


def upload_appointment_attachment(
    *,
    client_user_id: str,
    appointment_id: str,
    filename: str,
    content: bytes,
    content_type: str,
) -> str:
    """
    Upload one file for an appointment; return public URL.
    Requires Supabase bucket ``appointment-attachments`` (public read recommended).
    """
    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        raise ValueError("Supabase is not configured for file uploads")

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
    client = _get_client()
    client.storage.from_(APPOINTMENT_BUCKET).upload(
        path,
        content,
        file_options={"content-type": content_type.split(";")[0].strip(), "upsert": "true"},
    )
    return client.storage.from_(APPOINTMENT_BUCKET).get_public_url(path)


def upload_manual_case_document(
    *,
    appointment_id: str,
    filename: str,
    content: bytes,
    content_type: str,
) -> str:
    """
    Upload a document for a lawyer-created (manual) case.
    Stored under ``manual-cases/{appointment_id}/`` in ``appointment-attachments``.
    """
    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        raise ValueError("Supabase is not configured for file uploads")

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
    client = _get_client()
    client.storage.from_(APPOINTMENT_BUCKET).upload(
        path,
        content,
        file_options={"content-type": content_type.split(";")[0].strip(), "upsert": "true"},
    )
    return client.storage.from_(APPOINTMENT_BUCKET).get_public_url(path)


def upload_consultation_summary_pdf(*, appointment_id: str, content: bytes) -> str:
    """
    Persist a generated CLAiR consultation PDF for an appointment (upsert).
    Returns the storage object path (not a public URL) for later download via service role.
    """
    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        raise ValueError("Supabase is not configured for PDF caching")

    if len(content) > 8 * 1024 * 1024:
        raise ValueError("PDF too large to cache (max 8 MB)")

    path = f"consultation-summaries/{appointment_id}.pdf"
    client = _get_client()
    client.storage.from_(APPOINTMENT_BUCKET).upload(
        path,
        content,
        file_options={"content-type": "application/pdf", "upsert": "true"},
    )
    return path


# ── Direct chat attachments (client ↔ lawyer) ────────────────────────────────

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


def upload_chat_attachment(
    *,
    appointment_id: str,
    sender_type: str,
    filename: str,
    content: bytes,
    content_type: str,
) -> str:
    """
    Upload a direct-message attachment; return public URL.
    Requires Supabase bucket ``chat-attachments`` (public read).
    """
    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        raise ValueError("Supabase is not configured for file uploads")

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
    client = _get_client()
    client.storage.from_(CHAT_BUCKET).upload(
        path,
        content,
        file_options={"content-type": ct, "upsert": "true"},
    )
    return client.storage.from_(CHAT_BUCKET).get_public_url(path)


def download_storage_object(path: str) -> bytes:
    """Download raw bytes from appointment-attachments bucket."""
    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        raise ValueError("Supabase is not configured")
    client = _get_client()
    return client.storage.from_(APPOINTMENT_BUCKET).download(path)


def delete_storage_object(path: str) -> None:
    """Remove one object from appointment-attachments; ignore missing."""
    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        return
    try:
        client = _get_client()
        client.storage.from_(APPOINTMENT_BUCKET).remove([path])
    except Exception:
        pass
