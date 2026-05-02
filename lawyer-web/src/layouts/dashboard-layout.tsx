import { useState } from "react";
import { Outlet, NavLink, useNavigate } from "react-router-dom";
import { signOut } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { useAuth } from "@/features/auth/auth-provider";
import { cn } from "@/lib/cn";
import {
  LayoutDashboard,
  Briefcase,
  CalendarDays,
  MessageSquare,
  FolderOpen,
  LogOut,
  Menu,
  X,
  Scale,
} from "lucide-react";

const navItems = [
  { to: "/",             label: "Home",         icon: LayoutDashboard },
  { to: "/cases",        label: "Cases",        icon: Briefcase },
  { to: "/appointments", label: "Appointments", icon: CalendarDays },
  { to: "/messages",     label: "Messages",     icon: MessageSquare },
  { to: "/documents",    label: "Documents",    icon: FolderOpen },
];

export function DashboardLayout() {
  const navigate = useNavigate();
  const { lawyerState } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const displayName =
    lawyerState?.profile.display_name ??
    lawyerState?.user.first_name ??
    "Lawyer";
  const designation = lawyerState?.profile.designation ?? "";
  const initials = displayName.charAt(0).toUpperCase();

  async function handleSignOut() {
    await signOut(auth);
    navigate("/login", { replace: true });
  }

  return (
    <div className="flex h-screen overflow-hidden bg-[#f7f0f4]">
      {/* Mobile backdrop */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-30 bg-black/40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-40 flex w-56 flex-col transition-transform lg:static lg:translate-x-0",
          "bg-[#241715]",
          sidebarOpen ? "translate-x-0" : "-translate-x-full",
        )}
      >
        {/* Logo */}
        <div className="flex h-16 items-center gap-2.5 px-5 border-b border-white/10">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-[#703d57]">
            <Scale className="h-4 w-4 text-white" />
          </div>
          <span className="text-lg font-bold text-white tracking-wide">CLAiR</span>
          <button
            className="ml-auto lg:hidden"
            onClick={() => setSidebarOpen(false)}
          >
            <X className="h-5 w-5 text-white/60" />
          </button>
        </div>

        {/* Nav */}
        <nav className="flex-1 space-y-0.5 px-3 py-5">
          {navItems.map(({ to, label, icon: Icon }) => (
            <NavLink
              key={to}
              to={to}
              end={to === "/"}
              onClick={() => setSidebarOpen(false)}
              className={({ isActive }) =>
                cn(
                  "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all",
                  isActive
                    ? "bg-[#703d57] text-white"
                    : "text-white/60 hover:bg-white/10 hover:text-white",
                )
              }
            >
              <Icon className="h-4 w-4 shrink-0" />
              {label}
            </NavLink>
          ))}
        </nav>

        {/* User + Sign out */}
        <div className="border-t border-white/10 p-3 space-y-1">
          <div className="flex items-center gap-2.5 px-3 py-2">
            <div className="h-7 w-7 rounded-full bg-[#957186] flex items-center justify-center text-xs font-bold text-white shrink-0">
              {initials}
            </div>
            <div className="min-w-0">
              <p className="text-xs font-semibold text-white truncate">{displayName}</p>
              {designation && (
                <p className="text-[10px] text-white/50 truncate">{designation}</p>
              )}
            </div>
          </div>
          <button
            onClick={handleSignOut}
            className="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-white/60 transition-colors hover:bg-red-900/40 hover:text-red-300"
          >
            <LogOut className="h-4 w-4 shrink-0" />
            Sign out
          </button>
        </div>
      </aside>

      {/* Main area */}
      <div className="flex flex-1 flex-col overflow-hidden">
        {/* Top bar (mobile only) */}
        <header className="flex h-16 items-center gap-4 border-b border-[#d9b8c4]/40 bg-white px-4 lg:hidden">
          <button onClick={() => setSidebarOpen(true)}>
            <Menu className="h-6 w-6 text-[#402a2c]" />
          </button>
          <span className="text-lg font-semibold text-[#241715]">CLAiR</span>
        </header>

        {/* Page content */}
        <main className="flex-1 overflow-y-auto p-4 lg:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}