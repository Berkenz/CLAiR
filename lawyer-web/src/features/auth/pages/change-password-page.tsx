import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { updatePassword } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { api } from "@/lib/api";
import { useAuth, type LawyerState } from "@/features/auth/auth-provider";
import { markPasswordChanged } from "@/app";
import { Scale, Eye, EyeOff } from "lucide-react";

const MIN_LENGTH = 8;

export function ChangePasswordPage() {
  const navigate = useNavigate();
  const { setLawyerState } = useAuth();
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showNew, setShowNew] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
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
    if (validationError) { setError(validationError); return; }

    setError(null);
    setLoading(true);

    try {
      const currentUser = auth.currentUser;
      if (!currentUser) throw new Error("Not authenticated");

      // Step 1 — Update Firebase password
      await updatePassword(currentUser, newPassword);

      // Step 2 — Mark step complete in localStorage (works without backend)
      markPasswordChanged(currentUser.uid);

      // Step 3 — Notify backend (best effort — never blocks navigation)
      try {
        const token = await currentUser.getIdToken(true);
        const { data } = await api.post<LawyerState>(
          "/lawyer/auth/confirm-password-change",
          null,
          { headers: { Authorization: `Bearer ${token}` } },
        );
        setLawyerState(data);
      } catch {
        // Backend not up yet — that's fine, flow continues
      }

      // Step 4 — Always proceed to profile setup
      navigate("/profile-setup", { replace: true });

    } catch (err: unknown) {
      if (err instanceof Error && err.message.includes("requires-recent-login")) {
        setError("Your session has expired. Please log out and log in again.");
      } else {
        setError("Failed to change password. Please try again.");
      }
    } finally {
      setLoading(false);
    }
  }

  function getStrength(): { level: number; label: string; color: string } {
    const p = newPassword;
    if (!p) return { level: 0, label: "", color: "" };
    let score = 0;
    if (p.length >= 8) score++;
    if (p.length >= 12) score++;
    if (/[A-Z]/.test(p)) score++;
    if (/[0-9]/.test(p)) score++;
    if (/[^A-Za-z0-9]/.test(p)) score++;
    if (score <= 1) return { level: 1, label: "Weak", color: "bg-red-400" };
    if (score <= 3) return { level: 2, label: "Fair", color: "bg-amber-400" };
    return { level: 3, label: "Strong", color: "bg-emerald-500" };
  }

  const strength = getStrength();

  return (
    <div className="min-h-screen flex bg-[#f7f0f4]">
      <div className="hidden lg:flex w-[420px] flex-col justify-between bg-[#241715] p-12 flex-shrink-0">
        <div className="flex items-center gap-3">
          <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-[#703d57]">
            <Scale className="h-5 w-5 text-white" />
          </div>
          <span className="text-xl font-bold text-white tracking-wide">CLAiR</span>
        </div>
        <div>
          <blockquote className="text-[#d9b8c4] text-lg leading-relaxed font-light italic mb-6">
            "Justice is the constant and perpetual will to allot to every man his due."
          </blockquote>
          <p className="text-[#957186] text-sm">— Justinian I</p>
        </div>
        <div className="space-y-3">
          <div className="flex items-center gap-3">
            <div className="h-px flex-1 bg-white/10" />
            <span className="text-xs text-white/30 uppercase tracking-widest">Powered by AI</span>
            <div className="h-px flex-1 bg-white/10" />
          </div>
          <p className="text-xs text-white/25 text-center leading-relaxed">
            CLAiR is an AI-assisted legal practice management platform built for Filipino lawyers.
          </p>
        </div>
      </div>

      <div className="flex flex-1 items-center justify-center px-6 py-12">
        <div className="w-full max-w-sm">
          <div className="flex items-center gap-2.5 mb-10 lg:hidden">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-[#703d57]">
              <Scale className="h-4 w-4 text-white" />
            </div>
            <span className="text-lg font-bold text-[#241715] tracking-wide">CLAiR</span>
          </div>

          <div className="mb-8">
            <h1 className="text-2xl font-bold text-[#241715]">Set your password</h1>
            <p className="mt-1.5 text-sm text-[#957186]">
              Your account was created with a temporary password. Please set a new password before continuing.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-5">
            {error && (
              <div className="rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
                {error}
              </div>
            )}

            <div className="space-y-1.5">
              <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide">
                New password
              </label>
              <div className="relative">
                <input
                  id="new-password"
                  type={showNew ? "text" : "password"}
                  required
                  minLength={MIN_LENGTH}
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder="Minimum 8 characters"
                  className="w-full rounded-xl border border-[#d9b8c4] bg-white px-4 py-3 pr-11 text-sm text-[#241715] placeholder-[#c490aa] outline-none transition focus:border-[#703d57] focus:ring-2 focus:ring-[#703d57]/10"
                />
                <button type="button" onClick={() => setShowNew((v) => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-[#957186] hover:text-[#703d57] transition">
                  {showNew ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
              {newPassword && (
                <div className="space-y-1 pt-1">
                  <div className="flex gap-1">
                    {[1, 2, 3].map((n) => (
                      <div key={n} className={`h-1 flex-1 rounded-full transition-all ${strength.level >= n ? strength.color : "bg-[#d9b8c4]"}`} />
                    ))}
                  </div>
                  <p className={`text-xs font-medium ${strength.level === 1 ? "text-red-500" : strength.level === 2 ? "text-amber-500" : "text-emerald-600"}`}>
                    {strength.label}
                  </p>
                </div>
              )}
            </div>

            <div className="space-y-1.5">
              <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide">
                Confirm new password
              </label>
              <div className="relative">
                <input
                  id="confirm-password"
                  type={showConfirm ? "text" : "password"}
                  required
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="Re-enter your new password"
                  className="w-full rounded-xl border border-[#d9b8c4] bg-white px-4 py-3 pr-11 text-sm text-[#241715] placeholder-[#c490aa] outline-none transition focus:border-[#703d57] focus:ring-2 focus:ring-[#703d57]/10"
                />
                <button type="button" onClick={() => setShowConfirm((v) => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-[#957186] hover:text-[#703d57] transition">
                  {showConfirm ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
              {confirmPassword && (
                <p className={`text-xs font-medium ${newPassword === confirmPassword ? "text-emerald-600" : "text-red-500"}`}>
                  {newPassword === confirmPassword ? "Passwords match" : "Passwords do not match"}
                </p>
              )}
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full rounded-xl bg-[#703d57] py-3 text-sm font-semibold text-white transition hover:bg-[#5a3046] disabled:opacity-60 disabled:cursor-not-allowed"
            >
              {loading ? "Saving..." : "Set new password"}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}