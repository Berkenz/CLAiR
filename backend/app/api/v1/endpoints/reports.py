import logging
import uuid
from html import escape
from typing import Annotated

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.config import settings
from app.models.user import User
from app.schemas.report import (
    ConversationReportRequest,
    ConversationReportResponse,
    UserReportRequest,
    UserReportResponse,
)
from app.services.email_service import send_email
from app.services.lawyer_service import lawyer_service
from app.services.user_service import user_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/reports", tags=["reports"])


# ── helpers ────────────────────────────────────────────────────────────────────

def _user_label(user: User) -> str:
    return (
        f"{user.first_name or ''} {user.last_name or ''}".strip()
        or user.email
        or f"anonymous ({user.id})"
    )


def _build_report_email(
    body: ConversationReportRequest,
    user: User,
) -> tuple[str, str, str]:
    """Return (subject, plain_text, html) for the conversation report email."""
    reporter = _user_label(user)

    subject = f"[CLAiR Report] {body.category}"

    lines = [
        f"Category: {body.category}",
        f"Reporter: {reporter} (id: {user.id})",
    ]
    if body.conversation_id:
        lines.append(f"Conversation ID: {body.conversation_id}")
    if body.reported_message_excerpt:
        lines.append(f"\nReported message excerpt:\n{body.reported_message_excerpt}")
    lines.append(f"\nExplanation:\n{body.explanation}")

    if body.messages:
        lines.append("\n--- Full conversation transcript ---\n")
        for m in body.messages:
            role = "User" if m.role == "user" else "CLAiR"
            lines.append(f"{role}:\n{m.text}\n")

    plain = "\n".join(lines)

    esc = escape
    html_parts = [
        "<h2>Conversation Report</h2>",
        f"<p><strong>Category:</strong> {esc(body.category)}</p>",
        f"<p><strong>Reporter:</strong> {esc(reporter)} (id: {esc(str(user.id))})</p>",
    ]
    if body.conversation_id:
        html_parts.append(
            f"<p><strong>Conversation ID:</strong> {esc(body.conversation_id)}</p>"
        )
    if body.reported_message_excerpt:
        html_parts.append(
            f"<p><strong>Reported excerpt:</strong></p>"
            f"<blockquote style='border-left:3px solid #ccc;padding-left:12px;color:#555'>"
            f"{esc(body.reported_message_excerpt)}</blockquote>"
        )
    html_parts.append(
        f"<p><strong>Explanation:</strong></p><p>{esc(body.explanation)}</p>"
    )

    if body.messages:
        html_parts.append("<hr><h3>Full Conversation Transcript</h3>")
        for m in body.messages:
            role = "User" if m.role == "user" else "CLAiR"
            color = "#1a73e8" if m.role == "user" else "#333"
            html_parts.append(
                f"<p><strong style='color:{color}'>{esc(role)}:</strong></p>"
                f"<p style='white-space:pre-wrap;margin-left:12px'>{esc(m.text)}</p>"
            )

    html = "\n".join(html_parts)
    return subject, plain, html


