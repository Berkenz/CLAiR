import axios from "axios";

/** True when the request never reached the server (offline, DNS, CORS failure, wrong URL). */
export function isApiNetworkError(err: unknown): boolean {
  if (!axios.isAxiosError(err)) return false;
  return err.response === undefined;
}

/** Best-effort message from FastAPI / Axios error responses. */
export function getApiErrorMessage(err: unknown, fallback: string): string {
  const ax = err as {
    response?: { data?: { detail?: unknown } };
  };
  const detail = ax.response?.data?.detail;
  if (typeof detail === "string") return detail;
  if (Array.isArray(detail)) {
    const parts = detail.map((item) =>
      typeof item === "object" && item !== null && "msg" in item
        ? String((item as { msg: string }).msg)
        : JSON.stringify(item),
    );
    return parts.join(" ") || fallback;
  }
  return fallback;
}

function apiNetworkHint(): string {
  const origin =
    typeof window !== "undefined" && window.location?.origin
      ? window.location.origin
      : "this site";
  if (import.meta.env.PROD) {
    return (
      ` The browser could not reach the API (often CORS or a wrong API URL). ` +
      `Use VITE_API_BASE_URL=/api/v1 so Vercel proxies to the backend, or add ${origin} ` +
      `to backend CORS_ORIGINS (and redeploy the API).`
    );
  }
  return (
    " Start the API (e.g. uvicorn on port 8000). If `VITE_API_BASE_URL` points straight at the API, " +
    "set backend `CORS_ORIGINS` to include http://localhost:5173 (and http://127.0.0.1:5173 if you use that URL)."
  );
}

/** Same as getApiErrorMessage, but adds setup hints when the browser never got an HTTP response. */
export function getApiErrorMessageWithNetworkHint(err: unknown, fallback: string): string {
  const msg = getApiErrorMessage(err, fallback);
  if (!isApiNetworkError(err)) return msg;
  return `${msg}${apiNetworkHint()}`;
}
