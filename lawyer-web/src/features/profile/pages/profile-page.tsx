import { useAuth } from "@/features/auth/auth-provider";

export function ProfilePage() {
  const { user } = useAuth();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Profile</h1>
        <p className="mt-1 text-sm text-gray-500">
          Manage your account information.
        </p>
      </div>

      <div className="max-w-2xl rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-500">
              Email
            </label>
            <p className="mt-1 text-sm text-gray-900">
              {user?.email ?? "—"}
            </p>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-500">
              Display Name
            </label>
            <p className="mt-1 text-sm text-gray-900">
              {user?.displayName ?? "—"}
            </p>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-500">
              UID
            </label>
            <p className="mt-1 font-mono text-xs text-gray-400">
              {user?.uid ?? "—"}
            </p>
          </div>
        </div>

        <p className="mt-6 text-xs text-gray-400">
          Profile editing will be available in a future update.
        </p>
      </div>
    </div>
  );
}
