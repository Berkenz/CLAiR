from __future__ import annotations

import io
from datetime import datetime

from fpdf import FPDF

from app.models.conversation import Conversation, Message
from app.models.user import User
from app.services.chat_service import _get_client

_SUMMARY_MODEL = "llama-3.1-8b-instant"


_SUMMARY_SYSTEM = (
    "You are a legal assistant summarizer. You produce clear, structured "
    "summaries of client-lawyer consultations for a Philippine legal AI called CLAiR.\n\n"
    "Your summary will be read by a licensed attorney who needs to quickly understand:\n"
    "1. The client's situation and key facts\n"
    "2. The specific legal questions or concerns raised\n"
    "3. The legal topics / areas of law involved\n"
    "4. Key advice or information already provided by CLAiR\n"
    "5. Any next steps or action items mentioned\n\n"
    "Rules:\n"
    "- Write in third person ('The client ...', 'CLAiR advised ...')\n"
    "- Be concise but include all legally relevant facts\n"
    "- Use plain text; no markdown, no bullet symbols, no special formatting\n"
    "- Organize into short paragraphs with blank lines between them\n"
    "- Do NOT fabricate facts not present in the conversation"
)

_SUMMARY_MAX_CHARS = 12000

# ── Short appointment-description summary ─────────────────────────────────────

_SHORT_SUMMARY_SYSTEM = (
    "You write the text for the 'Description' field when a client books a legal "
    "consultation with a lawyer (Philippines). The lawyer will read this on the "
    "appointment request.\n\n"
    "Voice and tone:\n"
    "- Write in the first person as the client (I would like…, I need help with…, "
    "I’m hoping to discuss…).\n"
    "- It must read like a short, natural booking note — not a case summary, memo, "
    "or recap of 'what was discussed'.\n"
    "- Do NOT use analytical or third-person wording such as: 'The main legal topic', "
    "'The client', 'discussed was', 'raised a question', 'seeking clarification', "
    "'the specific circumstances surrounding', or similar.\n"
    "- 2–3 sentences maximum. Plain sentences only. No lists, headings, or markdown.\n"
    "- Stay factual; only include details supported by the conversation. Do not invent facts."
)


async def _generate_short_summary(messages: list[Message]) -> str:
    """2–3 sentence overview for an appointment booking description."""
    transcript_parts: list[str] = []
    for msg in messages:
        label = "Client" if msg.role == "user" else "CLAiR"
        transcript_parts.append(f"{label}: {msg.text}")
    transcript = "\n\n".join(transcript_parts)
    if len(transcript) > _SUMMARY_MAX_CHARS:
        transcript = transcript[:_SUMMARY_MAX_CHARS] + "\n...(truncated)"

    prompt = (
        "Below is my prior chat with CLAiR (AI legal assistant). Write 2–3 sentences "
        "I could paste into the appointment description when booking a lawyer — "
        "first person, polite, and focused on what I want from the consultation.\n\n"
        f"--- CONVERSATION ---\n{transcript}\n--- END ---\n\n"
        "Appointment description (first person, as if I wrote it for the booking form):"
    )

    try:
        client = _get_client()
        response = await client.chat.completions.create(
            model=_SUMMARY_MODEL,
            messages=[
                {"role": "system", "content": _SHORT_SUMMARY_SYSTEM},
                {"role": "user", "content": prompt},
            ],
            max_tokens=220,
            temperature=0.35,
        )
        text = (response.choices[0].message.content or "").strip()
        if text:
            return text
    except Exception:
        pass

    return ""


async def _generate_summary(messages: list[Message]) -> str:
    transcript_parts: list[str] = []
    for msg in messages:
        label = "Client" if msg.role == "user" else "CLAiR"
        transcript_parts.append(f"{label}: {msg.text}")
    transcript = "\n\n".join(transcript_parts)
    if len(transcript) > _SUMMARY_MAX_CHARS:
        transcript = transcript[:_SUMMARY_MAX_CHARS] + "\n...(truncated)"

    prompt = (
        "Summarize the following legal consultation conversation for a lawyer.\n\n"
        f"--- CONVERSATION ---\n{transcript}\n--- END ---\n\n"
        "Write the summary now."
    )

    try:
        client = _get_client()
        response = await client.chat.completions.create(
            model=_SUMMARY_MODEL,
            messages=[
                {"role": "system", "content": _SUMMARY_SYSTEM},
                {"role": "user", "content": prompt},
            ],
            max_tokens=1500,
            temperature=0.0,
        )
        text = (response.choices[0].message.content or "").strip()
        if text:
            return text
    except Exception:
        pass

    return "Summary could not be generated automatically. Please review the full conversation."


