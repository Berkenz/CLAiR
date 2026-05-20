import { useCallback, useEffect, useRef, useState, type CSSProperties, type FormEvent, type ChangeEvent } from "react";
import { useSearchParams } from "react-router-dom";
import {
  Check, X, RefreshCw, Loader2, Smartphone, CalendarClock,
  FileText, ChevronDown, ChevronUp, WifiOff, Download, Bot, User,
  ThumbsUp, Flag, AlertTriangle, Send, MessageCircle, Info,
  MessageSquare, Search, Pencil, Paperclip, ExternalLink, Plus,
  StickyNote, FolderOpen, CircleCheck,
} from "lucide-react";
import {
  DndContext,
  DragOverlay,
  PointerSensor,
  closestCenter,
  useSensor,
  useSensors,
  type DragEndEvent,
  type DragStartEvent,
} from "@dnd-kit/core";
import {
  SortableContext,
  arrayMove,
  useSortable,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { api } from "@/lib/api";
import { getApiErrorMessage, isApiNetworkError } from "@/lib/api-error";
import { cn } from "@/lib/cn";
import { ChatMarkdown } from "@/components/chat-markdown";
import { useAuth } from "@/features/auth/auth-provider";
import { useRefreshNotificationBadge } from "@/layouts/dashboard-layout";

// ─── Types ────────────────────────────────────────────────────────────────────

interface AppointmentAttachment {
  filename: string;
  url: string | null;
  content_type?: string | null;
}

interface Appointment {
  id: string;
  client_user_id: string | null;
  client_name: string;
  lawyer_photo_url?: string | null;
  client_photo_url?: string | null;
  appointment_date: string;
  appointment_time: string;
  appointment_type: string;
  case_title: string | null;
  description: string | null;
  lawyer_notes: string | null;
  attachments: AppointmentAttachment[];
  status: "pending" | "confirmed" | "cancelled" | "resolved";
  rejection_reason: string | null;
  attached_conversation_id: string | null;
  created_at: string;
  updated_at?: string | null;
  resolved_at?: string | null;
  portal_list_order?: number;
}

/** List/send DMs: confirmed, or resolved but still within 24h after resolve. */
function appointmentDirectMessagingOpen(appt: Appointment): boolean {
  if (appt.status === "confirmed") return true;
  if (appt.status === "resolved") {
    const raw = appt.resolved_at ?? appt.updated_at;
    if (!raw) return false;
    const t = Date.parse(raw);
    if (Number.isNaN(t)) return false;
    return Date.now() < t + 24 * 60 * 60 * 1000;
  }
  return false;
}

interface AssessmentMessage {
  id: string;
  role: string;
  text: string;
  created_at: string;
}

interface FeedbackRow {
  message_id: string;
  feedback_type: string;
  issue_codes: string[] | null;
  comment: string | null;
}

interface SharedBooking {
  appointment_id: string;
  shared_at: string;
  appointment_date: string;
  appointment_time: string;
  appointment_type: string;
  status: string;
  description_preview: string | null;
}

interface ConversationDetail {
  id: string;
  title: string;
  updated_at: string | null;
  client_display_name: string;
  messages: AssessmentMessage[];
  my_feedback: FeedbackRow[];
  shared_bookings: SharedBooking[];
}

interface MsgFeedback {
  messageId: string;
  type: "commend" | "report";
  issues?: string[];
  comment?: string;
}

// ─── Constants ────────────────────────────────────────────────────────────────

type DetailTab = "overview" | "notes" | "documents" | "conversation" | "pdf" | "chat";

const REPORT_ISSUES = [
  { id: "incorrect",    label: "Incorrect information",    desc: "The AI stated legally inaccurate facts" },
  { id: "misleading",   label: "Misleading advice",        desc: "Could lead the client to wrong conclusions" },
  { id: "outdated",     label: "Outdated law cited",        desc: "References repealed or amended legislation" },
  { id: "incomplete",   label: "Incomplete answer",         desc: "Important aspects of the question were omitted" },
  { id: "jurisdiction", label: "Wrong jurisdiction",        desc: "Does not apply to Philippine law or the relevant region" },
  { id: "overconfident",label: "Overly confident tone",     desc: "Presented uncertain information as definitive" },
  { id: "harmful",      label: "Potentially harmful",       desc: "Could cause legal or financial harm if followed" },
  { id: "other",        label: "Other concern",             desc: "Something else not listed above" },
];

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** When the appointment request was created (date + local time). */
function fmtBookedAt(iso: string | null) {
  if (!iso) return "—";
  try {
    const d = new Date(iso);
    const date = d.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
    const time = d.toLocaleTimeString(undefined, { hour: "numeric", minute: "2-digit" });
    return `${date} · ${time}`;
  } catch { return "—"; }
}

function fmtIso(iso: string | null) {
  if (!iso) return "—";
  try { return new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" }); }
  catch { return "—"; }
}

function initials(name: string) {
  return name.trim().split(/\s+/).map((w) => w[0]).join("").slice(0, 2).toUpperCase() || "?";
}

function ProfileAvatar({
  photoUrl,
  name,
  className,
  fallbackBgClass,
}: {
  photoUrl?: string | null;
  name: string;
  className: string;
  fallbackBgClass: string;
}) {
  const [broken, setBroken] = useState(false);
  const url = (photoUrl ?? "").trim();
  if (url && !broken) {
    return (
      <img
        key={url}
        src={url}
        alt=""
        className={cn(className, "rounded-full object-cover shrink-0")}
        onError={() => setBroken(true)}
      />
    );
  }
  return (
    <div
      className={cn(
        className,
        "rounded-full flex items-center justify-center font-bold text-white shrink-0",
        fallbackBgClass,
      )}
    >
      {initials(name)}
    </div>
  );
}

const STATUS_BADGE: Record<string, string> = {
  pending:   "bg-amber-50 text-amber-700 border-amber-200",
  confirmed: "bg-emerald-50 text-emerald-700 border-emerald-200",
  cancelled: "bg-red-50 text-red-600 border-red-200",
  resolved:  "bg-slate-100 text-slate-700 border-slate-200",
};

const AVATAR_BG = ["bg-[#703d57]", "bg-[#957186]", "bg-[#402a2c]", "bg-[#5a3046]", "bg-[#7e5069]"];

function displayCaseTitle(appt: Pick<Appointment, "case_title" | "client_name">): string {
  const t = appt.case_title?.trim();
  if (t) return t;
  return "Untitled case";
}

function normalizeAppointment(a: Appointment): Appointment {
  const po = a.portal_list_order;
  const portal =
    typeof po === "number" && !Number.isNaN(po)
      ? po
      : parseInt(String(po ?? "0"), 10) || 0;
  return {
    ...a,
    attachments: Array.isArray(a.attachments) ? a.attachments : [],
    case_title: a.case_title ?? null,
    lawyer_notes: a.lawyer_notes ?? null,
    description: a.description ?? null,
    portal_list_order: portal,
  };
}

function matchesCaseSearch(appt: Appointment, q: string): boolean {
  if (!q) return true;
  return (
    appt.client_name.toLowerCase().includes(q) ||
    (appt.case_title ?? "").toLowerCase().includes(q) ||
    (appt.lawyer_notes ?? "").toLowerCase().includes(q)
  );
}

type PortalCaseVariant = "pending" | "confirmed" | "resolved" | "cancelled";

function caseCardMetaLine(variant: PortalCaseVariant, appt: Appointment) {
  if (variant === "resolved") {
    return `Resolved · recorded ${fmtBookedAt(appt.updated_at ?? appt.created_at)}`;
  }
  if (variant === "cancelled") {
    return appt.rejection_reason ?? "Rejected";
  }
  return `Booked ${fmtBookedAt(appt.created_at)}`;
}

function CaseDragOverlayCard({
  appt,
  index,
  variant,
}: {
  appt: Appointment;
  index: number;
  variant: PortalCaseVariant;
}) {
  const metaClass =
    variant === "cancelled"
      ? "text-[11px] text-red-500/90 truncate mt-0.5"
      : variant === "resolved"
        ? "text-[11px] text-slate-600/90 mt-0.5"
        : "text-[11px] text-[#957186]/90 mt-0.5";
  return (
    <div
      className={cn(
        "rounded-2xl border p-3.5 bg-white shadow-2xl ring-2 ring-[#703d57]/20 scale-[1.02] will-change-transform",
        variant === "resolved" && "opacity-95",
        variant === "cancelled" && "opacity-90",
      )}
    >
      <div className="flex items-center gap-2.5">
        <ProfileAvatar
          photoUrl={appt.client_photo_url}
          name={appt.client_name}
          className="h-8 w-8 text-xs"
          fallbackBgClass={AVATAR_BG[index % AVATAR_BG.length]}
        />
        <div className="min-w-0 flex-1">
          <div className="flex items-start justify-between gap-2">
            <p className="text-[15px] font-bold text-[#241715] truncate leading-snug min-w-0">{displayCaseTitle(appt)}</p>
            <CaseSourceBadge appt={appt} className="shrink-0 mt-0.5" />
          </div>
          <p className="text-xs text-[#957186] truncate mt-0.5">{appt.client_name}</p>
          <p className={metaClass}>{caseCardMetaLine(variant, appt)}</p>
        </div>
        {variant === "pending" && (
          <span className="text-[10px] font-semibold bg-amber-50 text-amber-700 border border-amber-200 px-2 py-0.5 rounded-full shrink-0">
            pending
          </span>
        )}
      </div>
      {variant !== "cancelled" && (
        <div className="flex flex-wrap items-center gap-1.5 mt-1.5 pl-10">
          <span className="text-[11px] text-gray-500">{appt.appointment_type}</span>
        </div>
      )}
    </div>
  );
}

function SortablePortalCaseRow({
  appt,
  index,
  variant,
  selected,
  dragDisabled,
  onSelect,
  onAccept,
  openReject,
  acceptingId,
  unreadCount,
}: {
  appt: Appointment;
  index: number;
  variant: PortalCaseVariant;
  selected: boolean;
  dragDisabled: boolean;
  onSelect: () => void;
  onAccept?: (a: Appointment) => void;
  openReject?: (a: Appointment) => void;
  acceptingId: string | null;
  unreadCount?: number;
}) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({
    id: appt.id,
    disabled: dragDisabled,
  });
  const style: CSSProperties = {
    transform: transform != null ? CSS.Transform.toString(transform) : undefined,
    transition: transition ?? "transform 220ms cubic-bezier(0.2, 0, 0, 1)",
    opacity: isDragging ? 0.4 : 1,
  };

  const outer = cn(
    "rounded-2xl border overflow-hidden transition-[box-shadow,opacity] duration-200",
    variant === "resolved" && "opacity-90",
    variant === "cancelled" && "opacity-60",
    selected
      ? "border-[#703d57] bg-[#f7f0f4] shadow-sm"
      : "border-[#d9b8c4]/40 bg-white hover:border-[#703d57]/40 hover:bg-[#f7f0f4]",
    variant === "resolved" && selected && "opacity-100",
    variant === "cancelled" && selected && "opacity-100",
  );

  const metaClass =
    variant === "cancelled"
      ? "text-[11px] text-red-500/90 truncate mt-0.5"
      : variant === "resolved"
        ? "text-[11px] text-slate-600/90 mt-0.5"
        : "text-[11px] text-[#957186]/90 mt-0.5";

  const mainBlock = (
    <>
      <div className="flex items-center gap-2.5">
        <ProfileAvatar
          photoUrl={appt.client_photo_url}
          name={appt.client_name}
          className="h-8 w-8 text-xs"
          fallbackBgClass={AVATAR_BG[index % AVATAR_BG.length]}
        />
        <div className="min-w-0 flex-1">
          <div className="flex items-start justify-between gap-2">
            <p className="text-[15px] font-bold text-[#241715] truncate leading-snug min-w-0">{displayCaseTitle(appt)}</p>
            <div className="flex items-center gap-1.5 shrink-0">
              {!!unreadCount && unreadCount > 0 && (
                <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-red-500 px-1.5 text-[10px] font-bold text-white">
                  {unreadCount > 99 ? "99+" : unreadCount}
                </span>
              )}
              <CaseSourceBadge appt={appt} className="mt-0.5" />
            </div>
          </div>
          <p className="text-xs text-[#957186] truncate mt-0.5">{appt.client_name}</p>
          <p className={metaClass}>{caseCardMetaLine(variant, appt)}</p>
        </div>
        {variant === "pending" && (
          <span className="text-[10px] font-semibold bg-amber-50 text-amber-700 border border-amber-200 px-2 py-0.5 rounded-full shrink-0">
            pending
          </span>
        )}
      </div>
      {variant !== "cancelled" && (
        <div className="flex flex-wrap items-center gap-1.5 mt-1.5 pl-10">
          <span className="text-[11px] text-gray-500">{appt.appointment_type}</span>
        </div>
      )}
    </>
  );

  return (
    <div ref={setNodeRef} style={style} className={outer}>
      {variant === "pending" ? (
        <>
          <div
            className={cn(!dragDisabled && "cursor-grab active:cursor-grabbing touch-none")}
            {...(!dragDisabled ? { ...attributes, ...listeners } : {})}
          >
            <button type="button" onClick={onSelect} className="w-full text-left p-3.5 transition-all bg-transparent">
              {mainBlock}
            </button>
          </div>
          <div className="flex gap-2 mt-0 px-3.5 pb-3.5 pl-10">
            <button
              type="button"
              onClick={() => onAccept?.(appt)}
              disabled={acceptingId === appt.id}
              className="flex-1 flex items-center justify-center gap-1 py-1.5 rounded-lg bg-emerald-600 text-[11px] font-semibold text-white hover:bg-emerald-700 disabled:opacity-60 transition"
            >
              {acceptingId === appt.id ? <Loader2 className="h-3 w-3 animate-spin" /> : <Check className="h-3 w-3" />}
              Accept
            </button>
            <button
              type="button"
              onClick={() => openReject?.(appt)}
              disabled={acceptingId === appt.id}
              className="flex-1 flex items-center justify-center gap-1 py-1.5 rounded-lg border border-red-200 text-[11px] font-semibold text-red-600 hover:bg-red-50 disabled:opacity-60 transition"
            >
              <X className="h-3 w-3" />
              Reject
            </button>
          </div>
        </>
      ) : (
        <div
          className={cn(!dragDisabled && "cursor-grab active:cursor-grabbing touch-none")}
          {...(!dragDisabled ? { ...attributes, ...listeners } : {})}
        >
          <button type="button" onClick={onSelect} className="w-full text-left p-3.5 transition-all bg-transparent">
            {mainBlock}
          </button>
        </div>
      )}
    </div>
  );
}

function PortalCaseSectionDnd({
  items,
  reorderDisabled,
  selectedId,
  onReorder,
  onSelect,
  variant,
  onAccept,
  openReject,
  acceptingId,
  unreadByAppt,
}: {
  items: Appointment[];
  reorderDisabled: boolean;
  selectedId: string | null;
  onReorder: (ordered: Appointment[]) => void | Promise<void>;
  onSelect: (a: Appointment) => void;
  variant: PortalCaseVariant;
  onAccept?: (a: Appointment) => void;
  openReject?: (a: Appointment) => void;
  acceptingId: string | null;
  unreadByAppt?: Record<string, number>;
}) {
  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: { distance: 6 },
    }),
  );
  const [activeId, setActiveId] = useState<string | null>(null);
  const activeAppt = activeId ? items.find((x) => x.id === activeId) : undefined;
  const activeIndex = activeAppt ? items.findIndex((x) => x.id === activeAppt.id) : 0;

  const dragDisabled = reorderDisabled || items.length < 2;

  function handleDragStart(e: DragStartEvent) {
    setActiveId(String(e.active.id));
  }

  function handleDragEnd(e: DragEndEvent) {
    setActiveId(null);
    if (dragDisabled) return;
    const { active, over } = e;
    if (!over || active.id === over.id) return;
    const oldIndex = items.findIndex((x) => x.id === active.id);
    const newIndex = items.findIndex((x) => x.id === over.id);
    if (oldIndex < 0 || newIndex < 0) return;
    void onReorder(arrayMove(items, oldIndex, newIndex));
  }

  function handleDragCancel() {
    setActiveId(null);
  }

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCenter}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
      onDragCancel={handleDragCancel}
    >
      <SortableContext items={items.map((x) => x.id)} strategy={verticalListSortingStrategy}>
        <div className="space-y-2">
          {items.map((a, i) => (
            <SortablePortalCaseRow
              key={a.id}
              appt={a}
              index={i}
              variant={variant}
              selected={selectedId === a.id}
              dragDisabled={dragDisabled}
              onSelect={() => onSelect(a)}
              onAccept={onAccept}
              openReject={openReject}
              acceptingId={acceptingId}
              unreadCount={unreadByAppt?.[a.id] ?? 0}
            />
          ))}
        </div>
      </SortableContext>
      <DragOverlay dropAnimation={{ duration: 220, easing: "cubic-bezier(0.2, 0, 0, 1)" }}>
        {activeAppt ? (
          <div className="pointer-events-none w-[min(100%,22rem)]">
            <CaseDragOverlayCard appt={activeAppt} index={activeIndex >= 0 ? activeIndex : 0} variant={variant} />
          </div>
        ) : null}
      </DragOverlay>
    </DndContext>
  );
}

