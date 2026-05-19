import { Outlet, Navigate } from "react-router-dom";
import { useAuth } from "@/features/auth/auth-provider";
import { getNextStep } from "@/features/auth/onboarding-storage";

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
    return (
      <Navigate to={getNextStep(firebaseUser.uid, lawyerState.profile)} replace />
    );
  }

  return <Outlet />;
}
