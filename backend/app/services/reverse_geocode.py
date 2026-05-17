"""Best-effort reverse geocoding for chat context (OpenStreetMap Nominatim)."""

from __future__ import annotations

import logging
import time

import httpx

logger = logging.getLogger(__name__)

_GEO_CACHE_TTL_SECONDS = 86_400
_geocode_cache: dict[tuple[float, float], tuple[float, str | None]] = {}

# Nominatim requires a valid identifying User-Agent.
_NOMINATIM_UA = "CLAiR/1.0 (legal assistant; https://github.com/)"
_NOMINATIM_URL = "https://nominatim.openstreetmap.org/reverse"


def _cache_key(lat: float, lng: float) -> tuple[float, float]:
    return (round(lat, 2), round(lng, 2))


async def reverse_geocode_area_label(lat: float, lng: float) -> str | None:
    """
    Return a short city / province style label (e.g. \"Quezon City, Metro Manila\").
    None on failure — chat must still work without this.
    """
    key = _cache_key(lat, lng)
    cached = _geocode_cache.get(key)
    if cached is not None:
        ts, label = cached
        if time.monotonic() - ts < _GEO_CACHE_TTL_SECONDS:
            return label

    try:
        async with httpx.AsyncClient(timeout=4.0) as client:
            resp = await client.get(
                _NOMINATIM_URL,
                params={
                    "format": "json",
                    "lat": lat,
                    "lon": lng,
                    "zoom": 10,
                    "accept-language": "en",
                },
                headers={"User-Agent": _NOMINATIM_UA},
            )
        if resp.status_code != 200:
            _geocode_cache[key] = (time.monotonic(), None)
            return None
        data = resp.json()
        addr = data.get("address")
        if not isinstance(addr, dict):
            _geocode_cache[key] = (time.monotonic(), None)
            return None

        locality = (
            addr.get("city")
            or addr.get("town")
            or addr.get("municipality")
            or addr.get("village")
            or addr.get("suburb")
        )
        region = addr.get("state") or addr.get("region")

        label: str | None = None
        if isinstance(locality, str) and locality.strip():
            loc = locality.strip()
            if isinstance(region, str) and region.strip() and region.strip() != loc:
                label = f"{loc}, {region.strip()}"
            else:
                label = loc
        elif isinstance(region, str) and region.strip():
            label = region.strip()

        _geocode_cache[key] = (time.monotonic(), label)
        return label
    except Exception as e:
        logger.debug("Reverse geocode skipped: %s", e)
        _geocode_cache[key] = (time.monotonic(), None)
        return None
