import { Routes, Route, Navigate } from "react-router-dom";
import { useAuth } from "@/features/auth/auth-provider";
import { AuthLayout } from "@/layouts/auth-layout";
import { DashboardLayout } from "@/layouts/dashboard-layout";
import { LoginPage } from "@/features/auth/pages/login-page";
import { ChangePasswordPage } from "@/features/auth/pages/change-password-page";
import { ProfileSetupPage } from "@/features/profile-setup/pages/profile-setup-page";
import { DashboardPage } from "@/features/dashboard/pages/dashboard-page";
import { ConversationsPage } from "@/features/conversations/pages/conversations-page";
import { DocumentsPage } from "@/features/documents/pages/documents-page";
import { ProfilePage } from "@/features/profile/pages/profile-page";
import { AiAssessmentPage } from "@/features/ai-assessment/pages/ai-assessment-page";

function flowKey(uid: string, step: "passwordChanged" | "profileComplete") {
  return `clair_${uid}_${step}`;
}
export function markPasswordChanged(uid: string) {
  localStorage.setItem(flowKey(uid, "passwordChanged"), "true");
}
export function markProfileComplete(uid: string) {
  localStorage.setItem(flowKey(uid, "profileComplete"), "true");
}
function hasChangedPassword(uid: string) {
  return localStorage.getItem(flowKey(uid, "passwordChanged")) === "true";
}
function hasCompletedProfile(uid: string) {
  return localStorage.getItem(flowKey(uid, "profileComplete")) === "true";
}
function getNextStep(uid: string): "/change-password" | "/profile-setup" | "/" {
  if (!hasChangedPassword(uid)) return "/change-password";
  if (!hasCompletedProfile(uid)) return "/profile-setup";
  return "/";
}

function Spinner() {
  return (
    <div className="flex h-screen items-center justify-center bg-[#241715]">
      <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#957186] border-t-transparent" />
    </div>
  );
}

function useAuthStatus() {
  const { firebaseUser, loading } = useAuth();
  return { firebaseUser, isLoggedIn: !!firebaseUser, loading };
}

function PublicRoute({ children }: { children: React.ReactNode }) {
  const { firebaseUser, isLoggedIn, loading } = useAuthStatus();
  if (loading) return <Spinner />;
  if (isLoggedIn && firebaseUser) return <Navigate to={getNextStep(firebaseUser.uid)} replace />;
  return <>{children}</>;
}

function ChangePasswordRoute({ children }: { children: React.ReactNode }) {
  const { firebaseUser, isLoggedIn, loading } = useAuthStatus();
  if (loading) return <Spinner />;
  if (!isLoggedIn || !firebaseUser) return <Navigate to="/login" replace />;
  if (hasChangedPassword(firebaseUser.uid)) return <Navigate to={getNextStep(firebaseUser.uid)} replace />;
  return <>{children}</>;
}

function ProfileSetupRoute({ children }: { children: React.ReactNode }) {
  const { firebaseUser, isLoggedIn, loading } = useAuthStatus();
  if (loading) return <Spinner />;
  if (!isLoggedIn || !firebaseUser) return <Navigate to="/login" replace />;
  if (!hasChangedPassword(firebaseUser.uid)) return <Navigate to="/change-password" replace />;
  if (hasCompletedProfile(firebaseUser.uid)) return <Navigate to="/" replace />;
  return <>{children}</>;
}

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { firebaseUser, isLoggedIn, loading } = useAuthStatus();
  if (loading) return <Spinner />;
  if (!isLoggedIn || !firebaseUser) return <Navigate to="/login" replace />;
  const next = getNextStep(firebaseUser.uid);
  if (next !== "/") return <Navigate to={next} replace />;
  return <>{children}</>;
}

export function App() {
  return (
    <Routes>
      {/* Auth flow */}
      <Route element={<AuthLayout />}>
        <Route path="/login" element={<PublicRoute><LoginPage /></PublicRoute>} />
      </Route>
      <Route path="/change-password" element={<ChangePasswordRoute><ChangePasswordPage /></ChangePasswordRoute>} />
      <Route path="/profile-setup"   element={<ProfileSetupRoute><ProfileSetupPage /></ProfileSetupRoute>} />

      {/* Dashboard — 4 tabs only */}
      <Route element={<ProtectedRoute><DashboardLayout /></ProtectedRoute>}>
        <Route path="/"               element={<DashboardPage />} />
        <Route path="/conversations"  element={<ConversationsPage />} />
        <Route path="/documents"      element={<DocumentsPage />} />
        <Route path="/ai-assessment"  element={<AiAssessmentPage />} />
        <Route path="/profile"        element={<ProfilePage />} />
      </Route>

      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
}