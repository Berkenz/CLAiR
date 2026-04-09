import { FileText, Users, Clock } from "lucide-react";

const stats = [
  { label: "Pending Referrals", value: "—", icon: FileText },
  { label: "Active Clients", value: "—", icon: Users },
  { label: "Recent Consultations", value: "—", icon: Clock },
];

export function DashboardPage() {
  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="mt-1 text-sm text-gray-500">
          Welcome back. Here's an overview of your activity.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {stats.map(({ label, value, icon: Icon }) => (
          <div
            key={label}
            className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm"
          >
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-brand-50">
                <Icon className="h-5 w-5 text-brand-700" />
              </div>
              <div>
                <p className="text-sm text-gray-500">{label}</p>
                <p className="text-2xl font-semibold text-gray-900">{value}</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-gray-900">
          Recent Referrals
        </h2>
        <p className="mt-2 text-sm text-gray-500">
          No referrals yet. When clients request a lawyer referral, they will
          appear here.
        </p>
      </div>
    </div>
  );
}
