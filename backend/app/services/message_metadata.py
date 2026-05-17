"""Serialize / deserialize assistant-turn extras stored on messages.metadata."""

from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal
from typing import Any

from app.schemas.chat import RagSourceItem, SuggestedLawyer


def _to_json_safe(value: Any) -> Any:
    """Make values JSONB-safe (UUID, Decimal, etc.)."""
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    if isinstance(value, uuid.UUID):
        return str(value)
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, datetime):
        return value.isoformat()
    if isinstance(value, dict):
        return {str(k): _to_json_safe(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_to_json_safe(v) for v in value]
    return str(value)


def _lawyer_dict_for_storage(lawyer: dict) -> dict[str, Any]:
    """Stable lawyer payload for JSONB (matches API card fields)."""
    return {
        "id": str(lawyer.get("id", "")),
        "display_name": lawyer.get("display_name"),
        "designation": lawyer.get("designation"),
        "practice_areas": list(lawyer.get("practice_areas") or []),
        "first_name": lawyer.get("first_name"),
        "last_name": lawyer.get("last_name"),
        "photo_url": lawyer.get("photo_url"),
        "bio": lawyer.get("bio"),
        "office_address": lawyer.get("office_address"),
        "office_hours": _to_json_safe(lawyer.get("office_hours")),
        "office_phone": lawyer.get("office_phone"),
        "mobile_phone": lawyer.get("mobile_phone"),
        "office_email": lawyer.get("office_email"),
        "latitude": lawyer.get("latitude"),
        "longitude": lawyer.get("longitude"),
    }


def build_assistant_metadata(
    *,
    suggested_lawyers: list[dict],
    rag_sources: list[dict],
    rag_enabled: bool,
) -> dict[str, Any]:
    return _to_json_safe(
        {
            "suggested_lawyers": [
                _lawyer_dict_for_storage(l) for l in suggested_lawyers
            ],
            "rag_sources": rag_sources,
            "rag_enabled": rag_enabled,
        }
    )


def message_response_extras(metadata: dict | None) -> dict[str, Any]:
    """Map DB JSONB → MessageResponse optional fields."""
    if not metadata:
        return {
            "suggested_lawyers": [],
            "rag_sources": [],
            "rag_enabled": None,
        }

    raw_lawyers = metadata.get("suggested_lawyers") or []
    lawyers: list[SuggestedLawyer] = []
    for item in raw_lawyers:
        if not isinstance(item, dict):
            continue
        lawyers.append(
            SuggestedLawyer(
                id=str(item.get("id", "")),
                display_name=item.get("display_name"),
                designation=item.get("designation"),
                practice_areas=item.get("practice_areas") or [],
                first_name=item.get("first_name"),
                last_name=item.get("last_name"),
                photo_url=item.get("photo_url"),
                bio=item.get("bio"),
                office_address=item.get("office_address"),
                office_hours=item.get("office_hours"),
                office_phone=item.get("office_phone"),
                mobile_phone=item.get("mobile_phone"),
                office_email=item.get("office_email"),
                latitude=item.get("latitude"),
                longitude=item.get("longitude"),
            )
        )

    raw_rag = metadata.get("rag_sources") or []
    rag_sources = [
        RagSourceItem(**r)
        for r in raw_rag
        if isinstance(r, dict)
    ]

    rag_enabled = metadata.get("rag_enabled")
    if rag_enabled is not None:
        rag_enabled = bool(rag_enabled)

    return {
        "suggested_lawyers": lawyers,
        "rag_sources": rag_sources,
        "rag_enabled": rag_enabled,
    }
