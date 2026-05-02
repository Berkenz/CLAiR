import { useCallback, useEffect, useState } from "react";
import {
  Check, X, RefreshCw, Loader2, Smartphone, CalendarDays, Clock, FileText, ChevronDown, ChevronUp,
} from "lucide-react";
import { api } from "@/lib/api";

interface Appointment {
  id: string;
  client_user_id: string | null;
  client_name: string;
  appointment_date: string;
  appointment_time: string;
  appointment_type: string;
  description: string | null;
  status: string;
  rejection_reason: string | null;
  created_at: string;
}

function formatDate(iso: string) {
  const [y, m, d] = iso.split("-").map(Number);
  const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
  return `${months[m - 1]} ${d}, ${y}`;
}

function formatTime(t: string) {
  const [h, min] = t.split(":").map(Number);
  const ampm = h >= 12 ? "PM" : "AM";
  return `${h % 12 || 12}:${String(min).padStart(2, "0")} ${ampm}`;
}

const TYPE_COLORS: Record<string, string> = {
  "Initial Consultation":  "bg-[#f7f0f4] text-[#703d57]",
  "Document Review":       "bg-blue-50 text-blue-700",
  "Follow-Up":             "bg-amber-50 text-amber-700",
  "Hearing Preparation":   "bg-red-50 text-red-700",
  "Deposition":            "bg-purple-50 text-purple-700",
  "Settlement Discussion": "bg-emerald-50 text-emerald-700",
  "Case Update":           "bg-gray-100 text-gray-600",
  "Other":                 "bg-gray-100 text-gray-600",
};

