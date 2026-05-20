import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import { Outlet, NavLink, useNavigate, useLocation } from "react-router-dom";
import { signOut } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { api } from "@/lib/api";
import { useAuth } from "@/features/auth/auth-provider";
import { cn } from "@/lib/cn";
import {
  LayoutDashboard, Briefcase, Bell, BellRing,
  LogOut, Menu, X, ChevronRight, Sparkles,
} from "lucide-react";
import clairIcon from "@/assets/images/CLAiR-icon.png";
import type { Notification } from "@/features/notifications/pages/notifications-page";

const NotificationBadgeContext = createContext<() => void>(() => {});

/** Call this from any child page to immediately refresh the sidebar/header badge count. */
export function useRefreshNotificationBadge() {
  return useContext(NotificationBadgeContext);
}

const darkBgFilter =
  "brightness(0) saturate(100%) invert(78%) sepia(18%) saturate(400%) hue-rotate(295deg) brightness(105%) contrast(85%)";

const lightBgFilter =
  "brightness(0) saturate(100%) invert(25%) sepia(30%) saturate(800%) hue-rotate(295deg) brightness(80%) contrast(90%)";

const navItems = [
  { to: "/",               label: "Home",           icon: LayoutDashboard },
  { to: "/cases",          label: "Cases",          icon: Briefcase },
  { to: "/ai-assessment",  label: "AI Assessment",  icon: Sparkles },
  { to: "/notifications",  label: "Notifications",  icon: Bell },
];

