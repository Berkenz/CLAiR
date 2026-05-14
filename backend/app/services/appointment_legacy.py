"""Split legacy appointment descriptions (Subject: … + embedded blocks) into fields."""

from __future__ import annotations

import re

from app.models.appointment import Appointment


def migrate_legacy_appointment_if_needed(appt: Appointment) -> bool:
    """
    If case_title is empty and description starts with 'Subject:', split into
    case_title, cleaned description, and filename-only attachment rows.
    Returns True if the ORM object was modified (caller should flush).
    """
    if appt.case_title and str(appt.case_title).strip():
        return False

    desc = (appt.description or "").strip()
    if not desc.lower().startswith("subject:"):
        return False

    rest = desc[8:].lstrip()
    sep = "\n\n"
    idx = rest.find(sep)
    if idx != -1:
        title = rest[:idx].strip()
        body = rest[idx + 2 :].strip()
    else:
        nl = rest.find("\n")
        if nl == -1:
            title, body = rest.strip(), ""
        else:
            title, body = rest[:nl].strip(), rest[nl + 1 :].strip()

    if not title:
        title = "Consultation request"

    body = re.sub(
        r"\n*\n*---\s*\n*CLAiR conversation:.*$",
        "",
        body,
        flags=re.DOTALL | re.IGNORECASE,
    ).strip()

    parsed_files: list[dict] = []
    m = re.search(r"---\s*\n*Attached files:\s*\n(.*)$", body, re.DOTALL | re.IGNORECASE)
    if m:
        files_block = m.group(1)
        body = body[: m.start()].strip()
        for line in files_block.splitlines():
            line = line.strip()
            if not line:
                continue
            name = re.sub(r"^[•\-\*]\s*", "", line).strip()
            if name:
                parsed_files.append(
                    {"filename": name, "url": None, "content_type": None}
                )

    existing: list = list(appt.attachments) if appt.attachments else []
    seen = {str(x.get("filename", "")) for x in existing if isinstance(x, dict)}
    merged = [*existing]
    for item in parsed_files:
        fn = item.get("filename")
        if fn and fn not in seen:
            merged.append(item)
            seen.add(fn)

    appt.case_title = title[:500]
    appt.description = body or None
    appt.attachments = merged if merged else []
    return True
