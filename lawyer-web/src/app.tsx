import { Routes, Route, Navigate } from "react-router-dom";
import { useAuth } from "@/features/auth/auth-provider";
import { AuthLayout } from "@/layouts/auth-layout";
import { DashboardLayout } from "@/layouts/dashboard-layout";
import { LoginPage } from "@/features/auth/pages/login-page";
import { DashboardPage } from "@/features/dashboard/pages/dashboard-page";
import { CasesPage } from "@/features/cases/pages/cases-page";
import { AppointmentsPage } from "@/features/appointments/pages/appointments-page";
import { MessagesPage } from "@/features/messages/pages/messages-page";
import { DocumentsPage } from "@/features/documents/pages/documents-page";

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();


  if (import.meta.env.VITE_SKIP_AUTH === "true") {
    return <>{children}</>;
  }


  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center bg-[#241715]">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#957186] border-t-transparent" />
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