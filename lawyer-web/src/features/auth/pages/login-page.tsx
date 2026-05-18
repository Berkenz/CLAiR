import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { signInWithEmailAndPassword, signOut } from "firebase/auth";
import { Eye, EyeOff } from "lucide-react";
import { auth } from "@/lib/firebase";
import { api } from "@/lib/api";
import {
  clearPasswordChanged,
  clearProfileComplete,
  markPasswordChanged,
  markProfileComplete,
} from "@/features/auth/onboarding-storage";
import { useAuth, type LawyerState } from "@/features/auth/auth-provider";
import clairIcon from "@/assets/images/CLAiR-icon.png";

const darkBgFilter =
  "brightness(0) saturate(100%) invert(78%) sepia(18%) saturate(400%) hue-rotate(295deg) brightness(105%) contrast(85%)";

const lightBgFilter =
  "brightness(0) saturate(100%) invert(25%) sepia(30%) saturate(800%) hue-rotate(295deg) brightness(80%) contrast(90%)";

export function LoginPage() {
  const navigate = useNavigate();
  const { setLawyerState } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const credential = await signInWithEmailAndPassword(auth, email, password);
      const uid = credential.user.uid;
      const token = await credential.user.getIdToken();
      const { data } = await api.post<LawyerState>("/lawyer/auth/login", {
        firebase_token: token,
      });
      setLawyerState(data);

      // Keep local onboarding flags aligned with the backend (stale keys redirect incorrectly).
      if (data.profile.must_change_password) {
        clearPasswordChanged(uid);
        clearProfileComplete(uid);
      } else {
        markPasswordChanged(uid);
      }
      if (data.profile.is_profile_complete) {
        markProfileComplete(uid);
      } else {
        clearProfileComplete(uid);
      }

      if (data.profile.must_change_password) {
        navigate("/change-password", { replace: true });
      } else if (!data.profile.is_profile_complete) {
        navigate("/profile-setup", { replace: true });
      } else {
        navigate("/", { replace: true });
      }
    } catch (err: any) {
      await signOut(auth).catch(() => undefined);
      if (err.code === "auth/invalid-credential" || err.code === "auth/wrong-password" || err.code === "auth/user-not-found") {
        setError("Invalid email or password. Please try again.");
      } else if (err.code === "auth/too-many-requests") {
        setError("Too many attempts. Please try again later.");
      } else if (err.response?.status >= 400 && err.response?.status < 500) {
        const detail = err.response?.data?.detail;
        setError(
          typeof detail === "string"
            ? detail
            : "Could not complete sign-in. Please try again.",
        );
      } else {
        setError("Invalid email or password. Please try again.");
      }
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen flex bg-[#f7f0f4]">
      {/* Left decorative panel */}
      <div className="hidden lg:flex w-[420px] flex-col justify-between bg-[#241715] p-12 flex-shrink-0">
        <div className="flex items-center gap-3">
          <img
            src={clairIcon}
            alt="CLAiR"
            className="h-9 w-9 object-contain"
            style={{ filter: darkBgFilter }}
          />
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

      {/* Right login form */}
      <div className="flex flex-1 items-center justify-center px-6 py-12">
        <div className="w-full max-w-sm">
          {/* Mobile logo */}
          <div className="flex items-center gap-2.5 mb-10 lg:hidden">
            <img
              src={clairIcon}
              alt="CLAiR"
              className="h-8 w-8 object-contain"
              style={{ filter: lightBgFilter }}
            />
            <span className="text-lg font-bold text-[#241715] tracking-wide">CLAiR</span>
          </div>

          <div className="mb-8">
            <h1 className="text-2xl font-bold text-[#241715]">Welcome back</h1>
            <p className="mt-1.5 text-sm text-[#957186]">
              Sign in with the credentials provided to you.
            </p>
          </div>

          <form onSubmit={handleLogin} className="space-y-5">
            <div className="space-y-1.5">
              <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide">
                Email address
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
                placeholder="your@email.com"
                className="w-full rounded-xl border border-[#d9b8c4] bg-white px-4 py-3 text-sm text-[#241715] placeholder-[#c490aa] outline-none transition focus:border-[#703d57] focus:ring-2 focus:ring-[#703d57]/10"
              />
            </div>

            <div className="space-y-1.5">
              <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide">
                Password
              </label>
              <div className="relative">
                <input
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  autoComplete="current-password"
                  placeholder="••••••••"
                  className="w-full rounded-xl border border-[#d9b8c4] bg-white px-4 py-3 pr-11 text-sm text-[#241715] outline-none transition focus:border-[#703d57] focus:ring-2 focus:ring-[#703d57]/10"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((v) => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-[#957186] hover:text-[#703d57] transition"
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
            </div>

            {error && (
              <div className="rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full rounded-xl bg-[#703d57] py-3 text-sm font-semibold text-white transition hover:bg-[#5a3046] disabled:opacity-60 disabled:cursor-not-allowed"
            >
              {loading ? "Signing in…" : "Sign in"}
            </button>
          </form>

          <p className="mt-8 text-center text-xs text-[#957186]">
            Don't have credentials?{" "}
            <span className="text-[#703d57] font-medium">
              Contact your CLAiR administrator.
            </span>
          </p>
        </div>
      </div>
    </div>
  );
}