export function DashboardLayout() {
  const navigate = useNavigate();
  const location = useLocation();
  const { lawyerState } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);
  const prevUnreadRef = useRef<number>(0);
  const primed = useRef(false);
  const [banner, setBanner] = useState<Notification | null>(null);
  const bannerTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const onNotificationsPage = location.pathname === "/notifications";

  const fetchUnreadCount = useCallback(async () => {
    try {
      const { data } = await api.get<{ unread_count: number }>("/lawyer/notifications/unread-count");
      const newCount = data.unread_count;

      if (primed.current && newCount > prevUnreadRef.current && !onNotificationsPage) {
        try {
          const { data: listData } = await api.get<{ notifications: Notification[] }>("/lawyer/notifications");
          const newest = listData.notifications.find((n) => !n.is_read);
          if (newest) {
            setBanner(newest);
            if (bannerTimer.current) clearTimeout(bannerTimer.current);
            bannerTimer.current = setTimeout(() => setBanner(null), 8000);
          }
        } catch { /* silent */ }
      }

      prevUnreadRef.current = newCount;
      primed.current = true;
      setUnreadCount(newCount);
    } catch { /* silent */ }
  }, [onNotificationsPage]);

  useEffect(() => {
    fetchUnreadCount();
    const interval = setInterval(() => void fetchUnreadCount(), 15_000);
    return () => clearInterval(interval);
  }, [fetchUnreadCount]);

  function dismissBanner() {
    if (bannerTimer.current) clearTimeout(bannerTimer.current);
    setBanner(null);
  }

  async function handleBannerClick() {
    if (!banner) return;
    const id = banner.id;
    dismissBanner();
    try {
      await api.patch(`/lawyer/notifications/${id}/read`);
      void fetchUnreadCount();
    } catch { /* silent */ }
    const apptId = banner.payload?.appointment_id;
    if (apptId && banner.notification_type === "new_direct_message") {
      navigate(`/cases?appt=${apptId}&tab=chat`);
    } else if (apptId) {
      navigate(`/cases?appt=${apptId}`);
    } else {
      navigate("/notifications");
    }
  }

  const sidebarUser = useMemo(() => {
    const u = lawyerState?.user;
    const p = lawyerState?.profile;
    const display =
      p?.display_name?.trim() ||
      [u?.first_name, u?.last_name].filter(Boolean).join(" ").trim() ||
      u?.email?.split("@")[0] ||
      "Lawyer";
    const fi = (u?.first_name ?? "").trim().charAt(0);
    const li = (u?.last_name ?? "").trim().charAt(0);
    const initials =
      fi && li ? `${fi}${li}`.toUpperCase() : display.slice(0, 2).toUpperCase() || "?";
    const photoUrl = u?.photo_url?.trim() || null;
    return { display, initials, photoUrl };
  }, [lawyerState]);

  async function handleSignOut() {
    await signOut(auth);
    navigate("/login", { replace: true });
  }

  return (
    <div className="flex h-screen overflow-hidden bg-[#f7f0f4]">
      {sidebarOpen && (
        <div className="fixed inset-0 z-30 bg-black/40 lg:hidden" onClick={() => setSidebarOpen(false)} />
      )}

      <aside className={cn(
        "fixed inset-y-0 left-0 z-40 flex w-56 flex-col transition-transform lg:static lg:translate-x-0",
        "bg-[#241715]",
        sidebarOpen ? "translate-x-0" : "-translate-x-full",
      )}>
        <div className="flex h-16 items-center gap-2.5 px-4 border-b border-white/10">
          <img
            src={clairIcon}
            alt="CLAiR"
            className="h-8 w-8 object-contain shrink-0"
            style={{ filter: darkBgFilter }}
          />
          <span className="text-lg font-bold text-white tracking-wide">CLAiR</span>
          <button className="ml-auto lg:hidden" onClick={() => setSidebarOpen(false)}>
            <X className="h-5 w-5 text-white/60" />
          </button>
        </div>

        <nav className="flex-1 space-y-0.5 px-3 py-5 overflow-y-auto">
          {navItems.map(({ to, label, icon: Icon }) => (
            <NavLink
              key={to}
              to={to}
              end={to === "/"}
              onClick={() => {
                setSidebarOpen(false);
                if (to === "/notifications") void fetchUnreadCount();
              }}
              className={({ isActive }) => cn(
                "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all",
                isActive
                  ? "bg-[#703d57] text-white"
                  : "text-white/60 hover:bg-white/10 hover:text-white",
              )}
            >
              <span className="relative shrink-0">
                <Icon className="h-4 w-4" />
                {to === "/notifications" && unreadCount > 0 && (
                  <span className="absolute -top-1.5 -right-1.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-red-500 px-1 text-[9px] font-bold text-white ring-2 ring-[#241715]">
                    {unreadCount > 99 ? "99+" : unreadCount}
                  </span>
                )}
              </span>
              {label}
              {to === "/notifications" && unreadCount > 0 && (
                <span className="ml-auto rounded-full bg-red-500/20 px-2 py-0.5 text-[10px] font-bold text-red-300">
                  {unreadCount > 99 ? "99+" : unreadCount}
                </span>
              )}
            </NavLink>
          ))}
        </nav>

        <div className="border-t border-white/10 p-3 space-y-1">
          <NavLink
            to="/profile"
            onClick={() => setSidebarOpen(false)}
            className={({ isActive }) => cn(
              "flex items-center gap-2.5 px-3 py-2 rounded-lg transition-colors w-full group",
              isActive ? "bg-white/10" : "hover:bg-white/10"
            )}
          >
            {sidebarUser.photoUrl ? (
              <img
                key={sidebarUser.photoUrl}
                src={sidebarUser.photoUrl}
                alt=""
                className="h-7 w-7 rounded-full object-cover shrink-0 ring-1 ring-white/20"
              />
            ) : (
              <div className="h-7 w-7 rounded-full bg-[#957186] flex items-center justify-center text-xs font-bold text-white shrink-0">
                {sidebarUser.initials}
              </div>
            )}
            <div className="min-w-0 flex-1">
              <p className="text-xs font-semibold text-white truncate">{sidebarUser.display}</p>
              <p className="text-[10px] text-white/50 truncate">View profile</p>
            </div>
            <ChevronRight className="h-3.5 w-3.5 text-white/30 group-hover:text-white/60 transition-colors shrink-0" />
          </NavLink>

          <button
            onClick={handleSignOut}
            className="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-white/60 transition-colors hover:bg-red-900/40 hover:text-red-300"
          >
            <LogOut className="h-4 w-4 shrink-0" />
            Sign out
          </button>
        </div>
      </aside>

      <div className="flex flex-1 flex-col overflow-hidden relative">
        {/* Notification toast — bottom-right, Windows-style */}
        <div
          className={cn(
            "fixed bottom-5 right-5 z-50 w-80 transition-all duration-300 pointer-events-none",
            banner
              ? "translate-y-0 opacity-100"
              : "translate-y-4 opacity-0 pointer-events-none",
          )}
        >
          <button
            type="button"
            onClick={handleBannerClick}
            className="pointer-events-auto flex w-full items-start gap-3 rounded-xl border border-[#d9b8c4]/50 bg-white p-4 shadow-2xl ring-1 ring-black/5 transition-all hover:shadow-xl hover:border-[#703d57]/30 text-left"
          >
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-[#703d57] text-white">
              <BellRing className="h-4.5 w-4.5" strokeWidth={1.75} />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-[#241715] truncate">{banner?.title}</p>
              {banner?.body && (
                <p className="text-xs text-[#6b5060] mt-0.5 line-clamp-2 leading-relaxed">{banner.body}</p>
              )}
              <p className="text-[10px] text-[#957186] mt-1.5">Click to view</p>
            </div>
            <button
              type="button"
              onClick={(e) => { e.stopPropagation(); dismissBanner(); }}
              className="shrink-0 -mt-1 -mr-1 p-1 rounded-md text-[#957186] hover:text-[#402a2c] hover:bg-[#f7f0f4] transition-colors"
            >
              <X className="h-3.5 w-3.5" />
            </button>
          </button>
        </div>

        <header className="flex h-16 items-center gap-3 border-b border-[#d9b8c4]/40 bg-white px-4 lg:hidden">
          <button onClick={() => setSidebarOpen(true)}>
            <Menu className="h-6 w-6 text-[#402a2c]" />
          </button>
          <img
            src={clairIcon}
            alt="CLAiR"
            className="h-7 w-7 object-contain"
            style={{ filter: lightBgFilter }}
          />
          <span className="text-lg font-semibold text-[#241715]">CLAiR</span>
          <button
            onClick={() => { navigate("/notifications"); void fetchUnreadCount(); }}
            className="relative ml-auto p-2 rounded-xl text-[#703d57] hover:bg-[#f7f0f4] transition-colors"
            title="Notifications"
          >
            <Bell className="h-5 w-5" />
            {unreadCount > 0 && (
              <span className="absolute top-1 right-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-red-500 px-1 text-[9px] font-bold text-white ring-2 ring-white">
                {unreadCount > 99 ? "99+" : unreadCount}
              </span>
            )}
          </button>
        </header>
        <main className="flex-1 overflow-y-auto p-4 lg:p-8">
          <NotificationBadgeContext.Provider value={fetchUnreadCount}>
            <Outlet />
          </NotificationBadgeContext.Provider>
        </main>
      </div>
    </div>
  );
}