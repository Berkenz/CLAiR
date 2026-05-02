import { Users } from "lucide-react";

export function ClientsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Clients</h1>
        <p className="mt-1 text-sm text-gray-500">
          View and manage your connected clients.
        </p>
      </div>

      <div className="flex flex-col items-center justify-center rounded-xl border border-dashed border-gray-300 bg-white py-16">
        <Users className="h-12 w-12 text-gray-300" />
        <h3 className="mt-4 text-sm font-semibold text-gray-900">
          No clients yet
        </h3>
        <p className="mt-1 max-w-sm text-center text-sm text-gray-500">
          Clients who are referred to you will appear here once the referral
          system is active.
        </p>
      </div>
    </div>
  );
}