function portalThenDateAsc(a: Appointment, b: Appointment): number {
  const ao = a.portal_list_order ?? 0;
  const bo = b.portal_list_order ?? 0;
  if (ao !== bo) return ao - bo;
  const dc = a.appointment_date.localeCompare(b.appointment_date);
  if (dc !== 0) return dc;
  return (a.appointment_time ?? "").localeCompare(b.appointment_time ?? "");
}

function portalThenDateDesc(a: Appointment, b: Appointment): number {
  const ao = a.portal_list_order ?? 0;
  const bo = b.portal_list_order ?? 0;
  if (ao !== bo) return ao - bo;
  const dc = b.appointment_date.localeCompare(a.appointment_date);
  if (dc !== 0) return dc;
  return (b.appointment_time ?? "").localeCompare(a.appointment_time ?? "");
}

function isManualCase(appt: Pick<Appointment, "client_user_id">): boolean {
  return !isFromClairAppClient(appt as Appointment);
}

/** Linked CLAiR mobile user — app booking. Otherwise lawyer-entered / portal-only. */
function isFromClairAppClient(appt: Appointment): boolean {
  return Boolean((appt.client_user_id ?? "").trim());
}

function CaseSourceBadge({ appt, className }: { appt: Appointment; className?: string }) {
  const fromApp = isFromClairAppClient(appt);
  if (fromApp) {
    return (
      <span
        className={cn(
          "inline-flex items-center gap-0.5 rounded-md border border-violet-200 bg-violet-50 px-1.5 py-0.5 text-[10px] font-semibold text-violet-800",
          className,
        )}
        title="Client booked through the CLAiR mobile app"
      >
        <Smartphone className="h-3 w-3 shrink-0" aria-hidden />
        CLAiR app
      </span>
    );
  }
  return (
    <span
      className={cn(
        "inline-flex items-center gap-0.5 rounded-md border border-slate-200 bg-slate-100 px-1.5 py-0.5 text-[10px] font-semibold text-slate-700",
        className,
      )}
      title="Recorded manually from the lawyer portal (no linked app user)"
    >
      <Pencil className="h-3 w-3 shrink-0" aria-hidden />
      Manual
    </span>
  );
}

