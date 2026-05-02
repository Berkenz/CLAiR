import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "@/lib/api";
import { useAuth, type LawyerState } from "@/features/auth/auth-provider";

interface OptionsResponse {
  practice_areas: string[];
  designations: string[];
}

const CUSTOM_SENTINEL = "Other";

export function ProfileSetupPage() {
  const navigate = useNavigate();
  const { lawyerState, setLawyerState } = useAuth();

  const [options, setOptions] = useState<OptionsResponse>({
    practice_areas: [],
    designations: [],
  });

  const [firstName, setFirstName] = useState(
    lawyerState?.user.first_name ?? "",
  );
  const [lastName, setLastName] = useState(lawyerState?.user.last_name ?? "");
  const [displayName, setDisplayName] = useState(
    lawyerState?.profile.display_name ?? "",
  );
  const [designation, setDesignation] = useState(
    lawyerState?.profile.designation ?? "",
  );
  const [customDesignation, setCustomDesignation] = useState("");
  const [selectedAreas, setSelectedAreas] = useState<string[]>(
    lawyerState?.profile.practice_areas ?? [],
  );
  const [customArea, setCustomArea] = useState("");

  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [loadingOptions, setLoadingOptions] = useState(true);

  useEffect(() => {
    api
      .get<OptionsResponse>("/lawyer/options")
      .then(({ data }) => setOptions(data))
      .catch(() => {})
      .finally(() => setLoadingOptions(false));
  }, []);

  function toggleArea(area: string) {
    setSelectedAreas((prev) =>
      prev.includes(area) ? prev.filter((a) => a !== area) : [...prev, area],
    );
  }

  function buildFinalAreas(): string[] {
    const areas = selectedAreas.filter((a) => a !== CUSTOM_SENTINEL);
    if (selectedAreas.includes(CUSTOM_SENTINEL) && customArea.trim()) {
      areas.push(customArea.trim());
    }
    return areas;
  }

  function buildFinalDesignation(): string {
    if (designation === CUSTOM_SENTINEL) return customDesignation.trim();
    return designation;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    const finalAreas = buildFinalAreas();
    const finalDesignation = buildFinalDesignation();

    if (!firstName.trim() || !lastName.trim()) {
      setError("First name and last name are required.");
      return;
    }
    if (!displayName.trim()) {
      setError("Display name is required.");
      return;
    }
    if (!finalDesignation) {
      setError("Designation is required.");
      return;
    }
    if (finalAreas.length === 0) {
      setError("Please select at least one practice area.");
      return;
    }

    setLoading(true);
    try {
      const { data } = await api.put<LawyerState>("/lawyer/profile", {
        first_name: firstName.trim(),
        last_name: lastName.trim(),
        display_name: displayName.trim(),
        designation: finalDesignation,
        practice_areas: finalAreas,
      });

      setLawyerState(data);
      navigate("/", { replace: true });
    } catch (err: unknown) {
      const detail =
        err instanceof Error &&
        (err as { response?: { data?: { detail?: string } } }).response?.data
          ?.detail;
      setError(detail || "Failed to save profile. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  if (loadingOptions) {
    return (
      <div className="flex h-screen items-center justify-center bg-gray-50">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-brand-500 border-t-transparent" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 px-4 py-12">
      <div className="mx-auto w-full max-w-lg space-y-8">
        <div className="text-center">
          <h1 className="text-3xl font-bold tracking-tight text-brand-900">
            CLAiR
          </h1>
          <p className="mt-2 text-sm text-gray-500">
            Complete your profile to get started
          </p>
        </div>

        <form
          onSubmit={handleSubmit}
          className="rounded-xl border border-gray-200 bg-white p-8 shadow-sm"
        >
          <h2 className="mb-6 text-lg font-semibold text-gray-900">
            Your Profile
          </h2>

          {error && (
            <div className="mb-5 rounded-lg bg-red-50 px-4 py-3 text-sm text-red-700">
              {error}
            </div>
          )}

          <div className="space-y-5">
            {/* Name row */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label
                  htmlFor="first-name"
                  className="block text-sm font-medium text-gray-700"
                >
                  First name <span className="text-red-500">*</span>
                </label>
                <input
                  id="first-name"
                  type="text"
                  required
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  className="mt-1.5 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-brand-500 focus:ring-1 focus:ring-brand-500 focus:outline-none"
                />
              </div>
              <div>
                <label
                  htmlFor="last-name"
                  className="block text-sm font-medium text-gray-700"
                >
                  Last name <span className="text-red-500">*</span>
                </label>
                <input
                  id="last-name"
                  type="text"
                  required
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  className="mt-1.5 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-brand-500 focus:ring-1 focus:ring-brand-500 focus:outline-none"
                />
              </div>
            </div>

            {/* Display name */}
            <div>
              <label
                htmlFor="display-name"
                className="block text-sm font-medium text-gray-700"
              >
                Display name <span className="text-red-500">*</span>
              </label>
              <p className="mt-0.5 text-xs text-gray-400">
                This is how your name appears to clients (e.g. "Atty. Juan dela
                Cruz").
              </p>
              <input
                id="display-name"
                type="text"
                required
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                className="mt-1.5 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-brand-500 focus:ring-1 focus:ring-brand-500 focus:outline-none"
                placeholder="e.g. Atty. Juan dela Cruz"
              />
            </div>

            {/* Designation */}
            <div>
              <label
                htmlFor="designation"
                className="block text-sm font-medium text-gray-700"
              >
                Designation <span className="text-red-500">*</span>
              </label>
              <select
                id="designation"
                value={designation}
                onChange={(e) => setDesignation(e.target.value)}
                required
                className="mt-1.5 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-brand-500 focus:ring-1 focus:ring-brand-500 focus:outline-none"
              >
                <option value="" disabled>
                  Select your designation
                </option>
                {options.designations.map((d) => (
                  <option key={d} value={d}>
                    {d}
                  </option>
                ))}
              </select>
              {designation === CUSTOM_SENTINEL && (
                <input
                  type="text"
                  required
                  value={customDesignation}
                  onChange={(e) => setCustomDesignation(e.target.value)}
                  placeholder="Enter your designation"
                  className="mt-2 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-brand-500 focus:ring-1 focus:ring-brand-500 focus:outline-none"
                />
              )}
            </div>

            {/* Practice areas */}
            <div>
              <span className="block text-sm font-medium text-gray-700">
                Practice areas <span className="text-red-500">*</span>
              </span>
              <p className="mt-0.5 text-xs text-gray-400">
                Select all that apply.
              </p>
              <div className="mt-2 flex flex-wrap gap-2">
                {options.practice_areas.map((area) => {
                  const selected = selectedAreas.includes(area);
                  return (
                    <button
                      key={area}
                      type="button"
                      onClick={() => toggleArea(area)}
                      className={`rounded-full border px-3 py-1 text-xs font-medium transition-colors ${
                        selected
                          ? "border-brand-600 bg-brand-600 text-white"
                          : "border-gray-300 bg-white text-gray-700 hover:border-brand-400"
                      }`}
                    >
                      {area}
                    </button>
                  );
                })}
              </div>
              {selectedAreas.includes(CUSTOM_SENTINEL) && (
                <input
                  type="text"
                  value={customArea}
                  onChange={(e) => setCustomArea(e.target.value)}
                  placeholder="Enter your practice area"
                  className="mt-2 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-brand-500 focus:ring-1 focus:ring-brand-500 focus:outline-none"
                />
              )}
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full rounded-lg bg-brand-700 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-brand-800 focus:ring-2 focus:ring-brand-500 focus:ring-offset-2 focus:outline-none disabled:opacity-50"
            >
              {loading ? "Saving..." : "Save and continue"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
