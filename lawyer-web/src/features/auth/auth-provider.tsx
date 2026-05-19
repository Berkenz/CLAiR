import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { onAuthStateChanged, type User } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { api } from "@/lib/api";
import { syncOnboardingFromProfile } from "@/features/auth/onboarding-storage";

export interface LawyerProfile {
  id: string;
  user_id: string;
  display_name: string | null;
  designation: string | null;
  practice_areas: string[] | null;
  ibp_roll_number: string | null;
  year_admitted: string | null;
  ibp_chapter: string | null;
  ptr_number: string | null;
  mcle_compliance_number: string | null;
  law_school: string | null;
  firm_name: string | null;
  office_phone: string | null;
  mobile_phone: string | null;
  office_email: string | null;
  office_address: string | null;
  bio: string | null;
  office_hours: Record<string, { enabled: boolean; ranges: { id: string; start: string; end: string }[] }> | null;
  latitude: number | null;
  longitude: number | null;
  must_change_password: boolean;
  is_profile_complete: boolean;
  created_at: string;
  updated_at: string | null;
}

export interface LawyerUser {
  id: string;
  firebase_uid: string;
  email: string | null;
  first_name: string | null;
  middle_name: string | null;
  last_name: string | null;
  name_suffix: string | null;
  photo_url: string | null;
  is_active: boolean;
  created_at: string;
}

export interface LawyerState {
  user: LawyerUser;
  profile: LawyerProfile;
}

interface AuthContextValue {
  firebaseUser: User | null;
  lawyerState: LawyerState | null;
  loading: boolean;
  setLawyerState: (state: LawyerState) => void;
  refreshLawyerState: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue>({
  firebaseUser: null,
  lawyerState: null,
  loading: true,
  setLawyerState: () => {},
  refreshLawyerState: async () => {},
});

export function AuthProvider({ children }: { children: ReactNode }) {
  const [firebaseUser, setFirebaseUser] = useState<User | null>(null);
  const [lawyerState, setLawyerState] = useState<LawyerState | null>(null);
  const [loading, setLoading] = useState(true);

  // True only for the very first onAuthStateChanged call (page load / refresh).
  // Subsequent calls are triggered by explicit sign-in / sign-out actions, which
  // manage lawyerState themselves — fetching here would race against them.
  const isInitialLoad = useRef(true);

  const fetchLawyerProfile = useCallback(async (): Promise<boolean> => {
    try {
      const { data } = await api.get<LawyerState>("/lawyer/profile");
      setLawyerState(data);
      const uid = auth.currentUser?.uid;
      if (uid) {
        syncOnboardingFromProfile(uid, data.profile);
      }
      return true;
    } catch {
      setLawyerState(null);
      return false;
    }
  }, []);

  const refreshLawyerState = useCallback(async () => {
    await fetchLawyerProfile();
  }, [fetchLawyerProfile]);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (fbUser) => {
      setFirebaseUser(fbUser);

      if (fbUser && isInitialLoad.current) {
        // Existing session (page refresh) — restore lawyer state from the backend.
        await fetchLawyerProfile();
      } else if (!fbUser) {
        // Explicit sign-out or token expiry.
        setLawyerState(null);
      }
      // Fresh sign-in: skip the fetch here. The login page calls
      // POST /lawyer/auth/login which creates the DB record and then
      // calls setLawyerState() directly, avoiding any race condition.

      isInitialLoad.current = false;
      setLoading(false);
    });
    return unsubscribe;
  }, [fetchLawyerProfile]);

  return (
    <AuthContext.Provider
      value={{ firebaseUser, lawyerState, loading, setLawyerState, refreshLawyerState }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
