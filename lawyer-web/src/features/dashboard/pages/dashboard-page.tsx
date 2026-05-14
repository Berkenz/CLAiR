import { useMemo } from "react";
import { useNavigate } from "react-router-dom";
import {
  Sparkles,
  MessageCircle,
  ClipboardCheck,
  ArrowRight,
  ChevronRight,
  Clock,
  Briefcase,
} from "lucide-react";
import { useAuth } from "@/features/auth/auth-provider";

function formatGreetingName(lawyerState: ReturnType<typeof useAuth>["lawyerState"]): string {
  if (!lawyerState) return "Counselor";
  const dn = lawyerState.profile.display_name?.trim();
  if (dn) return dn;
  const u = lawyerState.user;
  const parts = [u.first_name, u.last_name].filter(Boolean).join(" ").trim();
  if (parts) return `Atty. ${parts}`;
  const local = u.email?.split("@")[0];
  return local ? local.charAt(0).toUpperCase() + local.slice(1) : "Counselor";
}

function formatSubtitle(lawyerState: ReturnType<typeof useAuth>["lawyerState"]): string {
  if (!lawyerState) return "Welcome back — manage cases and CLAiR AI tools from here.";
  const d = lawyerState.profile.designation?.trim();
  const areas = lawyerState.profile.practice_areas?.filter(Boolean) ?? [];
  const areaLine = areas.slice(0, 2).join(" · ");
  if (d && areaLine) return `${d} · ${areaLine}`;
  if (d) return d;
  if (areaLine) return areaLine;
  return "Your CLAiR lawyer portal — cases, appointments, and AI tools in one place.";
}

