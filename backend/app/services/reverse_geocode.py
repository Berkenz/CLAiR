"""Best-effort reverse geocoding for chat context (OpenStreetMap Nominatim)."""

from __future__ import annotations

import logging

import httpx

logger = logging.getLogger(__name__)

# Nominatim requires a valid identifying User-Agent.
_NOMINATIM_UA = "CLAiR/1.0 (legal assistant; https://github.com/)"
_NOMINATIM_URL = "https://nominatim.openstreetmap.org/reverse"


async def reverse_geocode_area_label(lat: float, lng: float) -> str | None:
    """
    Return a short city / province style label (e.g. \"Quezon City, Metro Manila\").
    None on failure — chat must still work without this.
    """
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
            return None
        data = resp.json()
        addr = data.get("address")
        if not isinstance(addr, dict):
            return None

        locality = (
            addr.get("city")
            or addr.get("town")
            or addr.get("municipality")
            or addr.get("village")
            or addr.get("suburb")
        )
        region = addr.get("state") or addr.get("region")

        if isinstance(locality, str) and locality.strip():
            loc = locality.strip()
            if isinstance(region, str) and region.strip() and region.strip() != loc:
                return f"{loc}, {region.strip()}"
            return loc
        if isinstance(region, str) and region.strip():
            return region.strip()
        return None
    except Exception as e:
        logger.debug("Reverse geocode skipped: %s", e)
        return None
