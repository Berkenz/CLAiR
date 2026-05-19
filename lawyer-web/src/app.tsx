import { Routes, Route, Navigate } from "react-router-dom";
import { useAuth } from "@/features/auth/auth-provider";
import { AuthLayout } from "@/layouts/auth-layout";
import { DashboardLayout } from "@/layouts/dashboard-layout";
import { LoginPage } from "@/features/auth/pages/login-page";
import { ChangePasswordPage } from "@/features/auth/pages/change-password-page";
import { ProfileSetupPage } from "@/features/profile-setup/pages/profile-setup-page";
import { DashboardPage } from "@/features/dashboard/pages/dashboard-page";
import { CasesPage } from "@/features/cases/pages/cases-page";
import { ProfilePage } from "@/features/profile/pages/profile-page";
import { AiAssessmentPage } from "@/features/ai-assessment/pages/ai-assessment-page";
import { NotificationsPage } from "@/features/notifications/pages/notifications-page";
import { getNextStep, hasChangedPassword } from "@/features/auth/onboarding-storage";
import { SplashScreen } from "@/components/splash-screen";


function PublicRoute({ children }: { children: React.ReactNode }) {
  const { firebaseUser, lawyerState, loading } = useAuth();
  if (loading) return <SplashScreen />;
  if (firebaseUser) {
    return (
      <Navigate
        to={getNextStep(firebaseUser.uid, lawyerState?.profile ?? null)}
        replace
      />
    );
  }
  return <>{children}</>;
}

function ChangePasswordRoute({ children }: { children: React.ReactNode }) {
  const { firebaseUser, lawyerState, loading } = useAuth();
  if (loading) return <SplashScreen />;
  if (!firebaseUser) return <Navigate to="/login" replace />;
  const profile = lawyerState?.profile ?? null;
  if (profile && !profile.must_change_password) {
    return <Navigate to={getNextStep(firebaseUser.uid, profile)} replace />;
  }
  if (!profile && hasChangedPassword(firebaseUser.uid)) {
    return <Navigate to={getNextStep(firebaseUser.uid)} replace />;
  }
  return <>{children}</>;
}

function ProfileSetupRoute({ children }: { children: React.ReactNode }) {
  const { firebaseUser, lawyerState, loading } = useAuth();
  if (loading) return <SplashScreen />;
  if (!firebaseUser) return <Navigate to="/login" replace />;
  const profile = lawyerState?.profile ?? null;
  const next = getNextStep(firebaseUser.uid, profile);
  if (next === "/change-password") return <Navigate to="/change-password" replace />;
  if (next === "/") return <Navigate to="/" replace />;
  return <>{children}</>;
}

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { firebaseUser, lawyerState, loading } = useAuth();
  if (loading) return <SplashScreen />;
  if (!firebaseUser) return <Navigate to="/login" replace />;
  const next = getNextStep(firebaseUser.uid, lawyerState?.profile ?? null);
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

      <Route element={<ProtectedRoute><DashboardLayout /></ProtectedRoute>}>
        <Route path="/"               element={<DashboardPage />} />
        <Route path="/cases"          element={<CasesPage />} />
        <Route path="/appointments"   element={<Navigate to="/cases" replace />} />
        <Route path="/availability"   element={<Navigate to="/" replace />} />
        <Route path="/conversations"  element={<Navigate to="/" replace />} />
        <Route path="/documents"      element={<Navigate to="/" replace />} />
        <Route path="/ai-assessment"  element={<AiAssessmentPage />} />
        <Route path="/notifications"  element={<NotificationsPage />} />
        <Route path="/profile"        element={<ProfilePage />} />
      </Route>

      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
}
