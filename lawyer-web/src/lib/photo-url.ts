/** Append ?v= when the storage path is stable but the image bytes changed. */
export function profilePhotoDisplayUrl(
  photoUrl: string | null | undefined,
  version?: string | number | null,
): string | null {
  const trimmed = (photoUrl ?? "").trim();
  if (!trimmed) return null;
  if (version == null || version === "") return trimmed;
  try {
    const uri = new URL(trimmed);
    uri.searchParams.set("v", String(version));
    return uri.toString();
  } catch {
    const sep = trimmed.includes("?") ? "&" : "?";
    return `${trimmed}${sep}v=${encodeURIComponent(String(version))}`;
  }
}
