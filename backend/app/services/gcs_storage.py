"""Google Cloud Storage uploads (profile photos, attachments, PDF cache)."""

from __future__ import annotations

import logging
import os

from google.cloud import storage
from google.cloud.exceptions import NotFound

from app.config import settings

logger = logging.getLogger(__name__)

_client: storage.Client | None = None


def gcs_configured() -> bool:
    bucket = (settings.GCS_BUCKET_NAME or "").strip()
    project = (settings.GCS_PROJECT_ID or settings.GCP_PROJECT_ID or "").strip()
    return bool(bucket and project)


def _ensure_credentials() -> None:
    path = (
        settings.GCP_VERTEX_CREDENTIALS_PATH
        or os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    )
    if path and os.path.isfile(path):
        os.environ.setdefault("GOOGLE_APPLICATION_CREDENTIALS", path)


def _get_client() -> storage.Client:
    global _client
    if not gcs_configured():
        raise ValueError(
            "GCS storage requires GCS_BUCKET_NAME and GCP_PROJECT_ID (or GCS_PROJECT_ID)"
        )
    _ensure_credentials()
    if _client is None:
        project = settings.GCS_PROJECT_ID or settings.GCP_PROJECT_ID
        _client = storage.Client(project=project)
    return _client


def public_url(object_path: str) -> str:
    bucket = settings.GCS_BUCKET_NAME
    return f"https://storage.googleapis.com/{bucket}/{object_path}"


def upload_bytes(*, object_path: str, content: bytes, content_type: str) -> str:
    """Upload object and return a stable public HTTPS URL."""
    client = _get_client()
    bucket = client.bucket(settings.GCS_BUCKET_NAME)
    blob = bucket.blob(object_path)
    blob.upload_from_string(content, content_type=content_type)
    logger.info("GCS upload ok: gs://%s/%s (%d bytes)", settings.GCS_BUCKET_NAME, object_path, len(content))
    return public_url(object_path)


def download_bytes(object_path: str) -> bytes:
    client = _get_client()
    bucket = client.bucket(settings.GCS_BUCKET_NAME)
    blob = bucket.blob(object_path)
    try:
        return blob.download_as_bytes()
    except NotFound as e:
        raise FileNotFoundError(object_path) from e


def delete_object(object_path: str) -> None:
    client = _get_client()
    bucket = client.bucket(settings.GCS_BUCKET_NAME)
    blob = bucket.blob(object_path)
    try:
        blob.delete()
    except NotFound:
        pass
