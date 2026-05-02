import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { updatePassword } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { api } from "@/lib/api";
import { useAuth, type LawyerState } from "@/features/auth/auth-provider";

const MIN_LENGTH = 8;

export function ChangePasswordPage() {
  const navigate = useNavigate();
  const { setLawyerState } = useAuth();
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  function validate(): string | null {
    if (newPassword.length < MIN_LENGTH)
      return `Password must be at least ${MIN_LENGTH} characters.`;
    if (newPassword !== confirmPassword)
      return "Passwords do not match.";
    return null;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const validationError = validate();
    if (validationError) {
      setError(validationError);
      return;
    }

    setError(null);
    setLoading(true);

    try {
      const currentUser = auth.currentUser;
      if (!currentUser) throw new Error("Not authenticated");

      await updatePassword(currentUser, newPassword);

      const token = await currentUser.getIdToken(true);
      const { data } = await api.post<LawyerState>(
        "/lawyer/auth/confirm-password-change",
        null,
        { headers: { Authorization: `Bearer ${token}` } },
      );

      setLawyerState(data);
      navigate("/profile-setup", { replace: true });
    } catch (err: unknown) {
      const detail =
        err instanceof Error &&
        (err as { response?: { data?: { detail?: string } } }).response?.data?.detail;
      if (detail) {
        setError(detail);
      } else if (
        err instanceof Error &&
        err.message.includes("requires-recent-login")
      ) {
        setError("Your session has expired. Please log out and log in again.");
      } else {
        setError("Failed to change password. Please try again.");
      }
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 px-4">
      <div className="w-full max-w-md space-y-8">
        <div className="text-center">
          <h1 className="text-3xl font-bold tracking-tight text-brand-900">
            CLAiR
          </h1>
          <p className="mt-2 text-sm text-gray-500">
            Set your new password to continue
          </p>
        </div>

        <div className="rounded-xl border border-gray-200 bg-white p-8 shadow-sm">
          <div className="mb-6">
            <h2 className="text-lg font-semibold text-gray-900">
              Change your password
            </h2>
            <p className="mt-1 text-sm text-gray-500">
              Your account was created with a temporary password. Please set a
              new password before continuing.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-5">
            {error && (
              <div className="rounded-lg bg-red-50 px-4 py-3 text-sm text-red-700">
                {error}
              </div>
            )}

            <div>
              <label
                htmlFor="new-password"
                className="block text-sm font-medium text-gray-700"
              >
                New password
              </label>
              <input
                id="new-password"
                type="password"
                required
                minLength={MIN_LENGTH}
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                className="mt-1.5 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-brand-500 focus:ring-1 focus:ring-brand-500 focus:outline-none"
                placeholder="Minimum 8 characters"
              />
            </div>

            <div>
              <label
                htmlFor="confirm-password"
                className="block text-sm font-medium text-gray-700"
              >
                Confirm new password
              </label>
              <input
                id="confirm-password"
                type="password"
                required
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                className="mt-1.5 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-brand-500 focus:ring-1 focus:ring-brand-500 focus:outline-none"
                placeholder="Re-enter your new password"
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full rounded-lg bg-brand-700 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-brand-800 focus:ring-2 focus:ring-brand-500 focus:ring-offset-2 focus:outline-none disabled:opacity-50"
            >
              {loading ? "Saving..." : "Set new password"}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
