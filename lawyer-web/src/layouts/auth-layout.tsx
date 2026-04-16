import { Outlet, Navigate } from "react-router-dom";
import { useAuth } from "@/features/auth/auth-provider";

export function AuthLayout() {
  const { firebaseUser, lawyerState, loading } = useAuth();

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-brand-600 border-t-transparent" />
      </div>
    );
  }

  if (firebaseUser && lawyerState) {
    if (lawyerState.profile.must_change_password) {
      return <Navigate to="/change-password" replace />;
    }
    if (!lawyerState.profile.is_profile_complete) {
      return <Navigate to="/profile-setup" replace />;
    }
    return <Navigate to="/" replace />;
  }

  return <Outlet />;
}
