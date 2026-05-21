"""Cache-bust helpers for profile photo URLs stored at stable storage paths."""

from __future__ import annotations

from datetime import datetime
from urllib.parse import parse_qsl, urlencode, urlparse, urlunparse


def photo_url_strip_cache_bust(url: str | None) -> str | None:
    """Remove ?v= from stored URLs so cache busting uses [updated_at] only."""
    if not url or not url.strip():
        return None
    parsed = urlparse(url.strip())
    query = dict(parse_qsl(parsed.query, keep_blank_values=True))
    query.pop("v", None)
    return urlunparse(parsed._replace(query=urlencode(query) if query else ""))


def photo_url_with_cache_bust(url: str | None, updated_at: datetime | None) -> str | None:
    """Append ?v=<timestamp> so clients refetch after re-upload to the same object path."""
    clean = photo_url_strip_cache_bust(url)
    if not clean:
        return None
    if updated_at is None:
        return clean
    parsed = urlparse(clean)
    query = dict(parse_qsl(parsed.query, keep_blank_values=True))
    query["v"] = str(int(updated_at.timestamp() * 1000))
    return urlunparse(parsed._replace(query=urlencode(query)))
