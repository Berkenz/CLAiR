import { useCallback, useEffect, useRef, useState } from "react";
import {
  Check, X, RefreshCw, Loader2, Smartphone, CalendarDays, Clock,
  FileText, ChevronDown, ChevronUp, WifiOff, Download, Bot, User,
  ThumbsUp, Flag, AlertTriangle, Send, MessageCircle, Info,
  MessageSquare, Search, Pencil, Paperclip, ExternalLink,
} from "lucide-react";
import { api } from "@/lib/api";
import { getApiErrorMessage, isApiNetworkError } from "@/lib/api-error";
import { cn } from "@/lib/cn";

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
  appointment_date: string;
  appointment_time: string;
  appointment_type: string;
  case_title: string | null;
  description: string | null;
  attachments: AppointmentAttachment[];
  status: "pending" | "confirmed" | "cancelled";
  rejection_reason: string | null;
  attached_conversation_id: string | null;
  created_at: string;
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

type DetailTab = "overview" | "conversation" | "pdf" | "chat";

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

function fmtDate(iso: string) {
  const [y, m, d] = iso.split("-").map(Number);
  const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
  return `${months[m - 1]} ${d}, ${y}`;
}

function fmtTime(t: string) {
  const [h, min] = t.split(":").map(Number);
  return `${h % 12 || 12}:${String(min).padStart(2, "0")} ${h >= 12 ? "PM" : "AM"}`;
}