def _build_pdf(
    *,
    user: User,
    conversation: Conversation,
    summary: str,
) -> bytes:
    pdf = FPDF()
    pdf.set_auto_page_break(auto=True, margin=25)
    pdf.add_page()

    pdf.set_font("Helvetica", "B", 20)
    pdf.cell(0, 12, "CLAiR - Legal Consultation Summary", new_x="LMARGIN", new_y="NEXT", align="C")
    pdf.ln(4)

    pdf.set_draw_color(100, 70, 50)
    pdf.set_line_width(0.5)
    pdf.line(10, pdf.get_y(), 200, pdf.get_y())
    pdf.ln(6)

    pdf.set_font("Helvetica", "B", 12)
    pdf.cell(0, 8, "Client Information", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(2)

    pdf.set_font("Helvetica", "", 11)
    name = user.full_name or "N/A"
    email = user.email or "N/A"
    location = user.location or "N/A"

    pdf.cell(40, 7, "Name:", new_x="RIGHT")
    pdf.cell(0, 7, name, new_x="LMARGIN", new_y="NEXT")
    pdf.cell(40, 7, "Email:", new_x="RIGHT")
    pdf.cell(0, 7, email, new_x="LMARGIN", new_y="NEXT")
    pdf.cell(40, 7, "Location:", new_x="RIGHT")
    pdf.cell(0, 7, location, new_x="LMARGIN", new_y="NEXT")
    pdf.ln(4)

    pdf.set_font("Helvetica", "B", 12)
    pdf.cell(0, 8, "Conversation Details", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(2)

    pdf.set_font("Helvetica", "", 11)
    pdf.cell(40, 7, "Title:", new_x="RIGHT")
    pdf.cell(0, 7, conversation.title, new_x="LMARGIN", new_y="NEXT")

    date_str = conversation.created_at.strftime("%B %d, %Y at %I:%M %p")
    pdf.cell(40, 7, "Date:", new_x="RIGHT")
    pdf.cell(0, 7, date_str, new_x="LMARGIN", new_y="NEXT")
    pdf.ln(6)

    pdf.set_draw_color(100, 70, 50)
    pdf.line(10, pdf.get_y(), 200, pdf.get_y())
    pdf.ln(6)

    pdf.set_font("Helvetica", "B", 14)
    pdf.cell(0, 10, "Summary", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(2)

    pdf.set_font("Helvetica", "", 11)
    for paragraph in summary.split("\n"):
        stripped = paragraph.strip()
        if stripped:
            pdf.multi_cell(0, 6, stripped)
            pdf.ln(3)

    pdf.ln(8)
    pdf.set_draw_color(100, 70, 50)
    pdf.line(10, pdf.get_y(), 200, pdf.get_y())
    pdf.ln(4)

    pdf.set_font("Helvetica", "I", 9)
    pdf.set_text_color(120, 120, 120)
    pdf.multi_cell(
        0, 5,
        "This document was generated by CLAiR, an AI legal assistant. "
        "The information provided is for reference purposes only and does not "
        "constitute legal advice. Please consult a licensed attorney for "
        "specific legal matters.",
    )

    pdf.ln(3)
    gen_time = datetime.now().strftime("%B %d, %Y at %I:%M %p")
    pdf.set_font("Helvetica", "", 8)
    pdf.cell(0, 5, f"Generated: {gen_time}", new_x="LMARGIN", new_y="NEXT", align="R")

    buffer = io.BytesIO()
    pdf.output(buffer)
    return buffer.getvalue()


async def generate_appointment_description_summary(messages: list[Message]) -> str:
    """Short 2–3 sentence overview for the appointment booking description field."""
    if not messages:
        return ""
    short = await _generate_short_summary(messages)
    if short:
        return short
    # Fallback: trim the detailed summary to its first paragraph
    detailed = await _generate_summary(messages)
    first_para = detailed.split("\n\n")[0].strip()
    return first_para or detailed


async def generate_consultation_pdf(
    user: User,
    conversation: Conversation,
) -> bytes:
    summary = await _generate_summary(conversation.messages)
    return _build_pdf(user=user, conversation=conversation, summary=summary)