function AddCaseModal({
  open,
  onClose,
  onCreated,
}: {
  open: boolean;
  onClose: () => void;
  onCreated: (a: Appointment) => void;
}) {
  const [types, setTypes] = useState<string[]>([]);
  const [typesError, setTypesError] = useState<string | null>(null);
  const [clientName, setClientName] = useState("");
  const [caseTitle, setCaseTitle] = useState("");
  const [appointmentDate, setAppointmentDate] = useState("");
  const [appointmentTime, setAppointmentTime] = useState("09:00");
  const [appointmentType, setAppointmentType] = useState("");
  const [description, setDescription] = useState("");
  const [creating, setCreating] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setClientName("");
    setCaseTitle("");
    setDescription("");
    setAppointmentDate(new Date().toISOString().slice(0, 10));
    setAppointmentTime("09:00");
    setAppointmentType("");
    setFormError(null);
    setTypesError(null);
    let cancelled = false;
    (async () => {
      try {
        const { data } = await api.get<string[]>("/lawyer/appointments/types");
        if (!cancelled) {
          setTypes(Array.isArray(data) ? data : []);
          if (data?.length) setAppointmentType((t) => (t && data.includes(t) ? t : data[0]));
        }
      } catch (err: unknown) {
        if (!cancelled) {
          setTypes([]);
          setTypesError(getApiErrorMessage(err, "Could not load appointment types."));
        }
      }
    })();
    return () => { cancelled = true; };
  }, [open]);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    const name = clientName.trim();
    if (!name) { setFormError("Client name is required."); return; }
    if (!appointmentDate) { setFormError("Choose an appointment date."); return; }
    if (!appointmentTime || !/^\d{1,2}:\d{2}$/.test(appointmentTime)) {
      setFormError("Time must be in HH:MM format.");
      return;
    }
    const [th, tm] = appointmentTime.split(":");
    const timeNormalized = `${String(parseInt(th, 10)).padStart(2, "0")}:${String(parseInt(tm, 10)).padStart(2, "0")}`;
    if (!appointmentType) { setFormError("Select an appointment type."); return; }

    setCreating(true);
    setFormError(null);
    try {
      const { data } = await api.post<Appointment>("/lawyer/appointments", {
        client_name: name,
        appointment_date: appointmentDate,
        appointment_time: timeNormalized,
        appointment_type: appointmentType,
        case_title: caseTitle.trim() || null,
        description: description.trim() || null,
      });
      onCreated({
        ...data,
        attachments: Array.isArray(data.attachments) ? data.attachments : [],
        case_title: data.case_title ?? null,
      });
      onClose();
    } catch (err: unknown) {
      setFormError(getApiErrorMessage(err, "Could not create case."));
    } finally {
      setCreating(false);
    }
  }

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-lg max-h-[90vh] overflow-y-auto rounded-2xl bg-white shadow-xl">
        <form onSubmit={(e) => void handleSubmit(e)} className="p-6">
          <div className="flex items-start justify-between gap-3 mb-5">
            <div>
              <h2 className="font-bold text-[#241715] text-lg">Add case</h2>
              <p className="text-sm text-[#957186] mt-0.5">
                Record a matter that did not come from the CLAiR app. It appears as an active case immediately.
              </p>
            </div>
            <button type="button" onClick={onClose} className="p-1 rounded-lg text-gray-400 hover:text-gray-700 shrink-0">
              <X className="h-5 w-5" />
            </button>
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-1.5">Client name *</label>
              <input
                required
                className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                placeholder="e.g. Maria Santos"
                value={clientName}
                onChange={(e) => setClientName(e.target.value)}
                autoFocus
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-1.5">Case title <span className="normal-case font-normal text-[#957186]">(optional)</span></label>
              <input
                className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                placeholder="Short label for your list"
                value={caseTitle}
                onChange={(e) => setCaseTitle(e.target.value)}
                maxLength={500}
              />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-1.5">Date *</label>
                <input
                  type="date"
                  required
                  className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                  value={appointmentDate}
                  onChange={(e) => setAppointmentDate(e.target.value)}
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-1.5">Time *</label>
                <input
                  type="time"
                  required
                  step={60}
                  className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                  value={appointmentTime}
                  onChange={(e) => setAppointmentTime(e.target.value)}
                />
              </div>
            </div>
            <div>
              <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-1.5">Appointment type *</label>
              <select
                required
                className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] bg-white focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                value={appointmentType}
                onChange={(e) => setAppointmentType(e.target.value)}
                disabled={types.length === 0}
              >
                {types.length === 0 ? (
                  <option value="">Loading types…</option>
                ) : (
                  types.map((t) => (
                    <option key={t} value={t}>{t}</option>
                  ))
                )}
              </select>
              {typesError && <p className="mt-1.5 text-xs text-amber-800">{typesError}</p>}
            </div>
            <div>
              <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-1.5">Notes <span className="normal-case font-normal text-[#957186]">(optional)</span></label>
              <textarea
                rows={3}
                className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30 resize-none"
                placeholder="Internal notes or matter summary"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
              />
            </div>
          </div>

          {formError && (
            <p className="mt-4 text-xs text-red-700 bg-red-50 border border-red-200 rounded-xl px-3 py-2">{formError}</p>
          )}

          <div className="flex gap-3 mt-6">
            <button type="button" onClick={onClose} className="flex-1 rounded-xl border border-[#d9b8c4]/60 py-2.5 text-sm font-semibold text-[#402a2c] hover:bg-[#f7f0f4] transition">
              Cancel
            </button>
            <button
              type="submit"
              disabled={creating || types.length === 0}
              className="flex-1 rounded-xl bg-[#703d57] py-2.5 text-sm font-semibold text-white hover:bg-[#5a3046] disabled:opacity-60 flex items-center justify-center gap-2 transition"
            >
              {creating ? <Loader2 className="h-4 w-4 animate-spin" /> : <Plus className="h-4 w-4" />}
              Create case
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// ─── Main Page ────────────────────────────────────────────────────────────────

export function CasesPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [backendDown, setBackendDown] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);

  const [accepting, setAccepting] = useState<string | null>(null);
  const [rejectTarget, setRejectTarget] = useState<Appointment | null>(null);
  const [rejectReason, setRejectReason] = useState("");
  const [rejecting, setRejecting] = useState(false);
  const [rejectError, setRejectError] = useState<string | null>(null);

  const [selected, setSelected] = useState<Appointment | null>(null);
  const [pendingDetailTab, setPendingDetailTab] = useState<DetailTab | null>(null);
  const [search, setSearch] = useState("");
  const [pendingCollapsed, setPendingCollapsed] = useState(false);
  const [resolvedCollapsed, setResolvedCollapsed] = useState(true);
  const [closedCollapsed, setClosedCollapsed] = useState(true);
  const [addCaseOpen, setAddCaseOpen] = useState(false);
  const [reorderSaving, setReorderSaving] = useState(false);

  const [unreadByAppt, setUnreadByAppt] = useState<Record<string, number>>({});
  const [chatUnreadByAppt, setChatUnreadByAppt] = useState<Record<string, number>>({});

  const fetchUnreadByAppt = useCallback(async () => {
    try {
      const { data } = await api.get<{ notifications: { is_read: boolean; notification_type: string; payload: Record<string, unknown> | null }[] }>("/lawyer/notifications");
      const map: Record<string, number> = {};
      const chatMap: Record<string, number> = {};
      for (const n of data.notifications) {
        if (n.is_read) continue;
        const apptId = n.payload?.appointment_id;
        if (typeof apptId === "string") {
          map[apptId] = (map[apptId] ?? 0) + 1;
          if (n.notification_type === "new_direct_message") {
            chatMap[apptId] = (chatMap[apptId] ?? 0) + 1;
          }
        }
      }
      setUnreadByAppt(map);
      setChatUnreadByAppt(chatMap);
    } catch { /* silent */ }
  }, []);

  const fetchAppointments = useCallback(async (opts?: { silent?: boolean }) => {
    const silent = opts?.silent === true;
    if (!silent) {
      setLoading(true);
      setBackendDown(false);
      setLoadError(null);
    }
    try {
      const { data } = await api.get<{ appointments: Appointment[] }>("/lawyer/appointments");
      setAppointments(
        data.appointments.map((a) =>
          normalizeAppointment({
            ...(a as Appointment),
            attachments: Array.isArray(a.attachments) ? a.attachments : [],
          }),
        ),
      );
    } catch (err: unknown) {
      if (!silent) {
        if (isApiNetworkError(err)) setBackendDown(true);
        else setLoadError(getApiErrorMessage(err, "Could not load appointments."));
      }
    } finally {
      if (!silent) setLoading(false);
    }
  }, []);

  useEffect(() => { fetchAppointments(); fetchUnreadByAppt(); }, [fetchAppointments, fetchUnreadByAppt]);

  useEffect(() => {
    const interval = setInterval(() => void fetchUnreadByAppt(), 30_000);
    return () => clearInterval(interval);
  }, [fetchUnreadByAppt]);

  const refreshBadge = useRefreshNotificationBadge();

  const markChatReadForAppt = useCallback(async (appointmentId: string) => {
    try {
      const { data } = await api.get<{ notifications: { id: string; is_read: boolean; notification_type: string; payload: Record<string, unknown> | null }[] }>("/lawyer/notifications");
      const toMark = data.notifications.filter(
        (n) => !n.is_read && n.notification_type === "new_direct_message" && n.payload?.appointment_id === appointmentId,
      );
      await Promise.all(toMark.map((n) => api.patch(`/lawyer/notifications/${n.id}/read`)));
      void fetchUnreadByAppt();
      refreshBadge();
    } catch { /* silent */ }
  }, [fetchUnreadByAppt, refreshBadge]);

  // Deep-link: auto-select appointment from ?appt=<id>&tab=<tab> (e.g. from notifications)
  useEffect(() => {
    const apptId = searchParams.get("appt");
    const tab = searchParams.get("tab") as DetailTab | null;
    if (!apptId || appointments.length === 0) return;
    const match = appointments.find((a) => a.id === apptId);
    if (match) {
      setSelected(match);
      if (tab) setPendingDetailTab(tab);
      setSearchParams({}, { replace: true });
    }
  }, [appointments, searchParams, setSearchParams]);

  // Keep selected in sync after re-fetch
  useEffect(() => {
    if (selected) {
      const updated = appointments.find((a) => a.id === selected.id);
      if (updated) setSelected(updated);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [appointments]);

  async function handleAccept(appt: Appointment) {
    setAccepting(appt.id);
    try {
      const { data } = await api.post<Appointment>(`/lawyer/appointments/${appt.id}/accept`);
      const n = normalizeAppointment(data);
      setAppointments((prev) => prev.map((a) => a.id === appt.id ? n : a));
      setSelected(n);
    } catch {
      // silent — user can retry
    } finally {
      setAccepting(null);
    }
  }

  function openReject(appt: Appointment) {
    setRejectTarget(appt);
    setRejectReason("");
    setRejectError(null);
  }

  async function handleReject() {
    if (!rejectTarget || !rejectReason.trim()) { setRejectError("Please provide a reason."); return; }
    setRejecting(true);
    setRejectError(null);
    try {
      const { data } = await api.post<Appointment>(`/lawyer/appointments/${rejectTarget.id}/reject`, { reason: rejectReason.trim() });
      const n = normalizeAppointment(data);
      setAppointments((prev) => prev.map((a) => a.id === rejectTarget.id ? n : a));
      if (selected?.id === rejectTarget.id) setSelected(n);
      setRejectTarget(null);
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { detail?: string } } })?.response?.data?.detail;
      setRejectError(msg ?? "Failed to reject. Please try again.");
    } finally {
      setRejecting(false);
    }
  }

  const persistPortalOrder = useCallback(async (ordered: Appointment[]) => {
    setReorderSaving(true);
    setLoadError(null);
    try {
      await api.put("/lawyer/appointments/portal-order", {
        appointment_ids: ordered.map((a) => a.id),
      });
      setAppointments((prev) => {
        const pos = new Map(ordered.map((a, i) => [a.id, i]));
        return prev.map((row) => {
          const p = pos.get(row.id);
          if (p === undefined) return row;
          return { ...row, portal_list_order: p };
        });
      });
    } catch (err: unknown) {
      setLoadError(getApiErrorMessage(err, "Could not save case order."));
    } finally {
      setReorderSaving(false);
    }
  }, []);

  const q = search.toLowerCase();
  const canReorderCases = !search.trim() && !reorderSaving;

  const pending   = appointments.filter((a) => a.status === "pending"   && matchesCaseSearch(a, q))
    .sort(portalThenDateAsc);
  const confirmed = appointments.filter((a) => a.status === "confirmed" && matchesCaseSearch(a, q))
    .sort(portalThenDateAsc);
  const resolvedList = appointments.filter((a) => a.status === "resolved" && matchesCaseSearch(a, q))
    .sort(portalThenDateDesc);
  const cancelled = appointments.filter((a) => a.status === "cancelled" && matchesCaseSearch(a, q))
    .sort(portalThenDateDesc);

  function handleApptUpdated(next: Appointment) {
    const normalized = normalizeAppointment(next);
    setAppointments((prev) => prev.map((a) => (a.id === normalized.id ? normalized : a)));
    setSelected(normalized);
  }

  function handleCaseCreated(created: Appointment) {
    const normalized = normalizeAppointment(created);
    setAppointments((prev) => [normalized, ...prev]);
    setSelected(normalized);
  }

  if (loading) return (
    <div className="py-32 flex items-center justify-center gap-2 text-[#957186]">
      <Loader2 className="h-5 w-5 animate-spin" />
      <span className="text-sm">Loading cases…</span>
    </div>
  );

  if (backendDown) return (
    <div className="py-32 flex flex-col items-center justify-center gap-4 text-center">
      <div className="h-16 w-16 rounded-2xl bg-[#f7f0f4] border border-[#d9b8c4]/40 flex items-center justify-center">
        <WifiOff className="h-7 w-7 text-[#957186]" />
      </div>
      <p className="text-sm font-semibold text-[#241715]">Backend not reachable</p>
      <button onClick={() => void fetchAppointments()} className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#703d57] text-sm font-semibold text-white hover:bg-[#5a3046] transition">
        <RefreshCw className="h-4 w-4" />Try again
      </button>
    </div>
  );

  return (
    <div className="flex gap-5 max-w-7xl mx-auto h-[calc(100vh-8rem)] min-h-0">

      {/* ── Left panel: list ── */}
      <div className="w-full min-w-0 sm:w-[22rem] shrink-0 flex flex-col min-h-0 sm:border-r sm:border-[#e8d4dc]/60 sm:pr-3">

        <div className="shrink-0 space-y-3 pb-3 border-b border-[#e8d4dc]/50 mb-3">
          <div className="flex items-start justify-between gap-2 pt-1">
            <div className="min-w-0">
              <h1 className="text-xl font-bold text-[#241715] tracking-tight">Cases</h1>
              <p className="text-xs text-[#957186] mt-0.5">{pending.length} pending · {confirmed.length} active · {resolvedList.length} resolved</p>
            </div>
            <div className="flex items-center gap-1 shrink-0">
              <button
                type="button"
                onClick={() => setAddCaseOpen(true)}
                className="flex items-center gap-1 rounded-xl bg-[#703d57] px-2.5 py-2 text-xs font-semibold text-white shadow-sm hover:bg-[#5a3046] transition"
                title="Add a case manually"
              >
                <Plus className="h-3.5 w-3.5" />
                <span>Add case</span>
              </button>
              <button type="button" onClick={() => void fetchAppointments()} className="p-2 rounded-xl border border-[#d9b8c4]/60 text-[#703d57] hover:bg-[#f7f0f4] transition" title="Refresh">
                <RefreshCw className="h-4 w-4" />
              </button>
            </div>
          </div>

          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-gray-400" />
            <input
              className="w-full rounded-xl border border-[#d9b8c4]/60 bg-white pl-8 pr-3 py-2 text-sm text-[#241715] placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
              placeholder="Search by client or case title…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
          {!search.trim() && (
            <p className="text-[10px] text-[#957186] px-0.5 leading-snug">
              Drag a case card to reorder within each section. Reorder is hidden while searching.
            </p>
          )}
          {reorderSaving && (
            <p className="text-[10px] text-[#703d57] font-semibold px-0.5 flex items-center gap-1">
              <Loader2 className="h-3 w-3 animate-spin shrink-0" aria-hidden />
              Saving order…
            </p>
          )}

          {loadError && (
            <div className="rounded-xl border border-amber-200 bg-amber-50 px-3 py-2.5 text-xs text-amber-900">{loadError}</div>
          )}
        </div>

        <div className="flex-1 min-h-0 overflow-y-auto space-y-5 pr-0.5">
        <div>
          <button
            onClick={() => setPendingCollapsed((v) => !v)}
            className="flex items-center gap-2 w-full mb-2 group"
          >
            <span className="text-xs font-bold text-[#241715] uppercase tracking-wide">Pending Requests</span>
            {pending.length > 0 && (
              <span className="rounded-full bg-amber-100 text-amber-700 text-[10px] font-bold px-1.5 py-0.5">{pending.length}</span>
            )}
            <span className="ml-auto text-gray-400">{pendingCollapsed ? <ChevronDown className="h-3.5 w-3.5" /> : <ChevronUp className="h-3.5 w-3.5" />}</span>
          </button>
          {!pendingCollapsed && (
            <div>
              {pending.length === 0 ? (
                <p className="text-xs text-gray-400 px-1 py-3">No pending requests.</p>
              ) : (
                <PortalCaseSectionDnd
                  items={pending}
                  reorderDisabled={!canReorderCases || !!accepting}
                  selectedId={selected?.id ?? null}
                  onReorder={persistPortalOrder}
                  onSelect={setSelected}
                  variant="pending"
                  onAccept={handleAccept}
                  openReject={openReject}
                  acceptingId={accepting}
                  unreadByAppt={unreadByAppt}
                />
              )}
            </div>
          )}
        </div>

        {/* Active Cases */}
        <div>
          <p className="text-xs font-bold text-[#241715] uppercase tracking-wide mb-2">
            Active Cases
            {confirmed.length > 0 && (
              <span className="ml-2 rounded-full bg-emerald-100 text-emerald-700 text-[10px] font-bold px-1.5 py-0.5">{confirmed.length}</span>
            )}
          </p>
          {confirmed.length === 0 ? (
              <div className="rounded-2xl border border-dashed border-[#d9b8c4]/80 bg-[#fdf9fb]/80 px-3 py-4 text-xs text-[#957186] leading-relaxed">
                <p>No active cases yet.</p>
                <p className="mt-2">
                  <button
                    type="button"
                    onClick={() => setAddCaseOpen(true)}
                    className="font-semibold text-[#703d57] hover:underline"
                  >
                    Add a case
                  </button>
                  {" "}manually, or accept a pending request from the list above.
                </p>
              </div>
            ) : (
              <PortalCaseSectionDnd
                items={confirmed}
                reorderDisabled={!canReorderCases}
                selectedId={selected?.id ?? null}
                onReorder={persistPortalOrder}
                onSelect={setSelected}
                variant="confirmed"
                acceptingId={accepting}
                unreadByAppt={unreadByAppt}
              />
            )}
        </div>

        {/* Resolved (manual cases) */}
        {resolvedList.length > 0 && (
          <div>
            <button
              type="button"
              onClick={() => setResolvedCollapsed((v) => !v)}
              className="flex items-center gap-2 w-full mb-2"
            >
              <span className="text-xs font-bold text-[#241715] uppercase tracking-wide">Resolved</span>
              <span className="rounded-full bg-slate-100 text-slate-700 text-[10px] font-bold px-1.5 py-0.5">{resolvedList.length}</span>
              <span className="ml-auto text-gray-400">{resolvedCollapsed ? <ChevronDown className="h-3.5 w-3.5" /> : <ChevronUp className="h-3.5 w-3.5" />}</span>
            </button>
            {!resolvedCollapsed && (
              <PortalCaseSectionDnd
                items={resolvedList}
                reorderDisabled={!canReorderCases}
                selectedId={selected?.id ?? null}
                onReorder={persistPortalOrder}
                onSelect={setSelected}
                variant="resolved"
                acceptingId={accepting}
                unreadByAppt={unreadByAppt}
              />
            )}
          </div>
        )}

        {/* Closed */}
        {cancelled.length > 0 && (
          <div>
            <button onClick={() => setClosedCollapsed((v) => !v)} className="flex items-center gap-2 w-full mb-2">
              <span className="text-xs font-bold text-[#241715] uppercase tracking-wide">Rejected</span>
              <span className="rounded-full bg-red-100 text-red-600 text-[10px] font-bold px-1.5 py-0.5">{cancelled.length}</span>
              <span className="ml-auto text-gray-400">{closedCollapsed ? <ChevronDown className="h-3.5 w-3.5" /> : <ChevronUp className="h-3.5 w-3.5" />}</span>
            </button>
            {!closedCollapsed && (
              <PortalCaseSectionDnd
                items={cancelled}
                reorderDisabled={!canReorderCases}
                selectedId={selected?.id ?? null}
                onReorder={persistPortalOrder}
                onSelect={setSelected}
                variant="cancelled"
                acceptingId={accepting}
                unreadByAppt={unreadByAppt}
              />
            )}
          </div>
        )}
        </div>
      </div>

      {/* ── Right panel: case detail ── */}
      <div className="flex-1 min-w-0 flex flex-col min-h-0">
        {selected ? (
          <CaseDetail
            appt={selected}
            onAccept={() => handleAccept(selected)}
            accepting={accepting === selected.id}
            onReject={() => openReject(selected)}
            onApptUpdated={handleApptUpdated}
            initialTab={pendingDetailTab}
            onInitialTabConsumed={() => setPendingDetailTab(null)}
            chatUnreadCount={chatUnreadByAppt[selected.id] ?? 0}
            onChatOpened={() => {
              markChatReadForAppt(selected.id);
              void fetchAppointments({ silent: true });
            }}
          />
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center text-center rounded-2xl border border-[#d9b8c4]/40 bg-white">
            <div className="h-16 w-16 rounded-2xl bg-[#f7f0f4] border border-[#d9b8c4]/40 flex items-center justify-center mb-4">
              <FileText className="h-7 w-7 text-[#957186]" />
            </div>
            <p className="text-sm font-semibold text-[#241715]">Select a case</p>
            <p className="text-xs text-[#957186] mt-1 max-w-xs">
              Choose a pending request or active case from the list, or use{" "}
              <button type="button" onClick={() => setAddCaseOpen(true)} className="font-semibold text-[#703d57] hover:underline">
                Add case
              </button>
              {" "}to record a matter manually.
            </p>
          </div>
        )}
      </div>

      <AddCaseModal open={addCaseOpen} onClose={() => setAddCaseOpen(false)} onCreated={handleCaseCreated} />

      {/* Reject modal */}
      {rejectTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-2xl bg-white shadow-xl p-6">
            <div className="flex items-start justify-between mb-4">
              <div>
                <h2 className="font-bold text-[#241715] text-lg">Reject Appointment</h2>
                <p className="text-sm text-[#957186] mt-0.5">{rejectTarget.client_name} · Booked {fmtBookedAt(rejectTarget.created_at)}</p>
              </div>
              <button onClick={() => setRejectTarget(null)} className="p-1 rounded-lg text-gray-400 hover:text-gray-700">
                <X className="h-5 w-5" />
              </button>
            </div>
            <label className="block text-xs font-semibold text-[#703d57] mb-1.5">
              <FileText className="h-3 w-3 inline mr-1" />Reason *
            </label>
            <textarea
              rows={3}
              autoFocus
              className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30 resize-none"
              placeholder="e.g. Schedule conflict, please book another date…"
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
            />
            {rejectError && <p className="mt-2 text-xs text-red-600 bg-red-50 border border-red-200 rounded-lg px-3 py-2">{rejectError}</p>}
            <div className="flex gap-3 mt-4">
              <button onClick={() => setRejectTarget(null)} className="flex-1 rounded-xl border border-[#d9b8c4]/60 py-2.5 text-sm font-semibold text-[#402a2c] hover:bg-[#f7f0f4] transition">Cancel</button>
              <button onClick={handleReject} disabled={rejecting} className="flex-1 rounded-xl bg-red-600 py-2.5 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-60 flex items-center justify-center gap-2 transition">
                {rejecting && <Loader2 className="h-4 w-4 animate-spin" />}Reject
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Case Detail Panel ────────────────────────────────────────────────────────

const USER_REPORT_CATEGORIES = [
  "Inappropriate Behavior",
  "Harassment or Threats",
  "Fraudulent Activity",
  "No-Show or Abandonment",
  "Privacy Violation",
  "Other",
] as const;

function CaseDetail({ appt, onAccept, accepting, onReject, onApptUpdated, initialTab, onInitialTabConsumed, chatUnreadCount, onChatOpened }: {
  appt: Appointment;
  onAccept: () => void;
  accepting: boolean;
  onReject: () => void;
  onApptUpdated: (a: Appointment) => void;
  initialTab?: DetailTab | null;
  onInitialTabConsumed?: () => void;
  chatUnreadCount?: number;
  onChatOpened?: () => void;
}) {
  const manual = isManualCase(appt);
  const [tab, setTab] = useState<DetailTab>(initialTab ?? "overview");
  const [resolveBusy, setResolveBusy] = useState(false);

  // ── Report client state ──────────────────────────────────────────────────
  const [showReportClient, setShowReportClient] = useState(false);
  const [rptCategory, setRptCategory] = useState<string>(USER_REPORT_CATEGORIES[0]);
  const [rptExplanation, setRptExplanation] = useState("");
  const [rptSubmitting, setRptSubmitting] = useState(false);
  const [rptError, setRptError] = useState<string | null>(null);
  const [rptSuccess, setRptSuccess] = useState(false);

  async function submitClientReport(e: FormEvent) {
    e.preventDefault();
    if (rptExplanation.trim().length < 12) {
      setRptError("Please provide at least 12 characters of explanation.");
      return;
    }
    setRptSubmitting(true);
    setRptError(null);
    try {
      const body: Record<string, string> = {
        category: rptCategory,
        explanation: appt.client_user_id
          ? rptExplanation.trim()
          : `[Client: ${appt.client_name}] ${rptExplanation.trim()}`,
      };
      if (appt.client_user_id) {
        body.reported_user_id = appt.client_user_id;
      } else {
        body.reported_user_id = "00000000-0000-0000-0000-000000000000";
      }
      await api.post("/reports/user", body);
      setRptSuccess(true);
      setTimeout(() => {
        setShowReportClient(false);
        setRptSuccess(false);
        setRptExplanation("");
        setRptCategory(USER_REPORT_CATEGORIES[0]);
      }, 1800);
    } catch (err) {
      setRptError(getApiErrorMessage(err, "Failed to submit report."));
    } finally {
      setRptSubmitting(false);
    }
  }

  useEffect(() => {
    if (initialTab) {
      setTab(initialTab);
      onInitialTabConsumed?.();
      if (initialTab === "chat") onChatOpened?.();
    } else {
      setTab("overview");
    }
  }, [appt.id]); // eslint-disable-line react-hooks/exhaustive-deps

  const tabs: { key: DetailTab; label: string; icon: React.ReactNode }[] = manual
    ? [
        { key: "overview", label: "Overview", icon: <Info className="h-3.5 w-3.5" /> },
        { key: "notes", label: "Notes", icon: <StickyNote className="h-3.5 w-3.5" /> },
        { key: "documents", label: "Documents", icon: <FolderOpen className="h-3.5 w-3.5" /> },
      ]
    : [
        { key: "overview", label: "Overview", icon: <Info className="h-3.5 w-3.5" /> },
        { key: "conversation", label: "CLAiR Chat", icon: <Bot className="h-3.5 w-3.5" /> },
        { key: "pdf", label: "PDF Summary", icon: <Download className="h-3.5 w-3.5" /> },
        { key: "chat", label: "Client Chat", icon: <MessageCircle className="h-3.5 w-3.5" /> },
      ];

  async function resolveCase() {
    if (resolveBusy || appt.status !== "confirmed") return;
    setResolveBusy(true);
    try {
      const { data } = await api.put<Appointment>(`/lawyer/appointments/${appt.id}`, { status: "resolved" });
      onApptUpdated(data);
    } catch {
      /* user can retry */
    } finally {
      setResolveBusy(false);
    }
  }

  async function reopenCase() {
    if (resolveBusy || appt.status !== "resolved") return;
    setResolveBusy(true);
    try {
      const { data } = await api.put<Appointment>(`/lawyer/appointments/${appt.id}`, { status: "confirmed" });
      onApptUpdated(data);
    } catch {
      /* user can retry */
    } finally {
      setResolveBusy(false);
    }
  }

  return (
    <div className="flex flex-col h-full rounded-2xl border border-[#d9b8c4]/40 bg-white overflow-hidden">
      {/* Case header */}
      <div className="px-6 py-4 border-b border-[#d9b8c4]/30 bg-[#f7f0f4] shrink-0">
        <div className="flex items-start justify-between gap-4">
          <div className="flex items-center gap-3 min-w-0">
            <ProfileAvatar
              photoUrl={appt.client_photo_url}
              name={appt.client_name}
              className="h-10 w-10 text-sm"
              fallbackBgClass="bg-[#703d57]"
            />
            <div className="min-w-0">
              <p className="text-[11px] font-semibold uppercase tracking-wide text-[#957186]">Case</p>
              <p className="font-bold text-[#241715] truncate text-lg leading-tight">{displayCaseTitle(appt)}</p>
              <p className="text-sm text-[#703d57] font-medium truncate mt-0.5">{appt.client_name}</p>
              <div className="flex items-center gap-2 mt-1.5 flex-wrap">
                <CaseSourceBadge appt={appt} />
                <span className="text-[#d9b8c4] select-none" aria-hidden>·</span>
                <span className="flex items-center gap-1 text-xs text-[#957186]">
                  <CalendarClock className="h-3 w-3 shrink-0" />
                  <span>Booked {fmtBookedAt(appt.created_at)}</span>
                </span>
              </div>
            </div>
          </div>
          <div className="flex flex-col items-end gap-2 shrink-0">
            <div className="flex items-center gap-2 flex-wrap justify-end">
              <span className={`text-xs font-semibold px-2.5 py-1 rounded-full border capitalize ${STATUS_BADGE[appt.status] ?? "bg-gray-100 text-gray-600 border-gray-200"}`}>
                {appt.status}
              </span>
              {appt.status === "pending" && (
                <div className="flex gap-1.5">
                  <button type="button" onClick={onAccept} disabled={accepting} className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-emerald-600 text-xs font-semibold text-white hover:bg-emerald-700 disabled:opacity-60 transition">
                    {accepting ? <Loader2 className="h-3 w-3 animate-spin" /> : <Check className="h-3 w-3" />}Accept
                  </button>
                  <button type="button" onClick={onReject} disabled={accepting} className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-red-200 text-xs font-semibold text-red-600 hover:bg-red-50 disabled:opacity-60 transition">
                    <X className="h-3 w-3" />Reject
                  </button>
                </div>
              )}
              {appt.status === "confirmed" && (
                <button
                  type="button"
                  onClick={() => void resolveCase()}
                  disabled={resolveBusy}
                  className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-slate-300 bg-white text-xs font-semibold text-slate-800 hover:bg-slate-50 disabled:opacity-60 transition"
                >
                  {resolveBusy ? <Loader2 className="h-3 w-3 animate-spin" /> : <CircleCheck className="h-3 w-3" />}
                  Resolve case
                </button>
              )}
              {appt.status === "resolved" && (
                <button
                  type="button"
                  onClick={() => void reopenCase()}
                  disabled={resolveBusy}
                  className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-[#703d57] text-xs font-semibold text-white hover:bg-[#5a3046] disabled:opacity-60 transition"
                >
                  {resolveBusy ? <Loader2 className="h-3 w-3 animate-spin" /> : <RefreshCw className="h-3 w-3" />}
                  Reopen case
                </button>
              )}
              <button
                type="button"
                onClick={() => setShowReportClient(true)}
                className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-red-200 text-xs font-semibold text-red-600 hover:bg-red-50 transition"
              >
                <Flag className="h-3 w-3" />
                Report client
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-0 border-b border-[#d9b8c4]/40 shrink-0 px-4 bg-white overflow-x-auto">
        {tabs.map((t) => (
          <button
            key={t.key}
            type="button"
            onClick={() => { setTab(t.key); if (t.key === "chat") onChatOpened?.(); }}
            className={cn(
              "flex items-center gap-1.5 px-4 py-2.5 text-xs font-medium border-b-2 -mb-px transition-colors shrink-0",
              tab === t.key
                ? "border-[#703d57] text-[#703d57]"
                : "border-transparent text-[#957186] hover:text-[#703d57]",
            )}
          >
            {t.icon}{t.label}
            {t.key === "chat" && !!chatUnreadCount && chatUnreadCount > 0 && (
              <span className="ml-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-red-500 px-1 text-[9px] font-bold text-white">
                {chatUnreadCount > 99 ? "99+" : chatUnreadCount}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Tab content */}
      <div className="flex-1 overflow-y-auto min-h-0">
        {tab === "overview" && <OverviewTab appt={appt} onApptUpdated={onApptUpdated} />}
        {manual && tab === "notes" && <ManualCaseNotesTab appt={appt} onApptUpdated={onApptUpdated} />}
        {manual && tab === "documents" && <ManualCaseDocumentsTab appt={appt} onApptUpdated={onApptUpdated} />}
        {!manual && tab === "conversation" && <ConversationTab appt={appt} />}
        {!manual && tab === "pdf" && <PdfTab appt={appt} />}
        {!manual && tab === "chat" && <ClientChatTab appt={appt} />}
      </div>

      {/* Report client modal */}
      {showReportClient && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl">
            <div className="flex items-center justify-between mb-4">
              <h2 className="font-bold text-[#241715] text-base">Report Client</h2>
              <button type="button" onClick={() => { setShowReportClient(false); setRptError(null); setRptSuccess(false); }} className="text-[#957186] hover:text-[#703d57]">
                <X className="h-5 w-5" />
              </button>
            </div>
            {rptSuccess ? (
              <p className="text-emerald-600 font-semibold text-sm text-center py-4">Report submitted successfully.</p>
            ) : (
              <form onSubmit={(e) => void submitClientReport(e)} className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-[#703d57] mb-1">Category</label>
                  <select
                    className="w-full rounded-lg border border-[#d9b8c4]/60 px-3 py-2 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                    value={rptCategory}
                    onChange={(e: ChangeEvent<HTMLSelectElement>) => setRptCategory(e.target.value)}
                  >
                    {USER_REPORT_CATEGORIES.map((c) => (
                      <option key={c} value={c}>{c}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold text-[#703d57] mb-1">Explanation</label>
                  <textarea
                    className="w-full rounded-lg border border-[#d9b8c4]/60 px-3 py-2 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30 min-h-[100px] resize-y"
                    placeholder="Describe the issue (min. 12 characters)…"
                    value={rptExplanation}
                    onChange={(e: ChangeEvent<HTMLTextAreaElement>) => setRptExplanation(e.target.value)}
                    required
                  />
                </div>
                {rptError && <p className="text-red-600 text-xs">{rptError}</p>}
                <button
                  type="submit"
                  disabled={rptSubmitting}
                  className="w-full py-2.5 rounded-xl bg-[#703d57] text-white text-sm font-semibold hover:bg-[#5a3046] disabled:opacity-60 transition flex items-center justify-center gap-2"
                >
                  {rptSubmitting && <Loader2 className="h-4 w-4 animate-spin" />}
                  {rptSubmitting ? "Submitting…" : "Submit Report"}
                </button>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Tab: Notes (manual cases) ───────────────────────────────────────────────

function ManualCaseNotesTab({ appt, onApptUpdated }: { appt: Appointment; onApptUpdated: (a: Appointment) => void }) {
  const readOnly = appt.status === "resolved";
  const [draft, setDraft] = useState(appt.lawyer_notes ?? "");
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    setDraft(appt.lawyer_notes ?? "");
    setErr(null);
  }, [appt.id, appt.lawyer_notes]);

  async function save() {
    if (readOnly) return;
    setSaving(true);
    setErr(null);
    try {
      const { data } = await api.put<Appointment>(`/lawyer/appointments/${appt.id}`, {
        lawyer_notes: draft.trim() ? draft.trim() : null,
      });
      onApptUpdated(data);
    } catch (e: unknown) {
      setErr(getApiErrorMessage(e, "Could not save notes."));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="p-6 max-w-3xl">
      <p className="text-sm text-[#957186] mb-4 leading-relaxed">
        Private notes for this manual case. They stay in the lawyer portal and are not shared with CLAiR mobile clients.
      </p>
      <textarea
        className="w-full min-h-[220px] rounded-xl border border-[#d9b8c4]/60 px-4 py-3 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30 resize-y disabled:bg-[#f7f0f4] disabled:text-[#957186]"
        placeholder="Matter summary, next steps, contact notes…"
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        disabled={readOnly}
      />
      {readOnly && (
        <p className="mt-2 text-xs text-[#957186]">This case is resolved. Use <span className="font-semibold text-[#703d57]">Reopen case</span> in the header to edit notes again.</p>
      )}
      {!readOnly && (
        <div className="flex items-center gap-3 mt-4">
          <button
            type="button"
            onClick={() => void save()}
            disabled={saving}
            className="inline-flex items-center gap-2 rounded-xl bg-[#703d57] px-4 py-2.5 text-sm font-semibold text-white hover:bg-[#5a3046] disabled:opacity-60 transition"
          >
            {saving && <Loader2 className="h-4 w-4 animate-spin" />}
            Save notes
          </button>
        </div>
      )}
      {err && <p className="mt-3 text-xs text-red-700 bg-red-50 border border-red-200 rounded-xl px-3 py-2">{err}</p>}
    </div>
  );
}

// ─── Tab: Documents (manual cases) ───────────────────────────────────────────

function ManualCaseDocumentsTab({ appt, onApptUpdated }: { appt: Appointment; onApptUpdated: (a: Appointment) => void }) {
  const readOnly = appt.status === "resolved";
  const [uploading, setUploading] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);
  const atts = appt.attachments ?? [];

  async function onPickFile(e: ChangeEvent<HTMLInputElement>) {
    const f = e.target.files?.[0];
    e.target.value = "";
    if (!f || readOnly) return;
    setUploading(true);
    setErr(null);
    const fd = new FormData();
    fd.append("file", f, f.name);
    try {
      const { data } = await api.post<Appointment>(
        `/lawyer/appointments/${appt.id}/case-documents`,
        fd,
      );
      onApptUpdated(data);
    } catch (ex: unknown) {
      setErr(getApiErrorMessage(ex, "Upload failed."));
    } finally {
      setUploading(false);
    }
  }

  return (
    <div className="p-6 max-w-3xl">
      <p className="text-sm text-[#957186] mb-4 leading-relaxed">
        Files you attach here are stored for this case only (manual matters). Allowed types match client booking uploads (PDF, Word, common images).
      </p>
      {!readOnly && (
        <div className="mb-5">
          <input ref={fileRef} type="file" accept=".pdf,.doc,.docx,.jpg,.jpeg,.png,.gif,.webp" className="hidden" onChange={(e) => void onPickFile(e)} />
          <button
            type="button"
            onClick={() => fileRef.current?.click()}
            disabled={uploading}
            className="inline-flex items-center gap-2 rounded-xl border border-[#d9b8c4]/80 bg-white px-4 py-2.5 text-sm font-semibold text-[#703d57] hover:bg-[#f7f0f4] disabled:opacity-60 transition"
          >
            {uploading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Paperclip className="h-4 w-4" />}
            Upload document
          </button>
        </div>
      )}
      {readOnly && (
        <p className="mb-4 text-xs text-[#957186]">Resolved cases are view-only. Reopen the case to add more files.</p>
      )}
      {err && <p className="mb-4 text-xs text-red-700 bg-red-50 border border-red-200 rounded-xl px-3 py-2">{err}</p>}
      {atts.length === 0 ? (
        <div className="rounded-xl border border-dashed border-[#d9b8c4]/80 bg-[#fdf9fb]/80 px-4 py-8 text-center text-sm text-[#957186]">
          No documents yet.
        </div>
      ) : (
        <ul className="rounded-xl border border-[#d9b8c4]/40 bg-white divide-y divide-[#f0e4ea]">
          {atts.map((att, idx) => (
            <li key={`${att.filename}-${idx}`} className="flex items-center justify-between gap-3 px-4 py-3">
              <span className="text-sm text-[#241715] truncate min-w-0" title={att.filename}>
                {att.filename}
              </span>
              {att.url ? (
                <a
                  href={att.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="shrink-0 flex items-center gap-1 text-xs font-semibold text-[#703d57] hover:underline"
                >
                  <ExternalLink className="h-3.5 w-3.5" />
                  Open
                </a>
              ) : (
                <span className="shrink-0 text-[11px] text-amber-700 bg-amber-50 border border-amber-200 rounded-lg px-2 py-1">
                  No download link
                </span>
              )}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

// ─── Tab: Overview ────────────────────────────────────────────────────────────

function OverviewTab({ appt, onApptUpdated }: { appt: Appointment; onApptUpdated: (a: Appointment) => void }) {
  const [editingTitle, setEditingTitle] = useState(false);
  const [titleDraft, setTitleDraft] = useState(appt.case_title ?? "");
  const [savingTitle, setSavingTitle] = useState(false);
  const [titleError, setTitleError] = useState<string | null>(null);

  useEffect(() => {
    setTitleDraft(appt.case_title ?? "");
    setEditingTitle(false);
    setTitleError(null);
  }, [appt.id, appt.case_title]);

  async function saveCaseTitle() {
    const trimmed = titleDraft.trim();
    if (!trimmed) {
      setTitleError("Case title cannot be empty.");
      return;
    }
    setSavingTitle(true);
    setTitleError(null);
    try {
      const { data } = await api.put<Appointment>(`/lawyer/appointments/${appt.id}`, {
        case_title: trimmed,
      });
      onApptUpdated(data);
      setEditingTitle(false);
    } catch (err: unknown) {
      setTitleError(getApiErrorMessage(err, "Could not save case title."));
    } finally {
      setSavingTitle(false);
    }
  }

  const manual = isManualCase(appt);
  const titleLocked = manual && appt.status === "resolved";

  return (
    <div className="p-6 space-y-5">
      {/* Case title (lawyer can rename) */}
      <div>
        <div className="flex items-center justify-between gap-2 mb-2">
          <p className="text-xs font-semibold text-[#5a3046] uppercase tracking-wide">Case title</p>
          {!titleLocked && !editingTitle ? (
            <button
              type="button"
              onClick={() => { setEditingTitle(true); setTitleDraft(appt.case_title ?? ""); setTitleError(null); }}
              className="flex items-center gap-1 text-xs font-medium text-[#703d57] hover:underline"
            >
              <Pencil className="h-3 w-3" />
              Rename
            </button>
          ) : null}
        </div>
        {editingTitle ? (
          <div className="space-y-2">
            <input
              className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
              value={titleDraft}
              onChange={(e) => setTitleDraft(e.target.value)}
              placeholder="Case / matter title"
              maxLength={500}
            />
            {titleError && <p className="text-xs text-red-600">{titleError}</p>}
            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => { setEditingTitle(false); setTitleDraft(appt.case_title ?? ""); setTitleError(null); }}
                className="px-3 py-1.5 rounded-lg border border-[#d9b8c4] text-xs font-semibold text-[#957186] hover:bg-[#f7f0f4]"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={savingTitle}
                onClick={() => void saveCaseTitle()}
                className="px-3 py-1.5 rounded-lg bg-[#703d57] text-xs font-semibold text-white hover:bg-[#5a3046] disabled:opacity-60 flex items-center gap-1"
              >
                {savingTitle && <Loader2 className="h-3 w-3 animate-spin" />}
                Save title
              </button>
            </div>
          </div>
        ) : (
          <div className="rounded-xl border border-[#d9b8c4]/40 bg-[#f7f0f4] px-4 py-3 text-sm font-semibold text-[#241715]">
            {displayCaseTitle(appt)}
          </div>
        )}
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="col-span-2">
          <InfoBlock label="Client source" value={isFromClairAppClient(appt) ? "CLAiR mobile app" : "Manual (lawyer portal)"} />
        </div>
        <InfoBlock label="Appointment Type"  value={appt.appointment_type} />
        <InfoBlock label="Status"             value={appt.status.charAt(0).toUpperCase() + appt.status.slice(1)} />
        <InfoBlock label="Booked"             value={fmtBookedAt(appt.created_at)} />
        <InfoBlock label="Client"             value={appt.client_name} />
      </div>

      <div>
        <p className="text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-2">
          {manual ? "Initial notes (from intake)" : "Description"}
        </p>
        {appt.description?.trim() ? (
          <div className="rounded-xl border border-[#d9b8c4]/40 bg-[#f7f0f4] px-4 py-3 text-sm text-[#241715] leading-relaxed whitespace-pre-wrap">
            {appt.description}
          </div>
        ) : (
          <div className="rounded-xl border border-[#d9b8c4]/40 bg-[#f7f0f4] px-4 py-3 text-sm text-[#957186]">
            {manual ? "No intake notes were added when this case was created." : "No description provided."}
          </div>
        )}
      </div>

      {!manual && (
      <div>
        <p className="text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-2 flex items-center gap-1.5">
          <Paperclip className="h-3.5 w-3.5" />
          Uploaded documents
        </p>
        {(appt.attachments ?? []).length === 0 ? (
          <div className="rounded-xl border border-[#d9b8c4]/40 bg-white px-4 py-3 text-sm text-[#957186]">
            No files attached to this request.
          </div>
        ) : (
          <ul className="rounded-xl border border-[#d9b8c4]/40 bg-white divide-y divide-[#f0e4ea]">
            {(appt.attachments ?? []).map((att, idx) => (
              <li key={`${att.filename}-${idx}`} className="flex items-center justify-between gap-3 px-4 py-3">
                <span className="text-sm text-[#241715] truncate min-w-0" title={att.filename}>
                  {att.filename}
                </span>
                {att.url ? (
                  <a
                    href={att.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="shrink-0 flex items-center gap-1 text-xs font-semibold text-[#703d57] hover:underline"
                  >
                    <ExternalLink className="h-3.5 w-3.5" />
                    Open
                  </a>
                ) : (
                  <span className="shrink-0 text-[11px] text-amber-700 bg-amber-50 border border-amber-200 rounded-lg px-2 py-1">
                    No download link
                  </span>
                )}
              </li>
            ))}
          </ul>
        )}
        {(appt.attachments ?? []).some((a) => !a.url) && (
          <p className="mt-2 text-[11px] text-[#957186] leading-relaxed">
            Older requests may list filenames only. New bookings upload files to storage when Supabase is configured.
          </p>
        )}
      </div>
      )}

      {manual && (
        <div className="rounded-xl border border-[#d9b8c4]/40 bg-[#f7f0f4] px-4 py-3 text-xs text-[#957186] leading-relaxed">
          Use the <span className="font-semibold text-[#703d57]">Documents</span> tab to upload files for this manual case.
        </div>
      )}

      {appt.status === "cancelled" && appt.rejection_reason && (
        <div>
          <p className="text-xs font-semibold text-red-600 uppercase tracking-wide mb-2">Rejection Reason</p>
          <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {appt.rejection_reason}
          </div>
        </div>
      )}

      {!manual && !appt.attached_conversation_id && (
        <div className="rounded-xl border border-[#d9b8c4]/40 bg-white px-4 py-3 text-xs text-[#957186]">
          No CLAiR conversation was attached to this appointment.
        </div>
      )}
    </div>
  );
}

function InfoBlock({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-[10px] font-semibold text-[#957186] uppercase tracking-wide mb-0.5">{label}</p>
      <p className="text-sm font-medium text-[#241715]">{value}</p>
    </div>
  );
}

// ─── Tab: CLAiR Conversation ──────────────────────────────────────────────────

function ConversationTab({ appt }: { appt: Appointment }) {
  const [detail, setDetail] = useState<ConversationDetail | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [feedbacks, setFeedbacks] = useState<Record<string, MsgFeedback>>({});
  const [reportTarget, setReportTarget] = useState<string | null>(null);
  const [selectedIssues, setSelectedIssues] = useState<string[]>([]);
  const [comment, setComment] = useState("");
  const [feedbackBusy, setFeedbackBusy] = useState(false);
  const [feedbackBanner, setFeedbackBanner] = useState("");
  const [submitted, setSubmitted] = useState<string | null>(null);

  useEffect(() => {
    if (!appt.attached_conversation_id) return;
    let cancelled = false;
    setLoading(true);
    setError("");
    setDetail(null);
    setFeedbacks({});
    (async () => {
      try {
        const { data } = await api.get<ConversationDetail>(
          `/lawyer/ai-assessment/client-conversations/${appt.attached_conversation_id}`
        );
        if (!cancelled) {
          setDetail(data);
          const m: Record<string, MsgFeedback> = {};
          for (const r of data.my_feedback) {
            m[r.message_id] = { messageId: r.message_id, type: r.feedback_type === "commend" ? "commend" : "report", issues: r.issue_codes ?? undefined, comment: r.comment ?? undefined };
          }
          setFeedbacks(m);
        }
      } catch (err) {
        if (!cancelled) setError(getApiErrorMessage(err, "Could not load conversation."));
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => { cancelled = true; };
  }, [appt.attached_conversation_id]);

  function openReport(id: string) { setReportTarget(id); setSelectedIssues([]); setComment(""); setFeedbackBanner(""); }
  function toggleIssue(id: string) { setSelectedIssues((p) => p.includes(id) ? p.filter((i) => i !== id) : [...p, id]); }

  async function submitCommend(messageId: string) {
    if (feedbackBusy) return;
    setFeedbackBusy(true);
    try {
      await api.post("/lawyer/ai-assessment/message-feedback", { message_id: messageId, feedback_type: "commend", issue_codes: [] });
      setFeedbacks((p) => ({ ...p, [messageId]: { messageId, type: "commend" } }));
      setSubmitted(messageId); setTimeout(() => setSubmitted(null), 2500);
    } catch (err) { setFeedbackBanner(getApiErrorMessage(err, "Could not commend.")); }
    finally { setFeedbackBusy(false); }
  }

  async function submitReport() {
    if (!reportTarget || selectedIssues.length === 0 || feedbackBusy) return;
    setFeedbackBusy(true);
    try {
      await api.post("/lawyer/ai-assessment/message-feedback", { message_id: reportTarget, feedback_type: "report", issue_codes: selectedIssues, comment: comment.trim() || undefined });
      setFeedbacks((p) => ({ ...p, [reportTarget]: { messageId: reportTarget, type: "report", issues: selectedIssues, comment: comment.trim() || undefined } }));
      setSubmitted(reportTarget); setTimeout(() => setSubmitted(null), 2500);
      setReportTarget(null);
    } catch (err) { setFeedbackBanner(getApiErrorMessage(err, "Could not submit report.")); }
    finally { setFeedbackBusy(false); }
  }

  if (!appt.attached_conversation_id) return (
    <div className="flex flex-col items-center justify-center h-full py-16 text-center px-8">
      <MessageSquare className="h-10 w-10 text-[#d9b8c4] mb-3" />
      <p className="text-sm font-semibold text-[#241715]">No conversation attached</p>
      <p className="text-xs text-[#957186] mt-1">The client did not attach a CLAiR conversation with this appointment request.</p>
    </div>
  );

  if (loading) return <div className="flex items-center justify-center py-16 text-sm text-[#957186]"><Loader2 className="h-4 w-4 animate-spin mr-2" />Loading conversation…</div>;
  if (error)   return <div className="p-6 text-sm text-red-600 bg-red-50 rounded-xl m-4">{error}</div>;
  if (!detail) return null;

  const msgs = [...detail.messages].sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());

  return (
    <div className="flex flex-col h-full">
      {feedbackBanner && <div className="px-4 py-2 text-xs text-red-700 bg-red-50 border-b border-red-100">{feedbackBanner}</div>}

      {/* Conversation header */}
      <div className="px-5 py-3 border-b border-[#d9b8c4]/30 bg-[#f7f0f4] shrink-0">
        <p className="text-sm font-bold text-[#241715]">{detail.title}</p>
        <p className="text-xs text-[#957186]">{msgs.length} messages · {fmtIso(detail.updated_at)}</p>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-5 space-y-4 min-h-0">
        {msgs.map((msg) => {
          const isAI = msg.role === "model" || msg.role === "assistant";
          const fb = feedbacks[msg.id];
          return (
            <div key={msg.id}>
              <div className={cn("flex gap-3", !isAI && "justify-end")}>
                {isAI && (
                  <div className="h-7 w-7 rounded-full bg-[#703d57] flex items-center justify-center shrink-0 mt-0.5">
                    <Bot className="h-3.5 w-3.5 text-white" />
                  </div>
                )}
                <div className={cn(
                  "max-w-[78%] rounded-2xl px-4 py-3 text-sm leading-relaxed",
                  isAI ? "bg-[#f7f0f4] text-[#241715] rounded-tl-sm" : "bg-[#703d57] text-white rounded-tr-sm whitespace-pre-wrap"
                )}>
                  {isAI ? <ChatMarkdown content={msg.text} /> : msg.text}
                </div>
                {!isAI && (
                  <div className="h-7 w-7 rounded-full bg-[#957186] flex items-center justify-center shrink-0 mt-0.5">
                    <User className="h-3.5 w-3.5 text-white" />
                  </div>
                )}
              </div>

              {isAI && (
                <div className="ml-10 mt-1.5 flex items-center gap-2 flex-wrap">
                  {fb?.type === "commend" ? (
                    <span className="flex items-center gap-1 text-xs text-emerald-600 font-medium"><Check className="h-3 w-3" />Commended</span>
                  ) : fb?.type === "report" ? (
                    <span className="flex items-center gap-1 text-xs text-red-500 font-medium"><Flag className="h-3 w-3" />Reported</span>
                  ) : (
                    <>
                      <button type="button" disabled={feedbackBusy} onClick={() => void submitCommend(msg.id)} className="flex items-center gap-1 px-2.5 py-1 rounded-lg border border-emerald-200 bg-emerald-50 text-[11px] font-medium text-emerald-700 hover:bg-emerald-100 disabled:opacity-50 transition">
                        <ThumbsUp className="h-3 w-3" />Commend
                      </button>
                      <button type="button" disabled={feedbackBusy} onClick={() => openReport(msg.id)} className="flex items-center gap-1 px-2.5 py-1 rounded-lg border border-red-200 bg-red-50 text-[11px] font-medium text-red-600 hover:bg-red-100 disabled:opacity-50 transition">
                        <Flag className="h-3 w-3" />Report
                      </button>
                    </>
                  )}
                  {submitted === msg.id && <span className="text-[11px] text-[#957186] animate-pulse">Saved ✓</span>}
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Report modal */}
      {reportTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-lg rounded-2xl bg-white shadow-2xl">
            <div className="flex items-start justify-between p-6 border-b border-[#d9b8c4]/30">
              <div className="flex items-center gap-3">
                <div className="h-9 w-9 rounded-xl bg-red-100 flex items-center justify-center">
                  <AlertTriangle className="h-5 w-5 text-red-600" />
                </div>
                <div>
                  <h2 className="font-bold text-[#241715]">Report AI Response</h2>
                  <p className="text-xs text-[#957186] mt-0.5">Logged for your QA records</p>
                </div>
              </div>
              <button onClick={() => setReportTarget(null)} className="p-1 rounded-lg text-gray-400 hover:text-gray-600 transition">
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <p className="text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-2">What's wrong? <span className="text-red-500">*</span></p>
              <div className="space-y-2">
                {REPORT_ISSUES.map((issue) => {
                  const checked = selectedIssues.includes(issue.id);
                  return (
                    <button key={issue.id} type="button" onClick={() => toggleIssue(issue.id)}
                      className={cn("w-full flex items-start gap-3 p-3 rounded-xl border text-left transition-all",
                        checked ? "border-red-300 bg-red-50" : "border-[#d9b8c4]/40 hover:border-[#703d57]/30 hover:bg-[#f7f0f4]"
                      )}>
                      <div className={cn("h-4 w-4 rounded border-2 flex items-center justify-center shrink-0 mt-0.5 transition-colors", checked ? "bg-red-500 border-red-500" : "border-[#d9b8c4]")}>
                        {checked && <Check className="h-2.5 w-2.5 text-white" />}
                      </div>
                      <div>
                        <p className="text-sm font-medium text-[#241715]">{issue.label}</p>
                        <p className="text-xs text-[#957186] mt-0.5">{issue.desc}</p>
                      </div>
                    </button>
                  );
                })}
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-1.5">Comments <span className="normal-case font-normal text-[#c490aa]">(optional)</span></label>
                <textarea rows={3} value={comment} onChange={(e) => setComment(e.target.value)} placeholder="Describe the specific error…" className="w-full rounded-xl border border-[#d9b8c4] bg-[#fdf9fb] px-3.5 py-2.5 text-sm text-[#241715] placeholder-[#c490aa] outline-none focus:border-[#703d57] resize-none" />
              </div>
            </div>
            <div className="flex gap-3 px-6 pb-6">
              <button onClick={() => setReportTarget(null)} className="flex-1 py-2.5 rounded-xl border border-[#d9b8c4] text-sm font-semibold text-[#957186] hover:bg-[#f7f0f4] transition">Cancel</button>
              <button onClick={() => void submitReport()} disabled={selectedIssues.length === 0 || feedbackBusy} className="flex-1 py-2.5 rounded-xl bg-red-600 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-50 flex items-center justify-center gap-2 transition">
                <Flag className="h-4 w-4" />Send report
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Tab: PDF Summary ─────────────────────────────────────────────────────────

function PdfTab({ appt }: { appt: Appointment }) {
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  useEffect(() => {
    if (!appt.attached_conversation_id) return;

    let active = true;
    let objectUrl: string | null = null;

    async function parseBlobError(data: Blob): Promise<string | undefined> {
      try {
        const t = await data.text();
        const j = JSON.parse(t) as { detail?: unknown };
        if (typeof j.detail === "string") return j.detail;
      } catch {
        /* ignore */
      }
      return undefined;
    }

    async function loadPdf() {
      setLoading(true);
      setError(null);
      setPreviewUrl(null);
      try {
        const response = await api.get<Blob>(`/lawyer/appointments/${appt.id}/pdf`, {
          responseType: "blob",
        });
        const raw = response.data;
        if (!(raw instanceof Blob) || raw.size === 0) {
          if (active) setError("Empty PDF response from server.");
          return;
        }
        const mime = raw.type || "";
        if (mime.includes("json") || mime.includes("text")) {
          const detail = await parseBlobError(raw);
          if (active) setError(detail ?? "Could not generate PDF.");
          return;
        }
        const blob = new Blob([raw], { type: "application/pdf" });
        objectUrl = URL.createObjectURL(blob);
        if (!active) {
          URL.revokeObjectURL(objectUrl);
          objectUrl = null;
          return;
        }
        setPreviewUrl(objectUrl);
      } catch (err: unknown) {
        if (!active) return;
        let msg = getApiErrorMessage(err, "Could not load PDF.");
        const ax = err as { response?: { data?: Blob } };
        if (ax.response?.data instanceof Blob && ax.response.data.size < 4096) {
          const detail = await parseBlobError(ax.response.data);
          if (detail) msg = detail;
        }
        setError(msg);
      } finally {
        if (active) setLoading(false);
      }
    }

    void loadPdf();
    return () => {
      active = false;
      if (objectUrl) URL.revokeObjectURL(objectUrl);
      setPreviewUrl(null);
    };
  }, [appt.id, appt.attached_conversation_id, refreshKey]);

  if (!appt.attached_conversation_id) {
    return (
      <div className="flex flex-col items-center justify-center h-full py-16 text-center px-8">
        <Download className="h-10 w-10 text-[#d9b8c4] mb-3" />
        <p className="text-sm font-semibold text-[#241715]">No PDF available</p>
        <p className="text-xs text-[#957186] mt-1">
          A PDF is generated from the attached CLAiR conversation. No conversation was attached to this appointment.
        </p>
      </div>
    );
  }

  const safeFileStem = appt.client_name.replace(/\s+/g, "_").replace(/[^a-zA-Z0-9_-]/g, "") || "Consultation";

  return (
    <div className="flex flex-col h-full min-h-0">
      <div className="shrink-0 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 px-4 py-3 border-b border-[#d9b8c4]/40 bg-[#f7f0f4]">
        <p className="text-xs text-[#957186] leading-relaxed max-w-xl">
          Preview is generated on demand (AI). For reference only — not legal advice.
        </p>
        <div className="flex items-center gap-2 shrink-0">
          <button
            type="button"
            onClick={() => setRefreshKey((k) => k + 1)}
            disabled={loading}
            className="inline-flex items-center gap-1.5 rounded-xl border border-[#d9b8c4]/80 bg-white px-3 py-2 text-xs font-semibold text-[#703d57] hover:bg-[#f7f0f4] disabled:opacity-50 transition"
          >
            <RefreshCw className={cn("h-3.5 w-3.5", loading && "animate-spin")} />
            Refresh
          </button>
          {previewUrl ? (
            <a
              href={previewUrl}
              download={`CLAiR_Consultation_${safeFileStem}.pdf`}
              className="inline-flex items-center gap-1.5 rounded-xl bg-[#703d57] px-3 py-2 text-xs font-semibold text-white hover:bg-[#5a3046] transition"
            >
              <Download className="h-3.5 w-3.5" />
              Download
            </a>
          ) : null}
        </div>
      </div>

      <div className="flex-1 min-h-0 flex flex-col p-4">
        {loading && (
          <div className="flex flex-1 flex-col items-center justify-center gap-2 text-[#957186] py-16">
            <Loader2 className="h-8 w-8 animate-spin" />
            <span className="text-sm">Generating PDF preview…</span>
          </div>
        )}
        {!loading && error && (
          <div className="flex flex-1 flex-col items-center justify-center px-6">
            <p className="text-sm text-red-600 text-center max-w-md bg-red-50 border border-red-200 rounded-xl px-4 py-3">{error}</p>
            <button
              type="button"
              onClick={() => setRefreshKey((k) => k + 1)}
              className="mt-4 text-xs font-semibold text-[#703d57] underline"
            >
              Try again
            </button>
          </div>
        )}
        {!loading && !error && previewUrl && (
          <iframe
            title="CLAiR consultation summary PDF"
            src={`${previewUrl}#toolbar=1`}
            className="w-full flex-1 min-h-[min(70vh,560px)] rounded-xl border border-[#d9b8c4]/60 bg-white shadow-sm"
          />
        )}
      </div>
    </div>
  );
}

// ─── Tab: Client Chat (UI placeholder) ───────────────────────────────────────

// ─── Direct Message Types ─────────────────────────────────────────────────────

interface DirectMessage {
  id: string;
  appointment_id: string;
  sender_type: "client" | "lawyer";
  content: string | null;
  attachment_url: string | null;
  attachment_name: string | null;
  attachment_content_type: string | null;
  is_read: boolean;
  created_at: string;
}

function fmtMsgTime(iso: string) {
  try {
    return new Date(iso).toLocaleTimeString(undefined, { hour: "numeric", minute: "2-digit" });
  } catch { return ""; }
}

function fmtMsgDate(iso: string) {
  try {
    const d = new Date(iso);
    const today = new Date();
    if (d.toDateString() === today.toDateString()) return "Today";
    const yesterday = new Date(today);
    yesterday.setDate(today.getDate() - 1);
    if (d.toDateString() === yesterday.toDateString()) return "Yesterday";
    return d.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
  } catch { return ""; }
}

function isSameDay(a: string, b: string) {
  try { return new Date(a).toDateString() === new Date(b).toDateString(); }
  catch { return false; }
}

function isImageType(ct: string | null | undefined) {
  return (ct ?? "").startsWith("image/");
}

// ─── ClientChatTab ────────────────────────────────────────────────────────────

function ClientChatTab({ appt }: { appt: Appointment }) {
  const [messages, setMessages] = useState<DirectMessage[]>([]);
  const [unread, setUnread] = useState(0);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [text, setText] = useState("");
  const [sending, setSending] = useState(false);
  const [sendError, setSendError] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const bottomRef = useRef<HTMLDivElement>(null);
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const messagingOpen = appointmentDirectMessagingOpen(appt);

  const { lawyerState } = useAuth();
  const lawyerSelfPhoto = lawyerState?.user.photo_url ?? null;
  const lawyerDisplayName =
    lawyerState?.profile.display_name?.trim() ||
    [lawyerState?.user.first_name, lawyerState?.user.last_name].filter(Boolean).join(" ") ||
    "Lawyer";

  const scrollToBottom = useCallback((smooth = true) => {
    setTimeout(() => {
      bottomRef.current?.scrollIntoView({ behavior: smooth ? "smooth" : "instant" });
    }, 60);
  }, []);

  const fetchMessages = useCallback(async (silent = false) => {
    if (!messagingOpen) return;
    try {
      const { data } = await api.get<{ messages: DirectMessage[]; unread_count: number }>(
        `/lawyer/appointments/${appt.id}/messages`
      );
      setMessages(data.messages);
      setUnread(data.unread_count);
      if (!silent) setLoadError(null);
    } catch (err: unknown) {
      if (!silent) setLoadError(getApiErrorMessage(err, "Could not load messages."));
    }
  }, [appt.id, messagingOpen]);

  const markRead = useCallback(async () => {
    if (!messagingOpen) return;
    try { await api.patch(`/lawyer/appointments/${appt.id}/messages/read`); }
    catch { /* best-effort */ }
  }, [appt.id, messagingOpen]);

  useEffect(() => {
    fetchMessages().then(() => {
      scrollToBottom(false);
      markRead();
    });
    pollRef.current = setInterval(() => fetchMessages(true), 5000);
    return () => { if (pollRef.current) clearInterval(pollRef.current); };
  }, [fetchMessages, markRead, scrollToBottom]);

  // Mark read whenever new messages arrive
  useEffect(() => {
    if (unread > 0) markRead();
  }, [messages.length, markRead, unread]);

  async function handleSend() {
    const t = text.trim();
    if (!t || sending) return;
    setSending(true);
    setSendError(null);
    try {
      const { data } = await api.post<DirectMessage>(`/lawyer/appointments/${appt.id}/messages`, { content: t });
      setText("");
      setMessages((prev) => [...prev, data]);
      scrollToBottom();
    } catch (err: unknown) {
      setSendError(getApiErrorMessage(err, "Failed to send message."));
    } finally {
      setSending(false);
    }
  }

  async function handleFileUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    e.target.value = "";
    setUploading(true);
    setSendError(null);
    try {
      const form = new FormData();
      form.append("file", file, file.name);
      const { data } = await api.post<DirectMessage>(
        `/lawyer/appointments/${appt.id}/messages/upload`,
        form,
      );
      setMessages((prev) => [...prev, data]);
      scrollToBottom();
    } catch (err: unknown) {
      setSendError(getApiErrorMessage(err, "Failed to upload file."));
    } finally {
      setUploading(false);
    }
  }

  if (!messagingOpen) {
    const isResolved = appt.status === "resolved";
    return (
      <div className="flex flex-col items-center justify-center h-full gap-3 p-8 text-center">
        <MessageCircle className="h-10 w-10 text-[#d9b8c4]" />
        <p className="text-sm font-semibold text-[#241715]">
          {isResolved ? "Messaging closed" : "Chat unavailable"}
        </p>
        <p className="text-xs text-[#957186] max-w-xs">
          {isResolved
            ? "This case is resolved and the 24-hour messaging window has ended. Reopen the case to send new messages."
            : appt.status === "pending"
              ? "Direct messaging is only available after you accept this appointment."
              : "Direct messaging is not available for this case."}
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      {appt.status === "resolved" && (
        <div className="mx-4 mt-3 rounded-xl border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-900 shrink-0">
          <span className="font-semibold">Case resolved.</span>{" "}
          You can still send messages for 24 hours after it was marked resolved, then the thread becomes read-only until you reopen the case.
        </div>
      )}
      {/* Case context bar */}
      <div className="px-4 py-2 bg-[#f7f0f4]/60 border-b border-[#d9b8c4]/30 flex items-center gap-2 shrink-0">
        <MessageCircle className="h-3.5 w-3.5 text-[#703d57]" />
        <span className="text-xs text-[#703d57] font-semibold truncate flex-1">
          {appt.client_name} — {displayCaseTitle(appt)}
        </span>
        {unread > 0 && (
          <span className="text-xs bg-[#703d57] text-white rounded-full px-2 py-0.5 font-bold">
            {unread} new
          </span>
        )}
      </div>

      {loadError && (
        <div className="mx-4 mt-3 rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700 shrink-0">
          {loadError}
        </div>
      )}

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-4 py-3 space-y-1 min-h-0">
        {messages.length === 0 && !loadError ? (
          <div className="flex flex-col items-center justify-center h-full gap-2 text-center">
            <MessageCircle className="h-8 w-8 text-[#d9b8c4]" />
            <p className="text-sm text-[#957186]">No messages yet</p>
            <p className="text-xs text-[#c4a8b5]">Send a message to start the conversation.</p>
          </div>
        ) : (
          messages.map((msg, i) => {
            const isLawyer = msg.sender_type === "lawyer";
            const showDate = i === 0 || !isSameDay(messages[i - 1].created_at, msg.created_at);
            return (
              <div key={msg.id}>
                {showDate && (
                  <div className="flex items-center gap-2 my-3">
                    <div className="flex-1 h-px bg-[#d9b8c4]/40" />
                    <span className="text-[11px] text-[#957186]">{fmtMsgDate(msg.created_at)}</span>
                    <div className="flex-1 h-px bg-[#d9b8c4]/40" />
                  </div>
                )}
                <div className={cn("flex gap-2 mb-2.5", isLawyer ? "justify-end" : "justify-start")}>
                  {!isLawyer && (
                    <ProfileAvatar
                      photoUrl={appt.client_photo_url}
                      name={appt.client_name}
                      className="h-7 w-7 text-[11px] mt-0.5"
                      fallbackBgClass="bg-[#957186]"
                    />
                  )}
                  <div className="max-w-[70%] flex flex-col gap-0.5">
                    <div className={cn(
                      "rounded-2xl text-sm leading-relaxed overflow-hidden",
                      isLawyer
                        ? "bg-[#703d57] text-white rounded-tr-sm"
                        : "bg-[#f7f0f4] text-[#241715] rounded-tl-sm border border-[#d9b8c4]/40"
                    )}>
                      {msg.attachment_url ? (
                        isImageType(msg.attachment_content_type) ? (
                          <a href={msg.attachment_url} target="_blank" rel="noreferrer">
                            <img
                              src={msg.attachment_url}
                              alt={msg.attachment_name ?? "image"}
                              className="max-w-[220px] max-h-[160px] object-cover rounded-t-2xl"
                            />
                            {msg.content && (
                              <p className="px-3 py-2 text-sm">{msg.content}</p>
                            )}
                          </a>
                        ) : (
                          <a
                            href={msg.attachment_url}
                            target="_blank"
                            rel="noreferrer"
                            className={cn("flex items-center gap-2 px-3 py-2.5 hover:opacity-80 transition-opacity")}
                          >
                            <Paperclip className="h-3.5 w-3.5 shrink-0" />
                            <span className="text-sm font-medium underline underline-offset-2 truncate max-w-[160px]">
                              {msg.attachment_name ?? "File"}
                            </span>
                            <ExternalLink className="h-3 w-3 shrink-0 opacity-60" />
                          </a>
                        )
                      ) : (
                        <p className="px-3 py-2.5">{msg.content}</p>
                      )}
                    </div>
                    <div className={cn("flex items-center gap-1", isLawyer ? "justify-end" : "justify-start")}>
                      <span className="text-[10px] text-[#957186]">{fmtMsgTime(msg.created_at)}</span>
                      {isLawyer && (
                        <span className={cn("text-[10px]", msg.is_read ? "text-[#703d57]" : "text-[#c4a8b5]")}>
                          {msg.is_read ? "✓✓" : "✓"}
                        </span>
                      )}
                    </div>
                  </div>
                  {isLawyer && (
                    <ProfileAvatar
                      photoUrl={lawyerSelfPhoto}
                      name={lawyerDisplayName}
                      className="h-7 w-7 text-[11px] mt-0.5"
                      fallbackBgClass="bg-[#703d57]"
                    />
                  )}
                </div>
              </div>
            );
          })
        )}
        <div ref={bottomRef} />
      </div>

      {/* Send error */}
      {sendError && (
        <div className="mx-4 mb-2 rounded-lg border border-red-200 bg-red-50 px-3 py-1.5 text-xs text-red-700 flex items-center justify-between shrink-0">
          <span>{sendError}</span>
          <button onClick={() => setSendError(null)} className="ml-2 text-red-400 hover:text-red-600">
            <X className="h-3 w-3" />
          </button>
        </div>
      )}

      {/* Input */}
      <div className="px-4 pb-4 pt-2 shrink-0 border-t border-[#d9b8c4]/30">
        <input
          ref={fileInputRef}
          type="file"
          accept=".jpg,.jpeg,.png,.gif,.webp,.pdf,.doc,.docx"
          className="hidden"
          onChange={handleFileUpload}
        />
        <div className="flex gap-2 items-end">
          <button
            type="button"
            onClick={() => fileInputRef.current?.click()}
            disabled={sending || uploading}
            className="p-2.5 rounded-xl border border-[#d9b8c4]/60 text-[#957186] hover:bg-[#f7f0f4] disabled:opacity-40 transition-colors shrink-0"
            title="Attach file"
          >
            {uploading
              ? <Loader2 className="h-4 w-4 animate-spin" />
              : <Paperclip className="h-4 w-4" />}
          </button>
          <div className="flex-1 rounded-2xl border border-[#d9b8c4] bg-white px-4 py-2.5">
            <textarea
              rows={1}
              className="w-full text-sm text-[#241715] placeholder-[#c4a8b5] resize-none outline-none leading-relaxed"
              placeholder={`Message ${appt.client_name.split(" ")[0]}…`}
              value={text}
              onChange={(e) => setText(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.shiftKey) {
                  e.preventDefault();
                  handleSend();
                }
              }}
              disabled={sending || uploading}
            />
          </div>
          <button
            type="button"
            onClick={handleSend}
            disabled={!text.trim() || sending || uploading}
            className="p-2.5 rounded-xl bg-[#703d57] text-white hover:bg-[#5a3046] disabled:opacity-40 transition-colors shrink-0"
          >
            {sending
              ? <Loader2 className="h-4 w-4 animate-spin" />
              : <Send className="h-4 w-4" />}
          </button>
        </div>
        <p className="text-center text-[10px] text-[#c4a8b5] mt-1.5">
          Enter to send · Shift+Enter for new line · Messages refresh every 5 s
        </p>
      </div>
    </div>
  );
}
