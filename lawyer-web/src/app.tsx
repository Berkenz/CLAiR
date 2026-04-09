import { Routes, Route, Navigate } from "react-router-dom";
import { useAuth } from "@/features/auth/auth-provider";
import { AuthLayout } from "@/layouts/auth-layout";
import { DashboardLayout } from "@/layouts/dashboard-layout";
import { LoginPage } from "@/features/auth/pages/login-page";
import { DashboardPage } from "@/features/dashboard/pages/dashboard-page";
import { ReferralsPage } from "@/features/referrals/pages/referrals-page";
import { ClientsPage } from "@/features/clients/pages/clients-page";
import { ProfilePage } from "@/features/profile/pages/profile-page";

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-brand-600 border-t-transparent" />
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
}

export function App() {
  return (
    <Routes>
      {/* Public routes */}
      <Route element={<AuthLayout />}>
        <Route path="/login" element={<LoginPage />} />
      </Route>

      {/* Protected routes */}
      <Route
        element={
          <ProtectedRoute>
            <DashboardLayout />
          </ProtectedRoute>
        }
      >
        <Route path="/" element={<DashboardPage />} />
        <Route path="/referrals" element={<ReferralsPage />} />
        <Route path="/clients" element={<ClientsPage />} />
        <Route path="/profile" element={<ProfilePage />} />
      </Route>

      {/* Catch-all */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