export function DashboardPage() {
  const navigate = useNavigate();
  const { lawyerState } = useAuth();

  const greetingName = useMemo(() => formatGreetingName(lawyerState), [lawyerState]);
  const subtitle = useMemo(() => formatSubtitle(lawyerState), [lawyerState]);

  const todayLabel = useMemo(
    () =>
      new Date().toLocaleDateString("en-PH", {
        weekday: "long",
        month: "long",
        day: "numeric",
        year: "numeric",
      }),
    [],
  );

  return (
    <div className="mx-auto max-w-6xl space-y-8 pb-12">
      {/* Hero */}
      <section className="relative overflow-hidden rounded-3xl border border-[#d9b8c4]/35 bg-gradient-to-br from-[#fdf8fb] via-white to-[#eedde8]/40 p-6 shadow-sm sm:p-8 md:p-10">
        <div className="pointer-events-none absolute -right-20 -top-20 h-64 w-64 rounded-full bg-[#703d57]/[0.08] blur-3xl" />
        <div className="pointer-events-none absolute -bottom-16 -left-12 h-48 w-48 rounded-full bg-[#703d57]/10 blur-2xl" />

        <div className="relative flex flex-col gap-6 md:flex-row md:items-start md:justify-between">
          <div className="min-w-0 max-w-2xl">
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-[#957186]">
              Lawyer portal
            </p>
            <h1 className="mt-2 text-balance text-2xl font-bold tracking-tight text-[#241715] sm:text-3xl md:text-[2rem] md:leading-tight">
              Hello,{" "}
              <span className="bg-gradient-to-r from-[#703d57] to-[#5a3046] bg-clip-text text-transparent">
                {greetingName}
              </span>
            </h1>
            <p className="mt-3 text-sm leading-relaxed text-[#957186] sm:text-[0.9375rem]">{subtitle}</p>
          </div>
          <div className="flex shrink-0 items-center gap-2 self-start rounded-2xl border border-[#d9b8c4]/50 bg-white/80 px-4 py-2.5 text-xs text-[#703d57] shadow-sm backdrop-blur-sm md:mt-1">
            <Clock className="h-3.5 w-3.5 shrink-0 opacity-70" />
            <span className="font-medium leading-snug text-[#5a3046]">{todayLabel}</span>
          </div>
        </div>
      </section>

      {/* Primary shortcuts */}
      <section aria-labelledby="dash-shortcuts-heading">
        <div className="mb-4 flex flex-wrap items-end justify-between gap-2">
          <div>
            <h2
              id="dash-shortcuts-heading"
              className="text-sm font-bold uppercase tracking-[0.18em] text-[#5a3046]"
            >
              At a glance
            </h2>
            <p className="mt-1 text-xs text-[#957186]">Jump to where you spend most of your time</p>
          </div>
        </div>

        <div className="grid gap-4 md:grid-cols-2 md:gap-5">
          <button
            type="button"
            onClick={() => navigate("/cases")}
            className="group relative flex flex-col overflow-hidden rounded-3xl border border-[#d9b8c4]/40 bg-white p-6 text-left shadow-sm transition-all duration-200 hover:border-[#703d57]/35 hover:shadow-md md:p-7"
          >
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#eedde8] text-[#703d57] transition-transform duration-200 group-hover:scale-105">
              <Briefcase className="h-6 w-6" strokeWidth={1.75} />
            </div>
            <h3 className="mt-5 text-lg font-bold text-[#241715]">Cases & appointments</h3>
            <p className="mt-1.5 max-w-sm text-sm leading-relaxed text-[#957186]">
              Bookings, client messages, and matter details connected to your practice.
            </p>
            <span className="mt-6 inline-flex items-center gap-1 text-sm font-semibold text-[#703d57]">
              Open cases
              <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" />
            </span>
          </button>

          <button
            type="button"
            onClick={() => navigate("/ai-assessment")}
            className="group relative flex flex-col overflow-hidden rounded-3xl border border-[#241715]/15 bg-gradient-to-br from-[#241715] via-[#2d1c20] to-[#402a2c] p-6 text-left text-white shadow-md transition-all duration-200 hover:shadow-lg md:p-7"
          >
            <div className="absolute right-0 top-0 h-32 w-32 translate-x-8 -translate-y-8 rounded-full bg-[#703d57]/25 blur-2xl" />
            <div className="relative flex h-12 w-12 items-center justify-center rounded-2xl bg-[#703d57] shadow-inner">
              <Sparkles className="h-6 w-6 text-white" strokeWidth={1.75} />
            </div>
            <h3 className="relative mt-5 text-lg font-bold">CLAiR AI workspace</h3>
            <p className="relative mt-1.5 max-w-sm text-sm leading-relaxed text-white/65">
              Legal research chat and conversation quality tools in one place.
            </p>
            <span className="relative mt-6 inline-flex items-center gap-1 text-sm font-semibold text-white/95">
              Enter workspace
              <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" />
            </span>
          </button>
        </div>
      </section>

      {/* AI tools */}
      <section aria-labelledby="dash-ai-heading">
        <div className="mb-4 flex flex-wrap items-baseline justify-between gap-2">
          <h2 id="dash-ai-heading" className="text-sm font-bold uppercase tracking-[0.18em] text-[#5a3046]">
            Inside AI workspace
          </h2>
          <p className="text-xs text-[#957186]">Pick a mode — same destination, focused tab</p>
        </div>

        <div className="grid gap-4 sm:grid-cols-2">
          <button
            type="button"
            onClick={() => navigate("/ai-assessment?tab=chat")}
            className="group flex items-center gap-4 rounded-3xl border border-[#d9b8c4]/40 bg-white p-5 text-left shadow-sm transition-all hover:border-[#703d57]/40 hover:bg-[#fdf8fb] hover:shadow-md sm:p-6"
          >
            <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-[#703d57] text-white shadow-sm ring-4 ring-[#703d57]/10 transition-transform group-hover:scale-[1.03]">
              <MessageCircle className="h-5 w-5" strokeWidth={1.75} />
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-sm font-bold text-[#241715]">Chat with CLAiR AI</p>
              <p className="mt-0.5 text-xs leading-relaxed text-[#957186]">
                Research, drafting angles, and quick answers grounded in Philippine law context.
              </p>
            </div>
            <ChevronRight className="h-5 w-5 shrink-0 text-[#d9b8c4] transition-colors group-hover:text-[#703d57]" />
          </button>

          <button
            type="button"
            onClick={() => navigate("/ai-assessment?tab=assessment")}
            className="group flex items-center gap-4 rounded-3xl border border-[#d9b8c4]/40 bg-white p-5 text-left shadow-sm transition-all hover:border-[#703d57]/40 hover:bg-[#fdf8fb] hover:shadow-md sm:p-6"
          >
            <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-[#402a2c] text-white shadow-sm ring-4 ring-[#402a2c]/10 transition-transform group-hover:scale-[1.03]">
              <ClipboardCheck className="h-5 w-5" strokeWidth={1.75} />
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-sm font-bold text-[#241715]">Assess AI conversations</p>
              <p className="mt-0.5 text-xs leading-relaxed text-[#957186]">
                Review client–AI threads and leave structured feedback for quality control.
              </p>
            </div>
            <ChevronRight className="h-5 w-5 shrink-0 text-[#d9b8c4] transition-colors group-hover:text-[#703d57]" />
          </button>
        </div>
      </section>
    </div>
  );
}
