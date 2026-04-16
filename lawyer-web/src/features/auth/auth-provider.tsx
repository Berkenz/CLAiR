import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import { onAuthStateChanged, type User } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { api } from "@/lib/api";

export interface LawyerProfile {
  id: string;
  user_id: string;
  display_name: string | null;
  designation: string | null;
  practice_areas: string[] | null;
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
  last_name: string | null;
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

  const fetchLawyerProfile = useCallback(async (fbUser: User) => {
    try {
      const { data } = await api.get<LawyerState>("/lawyer/profile");
      setLawyerState(data);
    } catch {
      setLawyerState(null);
    }
  }, []);

  const refreshLawyerState = useCallback(async () => {
    if (!firebaseUser) return;
    await fetchLawyerProfile(firebaseUser);
  }, [firebaseUser, fetchLawyerProfile]);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (fbUser) => {
      setFirebaseUser(fbUser);
      if (fbUser) {
        await fetchLawyerProfile(fbUser);
      } else {
        setLawyerState(null);
      }
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