function fmtIso(iso: string | null) {
  if (!iso) return "—";
  try { return new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" }); }
  catch { return "—"; }
}

function initials(name: string) {
  return name.trim().split(/\s+/).map((w) => w[0]).join("").slice(0, 2).toUpperCase() || "?";
}

const STATUS_BADGE: Record<string, string> = {
  pending:   "bg-amber-50 text-amber-700 border-amber-200",
  confirmed: "bg-emerald-50 text-emerald-700 border-emerald-200",
  cancelled: "bg-red-50 text-red-600 border-red-200",
};

const AVATAR_BG = ["bg-[#703d57]", "bg-[#957186]", "bg-[#402a2c]", "bg-[#5a3046]", "bg-[#7e5069]"];

function displayCaseTitle(appt: Pick<Appointment, "case_title" | "client_name">): string {
  const t = appt.case_title?.trim();
  if (t) return t;
  return "Untitled case";
}

function matchesCaseSearch(appt: Appointment, q: string): boolean {
  if (!q) return true;
  return (
    appt.client_name.toLowerCase().includes(q) ||
    (appt.case_title ?? "").toLowerCase().includes(q)
  );
}

// ─── Main Page ────────────────────────────────────────────────────────────────

export function CasesPage() {
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
  const [search, setSearch] = useState("");
  const [pendingCollapsed, setPendingCollapsed] = useState(false);
  const [closedCollapsed, setClosedCollapsed] = useState(true);

  const fetchAppointments = useCallback(async () => {
    setLoading(true);
    setBackendDown(false);
    setLoadError(null);
    try {
      const { data } = await api.get<{ appointments: Appointment[] }>("/lawyer/appointments");
      setAppointments(
        data.appointments.map((a) => ({
          ...a,
          attachments: Array.isArray(a.attachments) ? a.attachments : [],
          case_title: a.case_title ?? null,
        })),
      );
    } catch (err: unknown) {
      if (isApiNetworkError(err)) setBackendDown(true);
      else setLoadError(getApiErrorMessage(err, "Could not load appointments."));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchAppointments(); }, [fetchAppointments]);

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
      setAppointments((prev) => prev.map((a) => a.id === appt.id ? data : a));
      setSelected(data);
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
      setAppointments((prev) => prev.map((a) => a.id === rejectTarget.id ? data : a));
      if (selected?.id === rejectTarget.id) setSelected(data);
      setRejectTarget(null);
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { detail?: string } } })?.response?.data?.detail;
      setRejectError(msg ?? "Failed to reject. Please try again.");
    } finally {
      setRejecting(false);
    }
  }

  const q = search.toLowerCase();
  const pending   = appointments.filter((a) => a.status === "pending"   && matchesCaseSearch(a, q))
    .sort((a, b) => a.appointment_date.localeCompare(b.appointment_date));
  const confirmed = appointments.filter((a) => a.status === "confirmed" && matchesCaseSearch(a, q))
    .sort((a, b) => a.appointment_date.localeCompare(b.appointment_date));
  const cancelled = appointments.filter((a) => a.status === "cancelled" && matchesCaseSearch(a, q))
    .sort((a, b) => b.appointment_date.localeCompare(a.appointment_date));

  function handleApptUpdated(next: Appointment) {
    setAppointments((prev) => prev.map((a) => (a.id === next.id ? next : a)));
    setSelected(next);
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
      <button onClick={fetchAppointments} className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#703d57] text-sm font-semibold text-white hover:bg-[#5a3046] transition">
        <RefreshCw className="h-4 w-4" />Try again
      </button>
    </div>
  );

  return (
    <div className="flex gap-5 max-w-7xl mx-auto h-[calc(100vh-8rem)]">

      {/* ── Left panel: list ── */}
      <div className="w-80 shrink-0 flex flex-col gap-3 overflow-y-auto pr-1">

        {/* Header */}
        <div className="flex items-center justify-between pt-1">
          <div>
            <h1 className="text-xl font-bold text-[#241715]">Cases</h1>
            <p className="text-xs text-[#957186] mt-0.5">{pending.length} pending · {confirmed.length} active</p>
          </div>
          <button onClick={fetchAppointments} className="p-2 rounded-xl border border-[#d9b8c4]/60 text-[#703d57] hover:bg-[#f7f0f4] transition" title="Refresh">
            <RefreshCw className="h-4 w-4" />
          </button>
        </div>

        {/* Search */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-gray-400" />
          <input
            className="w-full rounded-xl border border-[#d9b8c4]/60 bg-white pl-8 pr-3 py-2 text-sm text-[#241715] placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
            placeholder="Search clients…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        {loadError && (
          <div className="rounded-xl border border-amber-200 bg-amber-50 px-3 py-2.5 text-xs text-amber-900">{loadError}</div>
        )}

        {/* Pending requests */}
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
            <div className="space-y-2">
              {pending.length === 0 ? (
                <p className="text-xs text-gray-400 px-1 py-3">No pending requests.</p>
              ) : pending.map((a, i) => (
                <button
                  key={a.id}
                  type="button"
                  onClick={() => setSelected(a)}
                  className={cn(
                    "w-full text-left rounded-2xl border p-3.5 transition-all",
                    selected?.id === a.id
                      ? "border-[#703d57] bg-[#f7f0f4]"
                      : "border-[#d9b8c4]/40 bg-white hover:border-[#703d57]/40 hover:bg-[#f7f0f4]"
                  )}
                >
                  <div className="flex items-center gap-2.5">
                    <div className={`h-8 w-8 rounded-full flex items-center justify-center text-xs font-bold text-white shrink-0 ${AVATAR_BG[i % AVATAR_BG.length]}`}>
                      {initials(a.client_name)}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="text-[15px] font-bold text-[#241715] truncate leading-snug">{displayCaseTitle(a)}</p>
                      <p className="text-xs text-[#957186] truncate mt-0.5">{a.client_name}</p>
                      <p className="text-[11px] text-[#957186]/90 mt-0.5">{fmtDate(a.appointment_date)}</p>
                    </div>
                    <span className="text-[10px] font-semibold bg-amber-50 text-amber-700 border border-amber-200 px-2 py-0.5 rounded-full shrink-0">pending</span>
                  </div>
                  <p className="text-[11px] text-gray-400 mt-1.5 truncate pl-10">{a.appointment_type}</p>
                  {/* Quick accept/reject inline */}
                  <div className="flex gap-2 mt-2.5 pl-10" onClick={(e) => e.stopPropagation()}>
                    <button
                      onClick={() => handleAccept(a)}
                      disabled={accepting === a.id}
                      className="flex-1 flex items-center justify-center gap-1 py-1.5 rounded-lg bg-emerald-600 text-[11px] font-semibold text-white hover:bg-emerald-700 disabled:opacity-60 transition"
                    >
                      {accepting === a.id ? <Loader2 className="h-3 w-3 animate-spin" /> : <Check className="h-3 w-3" />}
                      Accept
                    </button>
                    <button
                      onClick={() => openReject(a)}
                      disabled={accepting === a.id}
                      className="flex-1 flex items-center justify-center gap-1 py-1.5 rounded-lg border border-red-200 text-[11px] font-semibold text-red-600 hover:bg-red-50 disabled:opacity-60 transition"
                    >
                      <X className="h-3 w-3" />
                      Reject
                    </button>
                  </div>
                </button>
              ))}
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
          <div className="space-y-2">
            {confirmed.length === 0 ? (
              <p className="text-xs text-gray-400 px-1 py-3">No active cases yet. Accept a request to create one.</p>
            ) : confirmed.map((a, i) => (
              <button
                key={a.id}
                type="button"
                onClick={() => setSelected(a)}
                className={cn(
                  "w-full text-left rounded-2xl border p-3.5 transition-all",
                  selected?.id === a.id
                    ? "border-[#703d57] bg-[#f7f0f4]"
                    : "border-[#d9b8c4]/40 bg-white hover:border-[#703d57]/40 hover:bg-[#f7f0f4]"
                )}
              >
                <div className="flex items-center gap-2.5">
                  <div className={`h-8 w-8 rounded-full flex items-center justify-center text-xs font-bold text-white shrink-0 ${AVATAR_BG[i % AVATAR_BG.length]}`}>
                    {initials(a.client_name)}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-[15px] font-bold text-[#241715] truncate leading-snug">{displayCaseTitle(a)}</p>
                    <p className="text-xs text-[#957186] truncate mt-0.5">{a.client_name}</p>
                    <p className="text-[11px] text-[#957186]/90 mt-0.5">{fmtDate(a.appointment_date)} · {fmtTime(a.appointment_time)}</p>
                  </div>
                </div>
                <p className="text-[11px] text-gray-400 mt-1 truncate pl-10">{a.appointment_type}</p>
              </button>
            ))}
          </div>
        </div>

        {/* Closed */}
        {cancelled.length > 0 && (
          <div>
            <button onClick={() => setClosedCollapsed((v) => !v)} className="flex items-center gap-2 w-full mb-2">
              <span className="text-xs font-bold text-[#241715] uppercase tracking-wide">Rejected</span>
              <span className="rounded-full bg-red-100 text-red-600 text-[10px] font-bold px-1.5 py-0.5">{cancelled.length}</span>
              <span className="ml-auto text-gray-400">{closedCollapsed ? <ChevronDown className="h-3.5 w-3.5" /> : <ChevronUp className="h-3.5 w-3.5" />}</span>
            </button>
            {!closedCollapsed && (
              <div className="space-y-2">
                {cancelled.map((a, i) => (
                  <button
                    key={a.id}
                    type="button"
                    onClick={() => setSelected(a)}
                    className={cn(
                      "w-full text-left rounded-2xl border p-3.5 opacity-60 transition-all",
                      selected?.id === a.id
                        ? "border-[#703d57] bg-[#f7f0f4] opacity-100"
                        : "border-[#d9b8c4]/40 bg-white hover:opacity-80"
                    )}
                  >
                    <div className="flex items-center gap-2.5">
                      <div className={`h-8 w-8 rounded-full flex items-center justify-center text-xs font-bold text-white shrink-0 ${AVATAR_BG[i % AVATAR_BG.length]}`}>
                        {initials(a.client_name)}
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="text-[15px] font-bold text-[#241715] truncate leading-snug">{displayCaseTitle(a)}</p>
                        <p className="text-xs text-[#957186] truncate mt-0.5">{a.client_name}</p>
                        <p className="text-[11px] text-red-500/90 truncate mt-0.5">{a.rejection_reason ?? "Rejected"}</p>
                      </div>
                    </div>
                  </button>
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      {/* ── Right panel: case detail ── */}
      <div className="flex-1 min-w-0 flex flex-col">
        {selected ? (
          <CaseDetail
            appt={selected}
            onAccept={() => handleAccept(selected)}
            accepting={accepting === selected.id}
            onReject={() => openReject(selected)}
            onApptUpdated={handleApptUpdated}
          />
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center text-center rounded-2xl border border-[#d9b8c4]/40 bg-white">
            <div className="h-16 w-16 rounded-2xl bg-[#f7f0f4] border border-[#d9b8c4]/40 flex items-center justify-center mb-4">
              <FileText className="h-7 w-7 text-[#957186]" />
            </div>
            <p className="text-sm font-semibold text-[#241715]">Select a case</p>
            <p className="text-xs text-[#957186] mt-1 max-w-xs">
              Choose a pending request or active case from the list to view its details.
            </p>
          </div>
        )}
      </div>

      {/* Reject modal */}
      {rejectTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-2xl bg-white shadow-xl p-6">
            <div className="flex items-start justify-between mb-4">
              <div>
                <h2 className="font-bold text-[#241715] text-lg">Reject Appointment</h2>
                <p className="text-sm text-[#957186] mt-0.5">{rejectTarget.client_name} · {fmtDate(rejectTarget.appointment_date)}</p>
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

function CaseDetail({ appt, onAccept, accepting, onReject, onApptUpdated }: {
  appt: Appointment;
  onAccept: () => void;
  accepting: boolean;
  onReject: () => void;
  onApptUpdated: (a: Appointment) => void;
}) {
  const [tab, setTab] = useState<DetailTab>("overview");

  const tabs: { key: DetailTab; label: string; icon: React.ReactNode }[] = [
    { key: "overview",      label: "Overview",         icon: <Info className="h-3.5 w-3.5" /> },
    { key: "conversation",  label: "CLAiR Chat",        icon: <Bot className="h-3.5 w-3.5" /> },
    { key: "pdf",           label: "PDF Summary",       icon: <Download className="h-3.5 w-3.5" /> },
    { key: "chat",          label: "Client Chat",       icon: <MessageCircle className="h-3.5 w-3.5" /> },
  ];

  return (
    <div className="flex flex-col h-full rounded-2xl border border-[#d9b8c4]/40 bg-white overflow-hidden">
      {/* Case header */}
      <div className="px-6 py-4 border-b border-[#d9b8c4]/30 bg-[#f7f0f4] shrink-0">
        <div className="flex items-start justify-between gap-4">
          <div className="flex items-center gap-3 min-w-0">
            <div className="h-10 w-10 rounded-full bg-[#703d57] flex items-center justify-center text-sm font-bold text-white shrink-0">
              {initials(appt.client_name)}
            </div>
            <div className="min-w-0">
              <p className="text-[11px] font-semibold uppercase tracking-wide text-[#957186]">Case</p>
              <p className="font-bold text-[#241715] truncate text-lg leading-tight">{displayCaseTitle(appt)}</p>
              <p className="text-sm text-[#703d57] font-medium truncate mt-0.5">{appt.client_name}</p>
              <div className="flex items-center gap-3 mt-1 flex-wrap">
                <span className="flex items-center gap-1 text-xs text-[#957186]">
                  <CalendarDays className="h-3 w-3" />{fmtDate(appt.appointment_date)}
                </span>
                <span className="flex items-center gap-1 text-xs text-[#957186]">
                  <Clock className="h-3 w-3" />{fmtTime(appt.appointment_time)}
                </span>
                {appt.client_user_id && (
                  <span className="flex items-center gap-1 text-xs text-[#957186]">
                    <Smartphone className="h-3 w-3" />Mobile
                  </span>
                )}
              </div>
            </div>
          </div>
          <div className="flex items-center gap-2 shrink-0">
            <span className={`text-xs font-semibold px-2.5 py-1 rounded-full border capitalize ${STATUS_BADGE[appt.status] ?? "bg-gray-100 text-gray-600 border-gray-200"}`}>
              {appt.status}
            </span>
            {appt.status === "pending" && (
              <div className="flex gap-1.5">
                <button onClick={onAccept} disabled={accepting} className="flex items-center gap-1 px-3 py-1.5 rounded-lg bg-emerald-600 text-xs font-semibold text-white hover:bg-emerald-700 disabled:opacity-60 transition">
                  {accepting ? <Loader2 className="h-3 w-3 animate-spin" /> : <Check className="h-3 w-3" />}Accept
                </button>
                <button onClick={onReject} disabled={accepting} className="flex items-center gap-1 px-3 py-1.5 rounded-lg border border-red-200 text-xs font-semibold text-red-600 hover:bg-red-50 disabled:opacity-60 transition">
                  <X className="h-3 w-3" />Reject
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-0 border-b border-[#d9b8c4]/40 shrink-0 px-4 bg-white">
        {tabs.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={cn(
              "flex items-center gap-1.5 px-4 py-2.5 text-xs font-medium border-b-2 -mb-px transition-colors",
              tab === t.key
                ? "border-[#703d57] text-[#703d57]"
                : "border-transparent text-[#957186] hover:text-[#703d57]"
            )}
          >
            {t.icon}{t.label}
          </button>
        ))}
      </div>

      {/* Tab content */}
      <div className="flex-1 overflow-y-auto min-h-0">
        {tab === "overview"     && <OverviewTab appt={appt} onApptUpdated={onApptUpdated} />}
        {tab === "conversation" && <ConversationTab appt={appt} />}
        {tab === "pdf"          && <PdfTab appt={appt} />}
        {tab === "chat"         && <ClientChatTab appt={appt} />}
      </div>
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

  const atts = appt.attachments ?? [];

  return (
    <div className="p-6 space-y-5">
      {/* Case title (lawyer can rename) */}
      <div>
        <div className="flex items-center justify-between gap-2 mb-2">
          <p className="text-xs font-semibold text-[#5a3046] uppercase tracking-wide">Case title</p>
          {!editingTitle ? (
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
        <InfoBlock label="Appointment Type"  value={appt.appointment_type} />
        <InfoBlock label="Status"             value={appt.status.charAt(0).toUpperCase() + appt.status.slice(1)} />
        <InfoBlock label="Date"               value={fmtDate(appt.appointment_date)} />
        <InfoBlock label="Time"               value={fmtTime(appt.appointment_time)} />
        <InfoBlock label="Booked"             value={fmtIso(appt.created_at)} />
        <InfoBlock label="Client"             value={appt.client_name} />
      </div>

      <div>
        <p className="text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-2">Description</p>
        {appt.description?.trim() ? (
          <div className="rounded-xl border border-[#d9b8c4]/40 bg-[#f7f0f4] px-4 py-3 text-sm text-[#241715] leading-relaxed whitespace-pre-wrap">
            {appt.description}
          </div>
        ) : (
          <div className="rounded-xl border border-[#d9b8c4]/40 bg-[#f7f0f4] px-4 py-3 text-sm text-[#957186]">
            No description provided.
          </div>
        )}
      </div>

      <div>
        <p className="text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-2 flex items-center gap-1.5">
          <Paperclip className="h-3.5 w-3.5" />
          Uploaded documents
        </p>
        {atts.length === 0 ? (
          <div className="rounded-xl border border-[#d9b8c4]/40 bg-white px-4 py-3 text-sm text-[#957186]">
            No files attached to this request.
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
        {atts.some((a) => !a.url) && (
          <p className="mt-2 text-[11px] text-[#957186] leading-relaxed">
            Older requests may list filenames only. New bookings upload files to storage when Supabase is configured.
          </p>
        )}
      </div>

      {appt.status === "cancelled" && appt.rejection_reason && (
        <div>
          <p className="text-xs font-semibold text-red-600 uppercase tracking-wide mb-2">Rejection Reason</p>
          <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {appt.rejection_reason}
          </div>
        </div>
      )}

      {!appt.attached_conversation_id && (
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
                  "max-w-[78%] rounded-2xl px-4 py-3 text-sm leading-relaxed whitespace-pre-wrap",
                  isAI ? "bg-[#f7f0f4] text-[#241715] rounded-tl-sm" : "bg-[#703d57] text-white rounded-tr-sm"
                )}>
                  {msg.text}
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

function ClientChatTab({ appt }: { appt: Appointment }) {
  const bottomRef = useRef<HTMLDivElement>(null);

  const placeholderMessages = [
    { id: "1", role: "lawyer", text: `Hi ${appt.client_name.split(" ")[0]}, I've reviewed your appointment request and I'm looking into your concerns. I'll get back to you with further details shortly.` },
    { id: "2", role: "client", text: "Thank you, I appreciate it. Please let me know if you need any additional documents from my end." },
  ];

  return (
    <div className="flex flex-col h-full">
      {/* Coming soon banner */}
      <div className="mx-4 mt-4 rounded-xl border border-amber-200 bg-amber-50 px-4 py-2.5 flex items-center gap-2 shrink-0">
        <MessageCircle className="h-4 w-4 text-amber-600 shrink-0" />
        <p className="text-xs text-amber-800 font-medium">
          Direct client messaging is coming soon. The interface below is a preview.
        </p>
      </div>

      {/* Chat messages (placeholder) */}
      <div className="flex-1 overflow-y-auto p-5 space-y-4 min-h-0 opacity-60 pointer-events-none select-none">
        {placeholderMessages.map((msg) => {
          const isLawyer = msg.role === "lawyer";
          return (
            <div key={msg.id} className={cn("flex gap-3", isLawyer ? "justify-end" : "justify-start")}>
              {!isLawyer && (
                <div className="h-7 w-7 rounded-full bg-[#957186] flex items-center justify-center shrink-0 mt-0.5">
                  <User className="h-3.5 w-3.5 text-white" />
                </div>
              )}
              <div className={cn(
                "max-w-[72%] rounded-2xl px-4 py-3 text-sm leading-relaxed",
                isLawyer ? "bg-[#703d57] text-white rounded-tr-sm" : "bg-[#f7f0f4] text-[#241715] rounded-tl-sm"
              )}>
                {msg.text}
              </div>
              {isLawyer && (
                <div className="h-7 w-7 rounded-full bg-[#703d57] flex items-center justify-center shrink-0 mt-0.5">
                  <User className="h-3.5 w-3.5 text-white" />
                </div>
              )}
            </div>
          );
        })}
        <div ref={bottomRef} />
      </div>

      {/* Input (disabled) */}
      <div className="px-4 pb-4 shrink-0">
        <div className="flex gap-2 items-end opacity-50 pointer-events-none">
          <div className="flex-1 rounded-2xl border border-[#d9b8c4] bg-white px-4 py-3">
            <p className="text-sm text-[#c490aa]">Message {appt.client_name.split(" ")[0]}…</p>
          </div>
          <button className="p-3 rounded-2xl bg-[#703d57] flex items-center justify-center" disabled>
            <Send className="h-4 w-4 text-white" />
          </button>
        </div>
        <p className="text-center text-[11px] text-[#957186] mt-2">Client messaging will be available in a future update.</p>
      </div>
    </div>
  );
}
