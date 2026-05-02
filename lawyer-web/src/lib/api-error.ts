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
