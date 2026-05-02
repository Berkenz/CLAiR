import { Navigate, Route, Routes } from "react-router-dom";
import { useAuth } from "@/features/auth/auth-provider";
import { AuthLayout } from "@/layouts/auth-layout";
import { DashboardLayout } from "@/layouts/dashboard-layout";
import { LoginPage } from "@/features/auth/pages/login-page";
import { ChangePasswordPage } from "@/features/auth/pages/change-password-page";
import { ProfileSetupPage } from "@/features/profile-setup/pages/profile-setup-page";
import { DashboardPage } from "@/features/dashboard/pages/dashboard-page";
import { CasesPage } from "@/features/cases/pages/cases-page";
import { AppointmentsPage } from "@/features/appointments/pages/appointments-page";
import { MessagesPage } from "@/features/messages/pages/messages-page";
import { DocumentsPage } from "@/features/documents/pages/documents-page";

function Spinner() {
  return (
    <div className="flex h-screen items-center justify-center bg-gray-50">
      <div className="h-8 w-8 animate-spin rounded-full border-4 border-brand-500 border-t-transparent" />
    </div>
  );
}

/**
 * Guards that require a Firebase-authenticated lawyer account.
 * Redirects to /login if not signed in.
 * After sign-in, enforces the setup funnel:
 *   must_change_password  → /change-password
 *   !is_profile_complete  → /profile-setup
 *   fully set up          → dashboard
 */
function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { firebaseUser, lawyerState, loading } = useAuth();

  if (loading) return <Spinner />;

  if (!firebaseUser) return <Navigate to="/login" replace />;

  if (lawyerState?.profile.must_change_password) {
    return <Navigate to="/change-password" replace />;
  }

  if (lawyerState && !lawyerState.profile.is_profile_complete) {
    return <Navigate to="/profile-setup" replace />;
  }

  return <>{children}</>;
}

/**
 * Guards the change-password and profile-setup steps.
 * Prevents accessing a step that is already done or not yet unlocked.
 */
function SetupRoute({
  step,
  children,
}: {
  step: "change-password" | "profile-setup";
  children: React.ReactNode;
}) {
  const { firebaseUser, lawyerState, loading } = useAuth();

  if (loading) return <Spinner />;

  if (!firebaseUser) return <Navigate to="/login" replace />;

  if (!lawyerState) return <Spinner />;

  if (step === "change-password") {
    if (!lawyerState.profile.must_change_password) {
      return lawyerState.profile.is_profile_complete
        ? <Navigate to="/" replace />
        : <Navigate to="/profile-setup" replace />;
    }
  }

  if (step === "profile-setup") {
    if (lawyerState.profile.must_change_password) {
      return <Navigate to="/change-password" replace />;
    }
    if (lawyerState.profile.is_profile_complete) {
      return <Navigate to="/" replace />;
    }
  }

  return <>{children}</>;
}

export function App() {
  return (
    <Routes>
      {/* Public auth routes */}
      <Route element={<AuthLayout />}>
        <Route path="/login" element={<LoginPage />} />
      </Route>

      {/* Onboarding funnel — no sidebar layout */}
      <Route
        path="/change-password"
        element={
          <SetupRoute step="change-password">
            <ChangePasswordPage />
          </SetupRoute>
        }
      />
      <Route
        path="/profile-setup"
        element={
          <SetupRoute step="profile-setup">
            <ProfileSetupPage />
          </SetupRoute>
        }
      />

      {/* Protected dashboard routes */}
      <Route
        element={
          <ProtectedRoute>
            <DashboardLayout />
          </ProtectedRoute>
        }
      >
        <Route path="/"             element={<DashboardPage />} />
        <Route path="/cases"        element={<CasesPage />} />
        <Route path="/appointments" element={<AppointmentsPage />} />
        <Route path="/messages"     element={<MessagesPage />} />
        <Route path="/documents"    element={<DocumentsPage />} />
      </Route>

      {/* Catch-all */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
