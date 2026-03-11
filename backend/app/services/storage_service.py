"""Supabase Storage service for profile photos."""

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
