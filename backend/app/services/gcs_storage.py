"""Google Cloud Storage uploads (profile photos, attachments, PDF cache)."""

from __future__ import annotations

import json
import logging
import os
from functools import lru_cache

from google.cloud import storage
from google.cloud.exceptions import Forbidden, NotFound
from google.oauth2 import service_account

from app.config import settings

logger = logging.getLogger(__name__)

_client: storage.Client | None = None


def gcs_configured() -> bool:
    bucket = (settings.GCS_BUCKET_NAME or "").strip()
    project = (settings.GCS_PROJECT_ID or settings.GCP_PROJECT_ID or "").strip()
    return bool(bucket and project)


def gcs_credentials_available() -> bool:
    """True when we can authenticate to GCS (JSON env, key file, or ADC)."""
    if (settings.GCP_SERVICE_ACCOUNT_JSON or "").strip():
        return True
    path = _credentials_path()
    if path and os.path.isfile(path):
        return True
    try:
        import google.auth

        google.auth.default()
        return True
    except Exception:
        return False


def _credentials_path() -> str | None:
    return (
        settings.GCP_VERTEX_CREDENTIALS_PATH
        or settings.GOOGLE_APPLICATION_CREDENTIALS
        or os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    )


def _ensure_credentials_env() -> None:
    path = _credentials_path()
    if path and os.path.isfile(path):
        os.environ.setdefault("GOOGLE_APPLICATION_CREDENTIALS", path)


@lru_cache(maxsize=1)
def _service_account_credentials():
    raw = (settings.GCP_SERVICE_ACCOUNT_JSON or "").strip()
    if raw:
        try:
            info = json.loads(raw)
        except json.JSONDecodeError as e:
            raise ValueError("GCP_SERVICE_ACCOUNT_JSON is not valid JSON") from e
        return service_account.Credentials.from_service_account_info(info)

    path = _credentials_path()
    if path and os.path.isfile(path):
        return service_account.Credentials.from_service_account_file(path)

    return None


def _get_client() -> storage.Client:
    global _client
    if not gcs_configured():
        raise ValueError(
            "GCS storage requires GCS_BUCKET_NAME and GCP_PROJECT_ID (or GCS_PROJECT_ID)"
        )
    if _client is None:
        project = settings.GCS_PROJECT_ID or settings.GCP_PROJECT_ID
        creds = _service_account_credentials()
        if creds is not None:
            _client = storage.Client(project=project, credentials=creds)
        else:
            _ensure_credentials_env()
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
    try:
        blob.upload_from_string(content, content_type=content_type)
    except Forbidden as e:
        logger.exception(
            "GCS upload forbidden for gs://%s/%s",
            settings.GCS_BUCKET_NAME,
            object_path,
        )
        raise ValueError(
            "Cloud storage permission denied. Check the service account has "
            "Storage Object Admin on the bucket."
        ) from e
    logger.info(
        "GCS upload ok: gs://%s/%s (%d bytes)",
        settings.GCS_BUCKET_NAME,
        object_path,
        len(content),
    )
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
