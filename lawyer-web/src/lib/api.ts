import axios from "axios";
import { auth } from "./firebase";

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || "/api/v1",
  headers: { "Content-Type": "application/json" },
});

api.interceptors.request.use(async (config) => {
  const user = auth.currentUser;
  if (user) {
    const token = await user.getIdToken();
    config.headers.Authorization = `Bearer ${token}`;
  }
  // FormData needs the browser-set Content-Type with boundary; the default
  // application/json header breaks multipart uploads.
  if (config.data instanceof FormData) {
    delete config.headers["Content-Type"];
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      const url = String(error.config?.url ?? "");
      // Lawyer onboarding calls: backend may return 401 while Firebase is still valid.
      // Global sign-out here sends users back to login after password change incorrectly.
      const skipLogout =
        url.includes("/lawyer/auth/login") ||
        url.includes("/lawyer/auth/confirm-password-change") ||
        url.includes("/lawyer/auth/account");
      if (!skipLogout) {
        auth.signOut();
        window.location.href = "/login";
      }
    }
    return Promise.reject(error);
  },
);



export { api };