def _build_user_report_email(
    *,
    reporter: User,
    reporter_role: str,
    reported_user: User,
    reported_role: str,
    reported_display_name: str | None,
    body: UserReportRequest,
) -> tuple[str, str, str]:
    """Return (subject, plain_text, html) for a user-to-user report email."""
    reporter_name = _user_label(reporter)
    reported_name = reported_display_name or _user_label(reported_user)

    subject = f"[CLAiR User Report] {reporter_role} reports {reported_role} — {body.category}"

    lines = [
        f"Report type: {reporter_role} → {reported_role}",
        f"Category: {body.category}",
        "",
        f"Reporter: {reporter_name}",
        f"  Role: {reporter_role}",
        f"  User ID: {reporter.id}",
        f"  Email: {reporter.email or 'N/A'}",
        "",
        f"Reported: {reported_name}",
        f"  Role: {reported_role}",
        f"  User ID: {reported_user.id}",
        f"  Email: {reported_user.email or 'N/A'}",
        "",
        f"Explanation:\n{body.explanation}",
    ]
    plain = "\n".join(lines)

    esc = escape
    html = "\n".join([
        "<h2>User Report</h2>",
        f"<p><strong>Type:</strong> {esc(reporter_role)} reports {esc(reported_role)}</p>",
        f"<p><strong>Category:</strong> {esc(body.category)}</p>",
        "<hr>",
        "<h3>Reporter</h3>",
        f"<p><strong>Name:</strong> {esc(reporter_name)}</p>",
        f"<p><strong>Role:</strong> {esc(reporter_role)}</p>",
        f"<p><strong>User ID:</strong> {esc(str(reporter.id))}</p>",
        f"<p><strong>Email:</strong> {esc(reporter.email or 'N/A')}</p>",
        "<h3>Reported User</h3>",
        f"<p><strong>Name:</strong> {esc(reported_name)}</p>",
        f"<p><strong>Role:</strong> {esc(reported_role)}</p>",
        f"<p><strong>User ID:</strong> {esc(str(reported_user.id))}</p>",
        f"<p><strong>Email:</strong> {esc(reported_user.email or 'N/A')}</p>",
        "<hr>",
        f"<h3>Explanation</h3>",
        f"<p style='white-space:pre-wrap'>{esc(body.explanation)}</p>",
    ])

    return subject, plain, html


# ── endpoints ──────────────────────────────────────────────────────────────────

@router.post("", response_model=ConversationReportResponse)
async def report_conversation(
    body: ConversationReportRequest,
    background_tasks: BackgroundTasks,
    current_user: Annotated[User, Depends(get_current_user)],
):
    subject, plain, html = _build_report_email(body, current_user)

    background_tasks.add_task(
        send_email,
        to=settings.REPORT_RECIPIENT_EMAIL,
        subject=subject,
        body_text=plain,
        body_html=html,
    )

    logger.info(
        "Conversation report queued — category=%s user=%s conv=%s",
        body.category,
        current_user.id,
        body.conversation_id,
    )
    return ConversationReportResponse()


@router.post("/user", response_model=UserReportResponse)
async def report_user(
    body: UserReportRequest,
    background_tasks: BackgroundTasks,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Client reports a lawyer (by profile id) or lawyer reports a client (by user id)."""
    reported_user: User | None = None
    reported_role = "Client"
    reported_display_name: str | None = None

    if body.reported_lawyer_profile_id:
        try:
            profile_uuid = uuid.UUID(body.reported_lawyer_profile_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid lawyer profile ID")

        profile = await lawyer_service.get_profile_by_id(db, profile_uuid)
        if not profile:
            raise HTTPException(status_code=404, detail="Lawyer profile not found")

        reported_user = await user_service.get_user_by_id(db, profile.user_id)
        reported_role = "Lawyer"
        reported_display_name = profile.display_name
    elif body.reported_user_id:
        try:
            user_uuid = uuid.UUID(body.reported_user_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid user ID")

        reported_user = await user_service.get_user_by_id(db, user_uuid)

    if not reported_user:
        raise HTTPException(status_code=404, detail="Reported user not found")

    reporter_has_profile = await lawyer_service.get_profile_by_user_id(
        db, current_user.id
    )
    reporter_role = "Lawyer" if reporter_has_profile else "Client"

    subject, plain, html = _build_user_report_email(
        reporter=current_user,
        reporter_role=reporter_role,
        reported_user=reported_user,
        reported_role=reported_role,
        reported_display_name=reported_display_name,
        body=body,
    )

    background_tasks.add_task(
        send_email,
        to=settings.REPORT_RECIPIENT_EMAIL,
        subject=subject,
        body_text=plain,
        body_html=html,
    )

    logger.info(
        "User report queued — %s(%s) reports %s(%s) category=%s",
        reporter_role,
        current_user.id,
        reported_role,
        reported_user.id,
        body.category,
    )
    return UserReportResponse()
