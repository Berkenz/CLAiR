from __future__ import annotations

import io
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

from fpdf import FPDF

from app.models.conversation import Conversation, Message
from app.models.user import User
from app.services.llm_completion import chat_completion

_SUMMARY_MAX_CHARS = 12000

_ASSETS_DIR = Path(__file__).resolve().parent.parent / "assets"
_LOGO_PATH = _ASSETS_DIR / "clair_logo.png"
_FONTS_DIR = _ASSETS_DIR / "fonts"

_ACCENT = (139, 106, 122)
_ACCENT_DARK = (94, 58, 78)
_TEXT_DARK = (26, 26, 46)
_TEXT_MID = (107, 114, 128)
_MUTED_BG = (244, 245, 247)

_FONT = "Helvetica"
_UNICODE_FONT = "ArialUni"

_LAWYER_SUMMARY_SYSTEM = (
    "You write brief consultation summaries for licensed attorneys in the Philippines. "
    "The attorney will read this to understand a prior chat between the client and CLAiR "
    "(an AI legal assistant).\n\n"
    "Output plain text only. No markdown, bullets, headings, labels, or JSON.\n"
    "Write 2–4 short paragraphs separated by a single blank line. Cover:\n"
    "- What the client needs and the key facts.\n"
    "- The main legal issues or questions.\n"
    "- What CLAiR already told the client (brief).\n"
    "- Any lawyers mentioned or practical next steps, only if they appear in the chat.\n\n"
    "Use third person ('The client…', 'CLAiR explained…'). Be concise and factual. "
    "Do not invent details."
)

_SHORT_SUMMARY_SYSTEM = (
    "You write the text for the 'Description' field when a client books a legal "
    "consultation with a lawyer (Philippines). The lawyer will read this on the "
    "appointment request.\n\n"
    "Voice and tone:\n"
    "- Write in the first person as the client (I would like…, I need help with…, "
    "I'm hoping to discuss…).\n"
    "- It must read like a short, natural booking note — not a case summary, memo, "
    "or recap of 'what was discussed'.\n"
    "- Do NOT use analytical or third-person wording such as: 'The main legal topic', "
    "'The client', 'discussed was', 'raised a question', 'seeking clarification', "
    "'the specific circumstances surrounding', or similar.\n"
    "- 2–3 sentences maximum. Plain sentences only. No lists, headings, or markdown.\n"
    "- Stay factual; only include details supported by the conversation. Do not invent facts."
)


@dataclass
class ConsultationSummary:
    """Plain narrative summary for the PDF body."""
    body: str


def _register_fonts(pdf: FPDF) -> str:
    regular = _FONTS_DIR / "Arial.ttf"
    bold = _FONTS_DIR / "Arial-Bold.ttf"
    italic = _FONTS_DIR / "Arial-Italic.ttf"
    if regular.is_file() and bold.is_file():
        pdf.add_font(_UNICODE_FONT, "", str(regular))
        pdf.add_font(_UNICODE_FONT, "B", str(bold))
        pdf.add_font(
            _UNICODE_FONT,
            "I",
            str(italic) if italic.is_file() else str(regular),
        )
        return _UNICODE_FONT
    return _FONT


def _safe(text: str) -> str:
    if not text:
        return ""
    try:
        return text.encode("latin-1").decode("latin-1")
    except UnicodeEncodeError:
        return text.encode("latin-1", errors="replace").decode("latin-1")


async def _generate_short_summary(messages: list[Message]) -> str:
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
        text = await chat_completion(
            [
                {"role": "system", "content": _SHORT_SUMMARY_SYSTEM},
                {"role": "user", "content": prompt},
            ],
            max_tokens=220,
            temperature=0.35,
            title=True,
        )
        if text:
            return text
    except Exception:
        pass

    return ""


async def _generate_summary(messages: list[Message]) -> ConsultationSummary:
    transcript_parts: list[str] = []
    for msg in messages:
        label = "Client" if msg.role == "user" else "CLAiR"
        transcript_parts.append(f"{label}: {msg.text}")
    transcript = "\n\n".join(transcript_parts)
    if len(transcript) > _SUMMARY_MAX_CHARS:
        transcript = transcript[:_SUMMARY_MAX_CHARS] + "\n...(truncated)"

    prompt = (
        "Summarize this client–CLAiR conversation for an attorney.\n\n"
        f"--- CONVERSATION ---\n{transcript}\n--- END ---\n\n"
        "Write the summary now."
    )

    fallback = (
        "Summary could not be generated automatically. "
        "Please review the full conversation in CLAiR."
    )

    try:
        text = await chat_completion(
            [
                {"role": "system", "content": _LAWYER_SUMMARY_SYSTEM},
                {"role": "user", "content": prompt},
            ],
            max_tokens=900,
            temperature=0.0,
            title=True,
        )
        if text:
            return ConsultationSummary(body=text)
    except Exception:
        pass

    return ConsultationSummary(body=fallback)


