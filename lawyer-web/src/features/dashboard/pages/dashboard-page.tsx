import { Briefcase, CalendarDays, MessageSquare, FolderOpen } from "lucide-react";

const stats = [
  { label: "Active Cases",   value: "67", sub: "+2 this month",  icon: Briefcase,      color: "bg-[#703d57]" },
  { label: "Appointments",   value: "6",  sub: "This week",      icon: CalendarDays,   color: "bg-[#957186]" },
  { label: "Messages",       value: "3",  sub: "Unread",         icon: MessageSquare,  color: "bg-[#402a2c]" },
  { label: "Documents",      value: "28", sub: "Generated",      icon: FolderOpen,     color: "bg-[#703d57]" },
];

const recentCases = [
  { initials: "ML", name: "Mijares vs. Lumbab",    type: "Property Dispute",  status: "Active",  statusColor: "bg-emerald-100 text-emerald-700" },
  { initials: "CF", name: "Cutamora Family Trust", type: "Estate Planning",   status: "Pending", statusColor: "bg-amber-100 text-amber-700" },
  { initials: "EL", name: "Eroja Labor",            type: "Employment Law",    status: "Active",  statusColor: "bg-emerald-100 text-emerald-700" },
  { initials: "CM", name: "Cadampog Marriage",      type: "Family Law",        status: "Closed",  statusColor: "bg-gray-100 text-gray-500" },
];

const schedule = [
  { time: "9:00",  client: "Mark Grayson",   note: "Initial Consultation" },
  { time: "11:30", client: "Randy Beans",    note: "Document Review" },
  { time: "14:00", client: "Ben Poindexter", note: "Follow-Up" },
  { time: "16:30", client: "Billy Buther",   note: "Hearing Preparation" },
];

const avatarColors = ["bg-[#703d57]", "bg-[#957186]", "bg-[#402a2c]", "bg-[#d9b8c4] text-[#402a2c]"];

export function DashboardPage() {
  return (
    <div className="space-y-6 max-w-6xl mx-auto">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-[#241715]">Dashboard</h1>
        <p className="mt-0.5 text-sm text-[#957186]">Overview of your practice</p>
      </div>

      {/* Stats */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map(({ label, value, sub, icon: Icon, color }) => (
          <div
            key={label}
            className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-5 shadow-sm"
          >
            <div className={`inline-flex h-9 w-9 items-center justify-center rounded-xl ${color} mb-3`}>
              <Icon className="h-4 w-4 text-white" />
            </div>
            <p className="text-sm text-[#957186] font-medium">{label}</p>
            <p className="text-3xl font-bold text-[#241715] mt-0.5">{value}</p>
            <p className="text-xs text-gray-400 mt-1">{sub}</p>
          </div>
        ))}
      </div>

      {/* Bottom two panels */}
      <div className="grid gap-4 lg:grid-cols-2">
        {/* Recent Cases */}
        <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-6 shadow-sm">
          <div className="flex items-center justify-between mb-5">
            <h2 className="font-semibold text-[#241715]">Recent Cases</h2>
            <a href="/cases" className="text-sm text-[#703d57] hover:underline font-medium">See all</a>
          </div>
          <div className="space-y-1">
            {recentCases.map(({ initials, name, type, status, statusColor }, i) => (
              <div key={name} className="flex items-center gap-3 py-3 border-b border-gray-100 last:border-0">
                <div className={`h-9 w-9 rounded-full flex items-center justify-center text-xs font-bold text-white shrink-0 ${avatarColors[i % avatarColors.length]}`}>
                  {initials}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-[#241715] truncate">{name}</p>
                  <p className="text-xs text-gray-400">{type}</p>
                </div>
                <span className={`text-xs font-medium px-2.5 py-1 rounded-full ${statusColor}`}>
                  {status}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Today's Schedule */}
        <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-6 shadow-sm">
          <div className="flex items-center justify-between mb-5">
            <h2 className="font-semibold text-[#241715]">Today's Schedule</h2>
            <a href="/appointments" className="text-sm text-[#703d57] hover:underline font-medium">View all</a>
          </div>
          <div className="space-y-1">
            {schedule.map(({ time, client, note }) => (
              <div key={time} className="flex items-center gap-4 py-3 border-b border-gray-100 last:border-0">
                <span className="w-12 text-sm font-bold text-[#703d57] shrink-0">{time}</span>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-[#241715]">{client}</p>
                </div>
                <span className="text-xs text-gray-400 shrink-0">{note}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}