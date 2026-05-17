import { useCallback, useEffect, useState } from "react";
import {
  Bell, BellOff, Check, CheckCheck, Loader2, RefreshCw,
  Briefcase, MessageCircle, UserCheck, AlertTriangle,
  Clock, Trash2, WifiOff, Filter,
} from "lucide-react";
import { useNavigate } from "react-router-dom";
import { api } from "@/lib/api";
import { getApiErrorMessage, isApiNetworkError } from "@/lib/api-error";
import { cn } from "@/lib/cn";
import { useRefreshNotificationBadge } from "@/layouts/dashboard-layout";

export interface Notification {
  id: string;
  notification_type: string;
  title: string;
  body: string | null;
  payload: Record<string, unknown> | null;
  is_read: boolean;
  created_at: string;
}

const ICON_MAP: Record<string, typeof Bell> = {
  new_appointment: Briefcase,
  appointment_accepted: UserCheck,
  appointment_rejected: AlertTriangle,
  appointment_resolved: Check,
  new_direct_message: MessageCircle,
};

const ICON_BG_MAP: Record<string, string> = {
  new_appointment: "bg-amber-100 text-amber-700",
  appointment_accepted: "bg-emerald-100 text-emerald-700",
  appointment_rejected: "bg-red-100 text-red-600",
  appointment_resolved: "bg-slate-100 text-slate-600",
  new_direct_message: "bg-violet-100 text-violet-700",
};

function getNotificationRoute(n: Notification): string | null {
  const apptId = n.payload?.appointment_id;
  if (!apptId) return null;
  const id = String(apptId);
  if (n.notification_type === "new_direct_message") {
    return `/cases?appt=${id}&tab=chat`;
  }
  return `/cases?appt=${id}`;
}

type FilterKey = "all" | "unread";

function timeAgo(iso: string): string {
  try {
    const diff = Date.now() - new Date(iso).getTime();
    const secs = Math.floor(diff / 1000);
    if (secs < 60) return "just now";
    const mins = Math.floor(secs / 60);
    if (mins < 60) return `${mins}m ago`;
    const hrs = Math.floor(mins / 60);
    if (hrs < 24) return `${hrs}h ago`;
    const days = Math.floor(hrs / 24);
    if (days < 7) return `${days}d ago`;
    return new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric" });
  } catch {
    return "";
  }
}

function groupByDate(items: Notification[]): { label: string; items: Notification[] }[] {
  const groups: Map<string, Notification[]> = new Map();
  const today = new Date();
  const yesterday = new Date(today);
  yesterday.setDate(today.getDate() - 1);

  for (const n of items) {
    let label: string;
    try {
      const d = new Date(n.created_at);
      if (d.toDateString() === today.toDateString()) label = "Today";
      else if (d.toDateString() === yesterday.toDateString()) label = "Yesterday";
      else label = d.toLocaleDateString(undefined, { month: "long", day: "numeric", year: "numeric" });
    } catch {
      label = "Other";
    }
    const arr = groups.get(label) ?? [];
    arr.push(n);
    groups.set(label, arr);
  }
  return Array.from(groups.entries()).map(([label, items]) => ({ label, items }));
}