class _ClairConsultationPDF(FPDF):
    HEADER_H = 22
    MARGIN_L = 18
    MARGIN_R = 18

    def __init__(self) -> None:
        super().__init__()
        self._font = _register_fonts(self)
        self.set_auto_page_break(auto=True, margin=18)
        self.set_margins(self.MARGIN_L, self.HEADER_H + 10, self.MARGIN_R)
        self.alias_nb_pages()

    def _display(self, text: str) -> str:
        return _safe(text) if self._font == _FONT else text

    def _width(self) -> float:
        return self.w - self.MARGIN_L - self.MARGIN_R

    def header(self) -> None:
        self.set_fill_color(*_ACCENT_DARK)
        self.rect(0, 0, 210, self.HEADER_H, style="F")

        if _LOGO_PATH.is_file():
            try:
                self.image(str(_LOGO_PATH), x=172, y=3, w=16, h=16)
            except Exception:
                pass

        self.set_text_color(255, 255, 255)
        self.set_font(self._font, "B", 13)
        self.set_xy(self.MARGIN_L, 6)
        self.cell(0, 6, "CLAiR")
        self.set_font(self._font, "", 8)
        self.set_xy(self.MARGIN_L, 13)
        self.cell(0, 4, "Conversation summary for attorney review")
        self.set_text_color(*_TEXT_DARK)
        self.set_y(self.HEADER_H + 10)

    def footer(self) -> None:
        self.set_y(-14)
        self.set_font(self._font, "I", 7)
        self.set_text_color(*_TEXT_MID)
        self.cell(
            0,
            4,
            self._display(
                "AI-generated summary for reference only — not legal advice.  "
                f"Page {self.page_no()} of {{nb}}"
            ),
            align="C",
        )

    def _meta_panel(self, lines: list[tuple[str, str]]) -> None:
        x0 = self.MARGIN_L
        y0 = self.get_y()
        pad = 4
        line_h = 5.5

        self.set_font(self._font, "", 9)
        rendered: list[tuple[str, str, float]] = []
        max_h = 0.0
        label_w = 28
        for label, value in lines:
            val_lines = self.multi_cell(
                self._width() - label_w - pad * 2,
                line_h,
                self._display(value),
                dry_run=True,
                output="LINES",
            )
            h = max(len(val_lines), 1) * line_h
            max_h += h
            rendered.append((label, value, h))

        box_h = max_h + pad * 2
        self.set_fill_color(*_MUTED_BG)
        self.set_draw_color(*_ACCENT)
        self.rect(x0, y0, self._width(), box_h, style="DF")

        y = y0 + pad
        for label, value, row_h in rendered:
            self.set_xy(x0 + pad, y)
            self.set_font(self._font, "B", 8.5)
            self.set_text_color(*_TEXT_MID)
            self.cell(label_w, line_h, self._display(label), new_x="RIGHT")
            self.set_font(self._font, "", 9)
            self.set_text_color(*_TEXT_DARK)
            self.multi_cell(self._width() - label_w - pad * 2, line_h, self._display(value))
            y += row_h

        self.set_y(y0 + box_h + 8)

    def _summary_body(self, text: str) -> None:
        self.set_font(self._font, "B", 11)
        self.set_text_color(*_ACCENT_DARK)
        self.cell(0, 7, "Summary", new_x="LMARGIN", new_y="NEXT")
        self.ln(2)

        self.set_font(self._font, "", 10)
        self.set_text_color(*_TEXT_DARK)
        for block in text.split("\n"):
            paragraph = block.strip()
            if not paragraph:
                continue
            self.multi_cell(self._width(), 5.5, self._display(paragraph))
            self.ln(3)


def _build_pdf(
    *,
    user: User,
    conversation: Conversation,
    summary: ConsultationSummary,
) -> bytes:
    pdf = _ClairConsultationPDF()
    pdf.add_page()

    pdf.set_font(pdf._font, "B", 15)
    pdf.set_text_color(*_TEXT_DARK)
    title = conversation.title.strip() or "Legal consultation"
    pdf.multi_cell(pdf._width(), 7, pdf._display(title))
    pdf.ln(2)

    conv_dt = conversation.updated_at or conversation.created_at
    date_str = conv_dt.strftime("%B %d, %Y at %I:%M %p")
    gen_time = datetime.now().strftime("%B %d, %Y at %I:%M %p")

    pdf.set_font(pdf._font, "", 9)
    pdf.set_text_color(*_TEXT_MID)
    pdf.cell(0, 5, pdf._display(f"Conversation date: {date_str}"), new_x="LMARGIN", new_y="NEXT")
    pdf.ln(6)

    client_line = user.full_name or "Not provided"
    if user.email:
        client_line += f"  ·  {user.email}"
    if user.location:
        client_line += f"  ·  {user.location}"

    pdf._meta_panel(
        [
            ("Client", client_line),
            ("Generated", f"{gen_time} via CLAiR"),
        ]
    )

    pdf._summary_body(summary.body)

    pdf.ln(4)
    pdf.set_font(pdf._font, "", 8)
    pdf.set_text_color(*_TEXT_MID)
    pdf.multi_cell(
        pdf._width(),
        4.5,
        pdf._display(
            "This document summarizes an AI-assisted chat. The attorney should rely on "
            "their own judgment and the full conversation record where needed."
        ),
    )

    buffer = io.BytesIO()
    pdf.output(buffer)
    return buffer.getvalue()


async def generate_appointment_description_summary(messages: list[Message]) -> str:
    if not messages:
        return ""
    short = await _generate_short_summary(messages)
    if short:
        return short
    detailed = await _generate_summary(messages)
    first = detailed.body.split("\n\n")[0].strip()
    return first or detailed.body


async def generate_consultation_pdf(
    user: User,
    conversation: Conversation,
) -> bytes:
    summary = await _generate_summary(conversation.messages)
    return _build_pdf(user=user, conversation=conversation, summary=summary)
