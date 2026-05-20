"""Cache-bust helpers for profile photo URLs stored at stable storage paths."""

from __future__ import annotations

from datetime import datetime
from urllib.parse import parse_qsl, urlencode, urlparse, urlunparse


def photo_url_with_cache_bust(url: str | None, updated_at: datetime | None) -> str | None:
    """Append ?v=<timestamp> so clients refetch after re-upload to the same object path."""
    if not url or not url.strip():
        return None
    trimmed = url.strip()
    if updated_at is None:
        return trimmed
    parsed = urlparse(trimmed)
    query = dict(parse_qsl(parsed.query, keep_blank_values=True))
    query["v"] = str(int(updated_at.timestamp() * 1000))
    return urlunparse(parsed._replace(query=urlencode(query)))