export function NotificationsPage() {
  const navigate = useNavigate();
  const refreshBadge = useRefreshNotificationBadge();
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);
  const [backendDown, setBackendDown] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [markingAll, setMarkingAll] = useState(false);
  const [clearingAll, setClearingAll] = useState(false);
  const [filter, setFilter] = useState<FilterKey>("all");

  const fetchNotifications = useCallback(async () => {
    setLoading(true);
    setBackendDown(false);
    setLoadError(null);
    try {
      const { data } = await api.get<{ notifications: Notification[] }>("/lawyer/notifications");
      setNotifications(data.notifications);
    } catch (err: unknown) {
      if (isApiNetworkError(err)) setBackendDown(true);
      else setLoadError(getApiErrorMessage(err, "Could not load notifications."));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchNotifications();
  }, [fetchNotifications]);

  async function markAsRead(id: string) {
    try {
      await api.patch(`/lawyer/notifications/${id}/read`);
      setNotifications((prev) => prev.map((n) => (n.id === id ? { ...n, is_read: true } : n)));
      void refreshBadge();
    } catch { /* best-effort */ }
  }

  async function markAllAsRead() {
    setMarkingAll(true);
    try {
      await api.patch("/lawyer/notifications/read-all");
      setNotifications((prev) => prev.map((n) => ({ ...n, is_read: true })));
      void refreshBadge();
    } catch { /* best-effort */ }
    finally { setMarkingAll(false); }
  }

  async function clearAll() {
    setClearingAll(true);
    try {
      await api.delete("/lawyer/notifications");
      setNotifications([]);
      void refreshBadge();
    } catch { /* best-effort */ }
    finally { setClearingAll(false); }
  }

  function handleClick(n: Notification) {
    if (!n.is_read) markAsRead(n.id);
    const route = getNotificationRoute(n);
    if (route) navigate(route);
  }

  const unreadCount = notifications.filter((n) => !n.is_read).length;
  const displayed = filter === "unread" ? notifications.filter((n) => !n.is_read) : notifications;
  const groups = groupByDate(displayed);

  if (loading) {
    return (
      <div className="py-32 flex items-center justify-center gap-2 text-[#957186]">
        <Loader2 className="h-5 w-5 animate-spin" />
        <span className="text-sm">Loading notifications…</span>
      </div>
    );
  }

  if (backendDown) {
    return (
      <div className="py-32 flex flex-col items-center justify-center gap-4 text-center">
        <div className="h-16 w-16 rounded-2xl bg-[#f7f0f4] border border-[#d9b8c4]/40 flex items-center justify-center">
          <WifiOff className="h-7 w-7 text-[#957186]" />
        </div>
        <p className="text-sm font-semibold text-[#241715]">Backend not reachable</p>
        <button
          onClick={fetchNotifications}
          className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#703d57] text-sm font-semibold text-white hover:bg-[#5a3046] transition"
        >
          <RefreshCw className="h-4 w-4" />Try again
        </button>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-3xl space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[#241715] tracking-tight">Notifications</h1>
          <p className="mt-1 text-sm text-[#957186]">
            {unreadCount > 0
              ? `${unreadCount} unread notification${unreadCount > 1 ? "s" : ""}`
              : "You're all caught up"}
          </p>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          <button
            type="button"
            onClick={fetchNotifications}
            className="p-2 rounded-xl border border-[#d9b8c4]/60 text-[#703d57] hover:bg-[#f7f0f4] transition"
            title="Refresh"
          >
            <RefreshCw className="h-4 w-4" />
          </button>
          {unreadCount > 0 && (
            <button
              type="button"
              onClick={() => void markAllAsRead()}
              disabled={markingAll}
              className="flex items-center gap-1.5 rounded-xl border border-[#d9b8c4]/60 bg-white px-3 py-2 text-xs font-semibold text-[#703d57] hover:bg-[#f7f0f4] disabled:opacity-60 transition"
            >
              {markingAll ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <CheckCheck className="h-3.5 w-3.5" />}
              Mark all read
            </button>
          )}
          {notifications.length > 0 && (
            <button
              type="button"
              onClick={() => void clearAll()}
              disabled={clearingAll}
              className="flex items-center gap-1.5 rounded-xl border border-red-200 bg-white px-3 py-2 text-xs font-semibold text-red-600 hover:bg-red-50 disabled:opacity-60 transition"
            >
              {clearingAll ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Trash2 className="h-3.5 w-3.5" />}
              Clear all
            </button>
          )}
        </div>
      </div>

      {loadError && (
        <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">{loadError}</div>
      )}

      {/* Filter tabs */}
      {notifications.length > 0 && (
        <div className="flex gap-1 p-1 rounded-xl bg-[#f7f0f4] border border-[#d9b8c4]/30 w-fit">
          {(["all", "unread"] as FilterKey[]).map((f) => (
            <button
              key={f}
              type="button"
              onClick={() => setFilter(f)}
              className={cn(
                "flex items-center gap-1.5 px-4 py-2 rounded-lg text-xs font-semibold transition-all",
                filter === f
                  ? "bg-white text-[#703d57] shadow-sm"
                  : "text-[#957186] hover:text-[#703d57]",
              )}
            >
              <Filter className="h-3 w-3" />
              {f === "all" ? `All (${notifications.length})` : `Unread (${unreadCount})`}
            </button>
          ))}
        </div>
      )}

      {/* Notification list */}
      {displayed.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-3xl border border-[#d9b8c4]/40 bg-white py-20 text-center shadow-sm">
          <div className="h-16 w-16 rounded-2xl bg-[#f7f0f4] border border-[#d9b8c4]/40 flex items-center justify-center mb-4">
            <BellOff className="h-7 w-7 text-[#957186]" />
          </div>
          <p className="text-sm font-semibold text-[#241715]">
            {filter === "unread" ? "No unread notifications" : "No notifications yet"}
          </p>
          <p className="text-xs text-[#957186] mt-1 max-w-xs">
            {filter === "unread"
              ? "Switch to 'All' to see your notification history."
              : "When clients book appointments, send messages, or interact with your cases, you'll see updates here."}
          </p>
        </div>
      ) : (
        <div className="space-y-6">
          {groups.map((group) => (
            <div key={group.label}>
              <p className="text-[11px] font-bold uppercase tracking-[0.2em] text-[#957186] mb-3 px-1">
                {group.label}
              </p>
              <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white shadow-sm overflow-hidden divide-y divide-[#f0e4ea]/80">
                {group.items.map((n) => {
                  const Icon = ICON_MAP[n.notification_type] ?? Bell;
                  const iconBg = ICON_BG_MAP[n.notification_type] ?? "bg-[#f7f0f4] text-[#703d57]";
                  return (
                    <button
                      key={n.id}
                      type="button"
                      onClick={() => handleClick(n)}
                      className={cn(
                        "w-full flex items-start gap-3.5 px-5 py-4 text-left transition-colors group",
                        !n.is_read
                          ? "bg-[#fdf8fb] hover:bg-[#f7f0f4]"
                          : "hover:bg-[#fdf8fb]",
                      )}
                    >
                      <div className={cn("h-10 w-10 rounded-xl flex items-center justify-center shrink-0 mt-0.5", iconBg)}>
                        <Icon className="h-5 w-5" strokeWidth={1.75} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <p className={cn(
                            "text-sm leading-snug truncate",
                            !n.is_read ? "font-bold text-[#241715]" : "font-medium text-[#402a2c]",
                          )}>
                            {n.title}
                          </p>
                          <span className="flex items-center gap-1 text-[11px] text-[#957186] whitespace-nowrap shrink-0 mt-0.5">
                            <Clock className="h-3 w-3" />
                            {timeAgo(n.created_at)}
                          </span>
                        </div>
                        {n.body && <p className="text-xs text-[#957186] mt-0.5 leading-relaxed line-clamp-2">{n.body}</p>}
                      </div>
                      {!n.is_read && (
                        <div className="h-2.5 w-2.5 rounded-full bg-[#703d57] shrink-0 mt-2 ring-2 ring-[#703d57]/20" />
                      )}
                    </button>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