export function AppointmentsPage() {
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Accept state
  const [accepting, setAccepting] = useState<string | null>(null);

  // Reject modal state
  const [rejectTarget, setRejectTarget] = useState<Appointment | null>(null);
  const [rejectReason, setRejectReason] = useState("");
  const [rejecting, setRejecting] = useState(false);
  const [rejectError, setRejectError] = useState<string | null>(null);

  // Collapsed sections
  const [confirmedCollapsed, setConfirmedCollapsed] = useState(false);
  const [cancelledCollapsed, setCancelledCollapsed] = useState(true);

  const fetchAppointments = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const { data } = await api.get<{ appointments: Appointment[] }>("/lawyer/appointments");
      setAppointments(data.appointments);
    } catch {
      setError("Could not load appointments.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchAppointments(); }, [fetchAppointments]);

  async function handleAccept(appt: Appointment) {
    setAccepting(appt.id);
    try {
      const { data } = await api.post<Appointment>(`/lawyer/appointments/${appt.id}/accept`);
      setAppointments((prev) => prev.map((a) => a.id === appt.id ? data : a));
    } catch {
      // silently fail; user can retry
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
    if (!rejectTarget) return;
    if (!rejectReason.trim()) { setRejectError("Please provide a reason."); return; }
    setRejecting(true);
    setRejectError(null);
    try {
      const { data } = await api.post<Appointment>(`/lawyer/appointments/${rejectTarget.id}/reject`, {
        reason: rejectReason.trim(),
      });
      setAppointments((prev) => prev.map((a) => a.id === rejectTarget.id ? data : a));
      setRejectTarget(null);
    } catch (e: any) {
      setRejectError(e?.response?.data?.detail ?? "Failed to reject. Please try again.");
    } finally {
      setRejecting(false);
    }
  }

  const pending   = appointments.filter((a) => a.status === "pending")
    .sort((a, b) => a.appointment_date.localeCompare(b.appointment_date) || a.appointment_time.localeCompare(b.appointment_time));
  const confirmed = appointments.filter((a) => a.status === "confirmed")
    .sort((a, b) => a.appointment_date.localeCompare(b.appointment_date) || a.appointment_time.localeCompare(b.appointment_time));
  const cancelled = appointments.filter((a) => a.status === "cancelled")
    .sort((a, b) => b.appointment_date.localeCompare(a.appointment_date));

  return (
    <div className="space-y-6 max-w-3xl mx-auto">

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[#241715]">Appointments</h1>
          <p className="mt-0.5 text-sm text-[#957186]">
            {loading
              ? "Loading…"
              : `${appointments.length} total · ${pending.length} pending · ${confirmed.length} confirmed`}
          </p>
        </div>
        <button
          onClick={fetchAppointments}
          disabled={loading}
          className="p-2 rounded-xl border border-[#d9b8c4]/60 text-[#703d57] hover:bg-[#f7f0f4] transition-colors disabled:opacity-40"
          title="Refresh"
        >
          <RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} />
        </button>
      </div>

      {/* Error */}
      {error && (
        <div className="flex items-center justify-between rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
          <span>{error}</span>
          <button onClick={fetchAppointments} className="font-semibold underline">Retry</button>
        </div>
      )}

      {loading ? (
        <div className="py-24 flex items-center justify-center gap-2 text-[#957186]">
          <Loader2 className="h-5 w-5 animate-spin" />
          <span className="text-sm">Loading appointments…</span>
        </div>
      ) : (
        <>
          {/* ── Pending Requests ───────────────────────────────── */}
          <section>
            <div className="flex items-center gap-2 mb-3">
              <h2 className="text-sm font-bold text-[#241715]">Pending Requests</h2>
              {pending.length > 0 && (
                <span className="rounded-full bg-amber-100 text-amber-700 text-xs font-bold px-2 py-0.5">
                  {pending.length}
                </span>
              )}
            </div>

            {pending.length === 0 ? (
              <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white shadow-sm py-10 text-center text-sm text-gray-400">
                No pending requests.
              </div>
            ) : (
              <div className="space-y-3">
                {pending.map((a) => (
                  <AppointmentCard
                    key={a.id}
                    appt={a}
                    actions={
                      <div className="flex gap-2 mt-4 pt-4 border-t border-gray-100">
                        <button
                          onClick={() => handleAccept(a)}
                          disabled={accepting === a.id}
                          className="flex-1 flex items-center justify-center gap-1.5 rounded-xl bg-emerald-600 py-2 text-sm font-semibold text-white hover:bg-emerald-700 transition-colors disabled:opacity-60"
                        >
                          {accepting === a.id
                            ? <Loader2 className="h-4 w-4 animate-spin" />
                            : <Check className="h-4 w-4" />}
                          Accept
                        </button>
                        <button
                          onClick={() => openReject(a)}
                          disabled={accepting === a.id}
                          className="flex-1 flex items-center justify-center gap-1.5 rounded-xl border border-red-200 py-2 text-sm font-semibold text-red-600 hover:bg-red-50 transition-colors disabled:opacity-60"
                        >
                          <X className="h-4 w-4" />
                          Reject
                        </button>
                      </div>
                    }
                  />
                ))}
              </div>
            )}
          </section>

          {/* ── Confirmed ──────────────────────────────────────── */}
          <section>
            <button
              onClick={() => setConfirmedCollapsed((v) => !v)}
              className="flex w-full items-center gap-2 mb-3 group"
            >
              <h2 className="text-sm font-bold text-[#241715]">Confirmed</h2>
              {confirmed.length > 0 && (
                <span className="rounded-full bg-emerald-100 text-emerald-700 text-xs font-bold px-2 py-0.5">
                  {confirmed.length}
                </span>
              )}
              <span className="ml-auto text-gray-400 group-hover:text-gray-600">
                {confirmedCollapsed ? <ChevronDown className="h-4 w-4" /> : <ChevronUp className="h-4 w-4" />}
              </span>
            </button>

            {!confirmedCollapsed && (
              confirmed.length === 0 ? (
                <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white shadow-sm py-10 text-center text-sm text-gray-400">
                  No confirmed appointments.
                </div>
              ) : (
                <div className="space-y-3">
                  {confirmed.map((a) => <AppointmentCard key={a.id} appt={a} />)}
                </div>
              )
            )}
          </section>

          {/* ── Rejected / Cancelled ───────────────────────────── */}
          {cancelled.length > 0 && (
            <section>
              <button
                onClick={() => setCancelledCollapsed((v) => !v)}
                className="flex w-full items-center gap-2 mb-3 group"
              >
                <h2 className="text-sm font-bold text-[#241715]">Rejected</h2>
                <span className="rounded-full bg-red-100 text-red-600 text-xs font-bold px-2 py-0.5">
                  {cancelled.length}
                </span>
                <span className="ml-auto text-gray-400 group-hover:text-gray-600">
                  {cancelledCollapsed ? <ChevronDown className="h-4 w-4" /> : <ChevronUp className="h-4 w-4" />}
                </span>
              </button>

              {!cancelledCollapsed && (
                <div className="space-y-3">
                  {cancelled.map((a) => <AppointmentCard key={a.id} appt={a} />)}
                </div>
              )}
            </section>
          )}
        </>
      )}

      {/* ── Reject Modal ─────────────────────────────────────────── */}
      {rejectTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-2xl bg-white shadow-xl p-6">
            <div className="flex items-start justify-between mb-4">
              <div>
                <h2 className="font-bold text-[#241715] text-lg">Reject Appointment</h2>
                <p className="text-sm text-[#957186] mt-0.5">
                  {rejectTarget.client_name} · {formatDate(rejectTarget.appointment_date)} at {formatTime(rejectTarget.appointment_time)}
                </p>
              </div>
              <button onClick={() => setRejectTarget(null)} className="p-1 rounded-lg text-gray-400 hover:text-gray-700 mt-0.5">
                <X className="h-5 w-5" />
              </button>
            </div>

            <div>
              <label className="block text-xs font-semibold text-[#703d57] mb-1.5">
                <FileText className="h-3 w-3 inline mr-1" />Reason for rejection *
              </label>
              <textarea
                rows={4}
                autoFocus
                className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30 resize-none"
                placeholder="e.g. Schedule conflict, please book another date…"
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
              />
              {rejectError && (
                <p className="mt-2 text-xs text-red-600 bg-red-50 border border-red-200 rounded-lg px-3 py-2">
                  {rejectError}
                </p>
              )}
            </div>

            <div className="flex gap-3 mt-5">
              <button
                onClick={() => setRejectTarget(null)}
                className="flex-1 rounded-xl border border-[#d9b8c4]/60 py-2.5 text-sm font-semibold text-[#402a2c] hover:bg-[#f7f0f4] transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleReject}
                disabled={rejecting}
                className="flex-1 rounded-xl bg-red-600 py-2.5 text-sm font-semibold text-white hover:bg-red-700 transition-colors disabled:opacity-60 flex items-center justify-center gap-2"
              >
                {rejecting && <Loader2 className="h-4 w-4 animate-spin" />}
                Reject
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

/* ── Reusable appointment card ─────────────────────────────────────────── */
function AppointmentCard({ appt, actions }: { appt: Appointment; actions?: React.ReactNode }) {
  const statusStyle: Record<string, string> = {
    pending:   "bg-amber-50 text-amber-700 border-amber-200",
    confirmed: "bg-emerald-50 text-emerald-700 border-emerald-200",
    cancelled: "bg-red-50 text-red-600 border-red-200",
  };

  return (
    <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white shadow-sm p-5">
      {/* Top row */}
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <p className="font-semibold text-[#241715] text-sm">{appt.client_name}</p>
            {appt.client_user_id && (
              <span className="flex items-center gap-1 text-xs text-[#957186]" title="Booked via mobile app">
                <Smartphone className="h-3 w-3" />
                Mobile
              </span>
            )}
          </div>
          <div className="flex items-center gap-3 mt-1.5 flex-wrap">
            <span className="flex items-center gap-1 text-xs text-gray-500">
              <CalendarDays className="h-3 w-3" />
              {formatDate(appt.appointment_date)}
            </span>
            <span className="flex items-center gap-1 text-xs text-gray-500">
              <Clock className="h-3 w-3" />
              {formatTime(appt.appointment_time)}
            </span>
          </div>
        </div>

        {/* Status + type badges */}
        <div className="flex flex-col items-end gap-1.5 shrink-0">
          <span className={`text-xs font-semibold px-2.5 py-0.5 rounded-full border capitalize ${statusStyle[appt.status] ?? "bg-gray-100 text-gray-600 border-gray-200"}`}>
            {appt.status}
          </span>
          <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${TYPE_COLORS[appt.appointment_type] ?? "bg-gray-100 text-gray-600"}`}>
            {appt.appointment_type}
          </span>
        </div>
      </div>

      {/* Description */}
      {appt.description && (
        <p className="mt-3 text-xs text-gray-500 leading-relaxed border-t border-gray-100 pt-3">
          <FileText className="h-3 w-3 inline mr-1 text-gray-400" />
          {appt.description}
        </p>
      )}

      {/* Rejection reason */}
      {appt.status === "cancelled" && appt.rejection_reason && (
        <div className="mt-3 border-t border-gray-100 pt-3">
          <p className="text-xs text-red-600 bg-red-50 rounded-lg px-3 py-2">
            <span className="font-semibold">Reason: </span>{appt.rejection_reason}
          </p>
        </div>
      )}

      {/* Action slot */}
      {actions}
    </div>
  );
}
