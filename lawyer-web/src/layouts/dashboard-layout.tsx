import { useMemo, useState } from "react";
import { Outlet, NavLink, useNavigate } from "react-router-dom";
import { signOut } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { useAuth } from "@/features/auth/auth-provider";
import { cn } from "@/lib/cn";
import {
  LayoutDashboard, Briefcase,
  LogOut, Menu, X, ChevronRight, Sparkles,
} from "lucide-react";
import clairIcon from "@/assets/images/CLAiR-icon.png";

const darkBgFilter =
  "brightness(0) saturate(100%) invert(78%) sepia(18%) saturate(400%) hue-rotate(295deg) brightness(105%) contrast(85%)";

const lightBgFilter =
  "brightness(0) saturate(100%) invert(25%) sepia(30%) saturate(800%) hue-rotate(295deg) brightness(80%) contrast(90%)";

const navItems = [
  { to: "/",               label: "Home",           icon: LayoutDashboard },
  { to: "/cases",          label: "Cases",          icon: Briefcase },
  { to: "/ai-assessment",  label: "AI Assessment",  icon: Sparkles },
];

export function DashboardLayout() {
  const navigate = useNavigate();
  const { lawyerState } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(false);

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
              onClick={() => setSidebarOpen(false)}
              className={({ isActive }) => cn(
                "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all",
                isActive
                  ? "bg-[#703d57] text-white"
                  : "text-white/60 hover:bg-white/10 hover:text-white",
              )}
            >
              <Icon className="h-4 w-4 shrink-0" />
              {label}
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

      <div className="flex flex-1 flex-col overflow-hidden">
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
        </header>
        <main className="flex-1 overflow-y-auto p-4 lg:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}