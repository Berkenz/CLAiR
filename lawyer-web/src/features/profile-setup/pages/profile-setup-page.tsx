import { useEffect, useState } from "react";
import { auth } from "@/lib/firebase";
import { api } from "@/lib/api";
import { getApiErrorMessage } from "@/lib/api-error";
import { markProfileComplete } from "@/features/auth/onboarding-storage";
import { useAuth, type LawyerState } from "@/features/auth/auth-provider";
import { buildLawyerProfileUpdateBody } from "@/features/lawyer/profile-update-body";
import { LocationPicker } from "@/features/profile/components/LocationPicker";
import { useNavigate } from "react-router-dom";
import { Scale, ChevronRight, ChevronLeft, Check } from "lucide-react";
import { cn } from "@/lib/cn";

const FALLBACK_PRACTICE_AREAS = [
  "Family Law",
  "Corporate Law",
  "Criminal Law",
  "Labor Law",
  "Real Estate Law",
  "Other",
];

const FALLBACK_DESIGNATIONS = [
  "Associate",
  "Senior Associate",
  "Senior Partner",
  "Managing Partner",
  "Of Counsel",
  "Other",
];

const DAYS = [
  { key: "sun", label: "Sunday",    short: "S" },
  { key: "mon", label: "Monday",    short: "M" },
  { key: "tue", label: "Tuesday",   short: "T" },
  { key: "wed", label: "Wednesday", short: "W" },
  { key: "thu", label: "Thursday",  short: "T" },
  { key: "fri", label: "Friday",    short: "F" },
  { key: "sat", label: "Saturday",  short: "S" },
];

const HALF_HOURS = Array.from({ length: 48 }, (_, i) => {
  const h = Math.floor(i / 2);
  const m = i % 2 === 0 ? "00" : "30";
  const ampm = h < 12 ? "AM" : "PM";
  const hour = h % 12 === 0 ? 12 : h % 12;
  return `${String(hour).padStart(2, "0")}:${m} ${ampm}`;
});

interface TimeRange { id: string; start: string; end: string; }
interface DaySchedule { enabled: boolean; ranges: TimeRange[]; }
type Schedule = Record<string, DaySchedule>;

function defaultRange(): TimeRange {
  return { id: Date.now().toString() + Math.random(), start: "08:00 AM", end: "05:00 PM" };
}

const STANDARD_SCHEDULE: Schedule = {
  sun: { enabled: false, ranges: [defaultRange()] },
  mon: { enabled: true,  ranges: [defaultRange()] },
  tue: { enabled: true,  ranges: [defaultRange()] },
  wed: { enabled: true,  ranges: [defaultRange()] },
  thu: { enabled: true,  ranges: [defaultRange()] },
  fri: { enabled: true,  ranges: [defaultRange()] },
  sat: { enabled: false, ranges: [defaultRange()] },
};

type Step = "personal" | "credentials" | "practice" | "details";

export function ProfileSetupPage() {
  const navigate = useNavigate();
  const { setLawyerState } = useAuth();
  const [step, setStep] = useState<Step>("personal");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const [practiceAreaOptions, setPracticeAreaOptions] = useState<string[]>(FALLBACK_PRACTICE_AREAS);
  const [designationOptions, setDesignationOptions] = useState<string[]>(FALLBACK_DESIGNATIONS);

  const [firstName, setFirstName] = useState("");
  const [middleName, setMiddleName] = useState("");
  const [lastName, setLastName] = useState("");
  const [suffix, setSuffix] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [designation, setDesignation] = useState("");
  const [ibpRoll, setIbpRoll] = useState("");
  const [yearAdmitted, setYearAdmitted] = useState("");
  const [ibpChapter, setIbpChapter] = useState("");
  const [ptrNumber, setPtrNumber] = useState("");
  const [mcleNumber, setMcleNumber] = useState("");
  const [lawSchool, setLawSchool] = useState("");
  const [practiceAreas, setPracticeAreas] = useState<string[]>([]);
  const [firmName, setFirmName] = useState("");
  const [officePhone, setOfficePhone] = useState("");
  const [mobile, setMobile] = useState("");
  const [officeEmail, setOfficeEmail] = useState("");
  const [officeAddress, setOfficeAddress] = useState("");

  // Step 4 — Office Details
  const [bio, setBio] = useState("");
  const [schedule, setSchedule] = useState<Schedule>(JSON.parse(JSON.stringify(STANDARD_SCHEDULE)));
  const [latitude, setLatitude] = useState<number | null>(null);
  const [longitude, setLongitude] = useState<number | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const { data } = await api.get<{ practice_areas: string[]; designations: string[] }>(
          "/lawyer/options",
        );
        if (!cancelled) {
          setPracticeAreaOptions(data.practice_areas);
          setDesignationOptions(data.designations);
        }
      } catch {
        /* keep fallbacks */
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  function toggleArea(area: string) {
    setPracticeAreas((prev) =>
      prev.includes(area) ? prev.filter((a) => a !== area) : [...prev, area]
    );
  }

  function toggleDay(day: string) {
    setSchedule((prev) => {
      const next: Schedule = JSON.parse(JSON.stringify(prev));
      next[day].enabled = !next[day].enabled;
      if (next[day].enabled && next[day].ranges.length === 0) next[day].ranges.push(defaultRange());
      return next;
    });
  }

  function updateRange(day: string, id: string, field: "start" | "end", value: string) {
    setSchedule((prev) => {
      const next: Schedule = JSON.parse(JSON.stringify(prev));
      const r = next[day].ranges.find((r: TimeRange) => r.id === id);
      if (r) r[field] = value;
      return next;
    });
  }

  function applyAll(day: string) {
    const source = schedule[day].ranges[0];
    if (!source) return;
    setSchedule((prev) => {
      const next: Schedule = JSON.parse(JSON.stringify(prev));
      DAYS.forEach(({ key }) => {
        if (next[key].enabled && next[key].ranges.length > 0) {
          next[key].ranges[0].start = source.start;
          next[key].ranges[0].end = source.end;
        }
      });
      return next;
    });
  }

  function canProceedPersonal() {
    return firstName.trim() && lastName.trim() && designation;
  }

  function canProceedCredentials() {
    return ibpRoll.trim() && yearAdmitted.trim() && ibpChapter.trim();
  }

  async function handleFinish() {
    if (practiceAreas.length === 0) {
      setError("Please select at least one practice area.");
      return;
    }
    const uid = auth.currentUser?.uid;
    if (!uid) {
      setError("Your session expired. Please sign in again.");
      return;
    }

    setError("");
    setSaving(true);
    try {
      await auth.currentUser?.getIdToken(true);
      const body = buildLawyerProfileUpdateBody({
        firstName,
        middleName,
        lastName,
        suffix,
        displayName,
        designation,
        practiceAreas,
        ibpRoll,
        yearAdmitted,
        ibpChapter,
        ptrNumber,
        mcleNumber,
        lawSchool,
        firmName,
        officePhone,
        mobile,
        officeEmail,
        officeAddress,
        bio,
        officeHours: schedule,
        latitude,
        longitude,
      });
      const { data } = await api.put<LawyerState>("/lawyer/profile", body);
      setLawyerState(data);
      if (!data.profile.is_profile_complete) {
        setError(
          "Your profile was saved but required fields are still missing. Go through each step and ensure nothing is blank.",
        );
        return;
      }
      markProfileComplete(uid);
      navigate("/", { replace: true });
    } catch (err) {
      setError(getApiErrorMessage(err, "Could not save your profile. Please try again."));
    } finally {
      setSaving(false);
    }
  }

  const steps: { key: Step; label: string }[] = [
    { key: "personal", label: "Personal" },
    { key: "credentials", label: "Bar Credentials" },
    { key: "practice", label: "Practice Areas" },
    { key: "details", label: "Office Details" },
  ];

  const enabledDays = DAYS.filter(({ key }) => schedule[key].enabled);
  const selectCls = "rounded-lg border border-[#d9b8c4] bg-[#fdf9fb] px-2.5 py-1.5 text-xs text-[#241715] outline-none focus:border-[#703d57] focus:bg-white transition appearance-none";

  const currentIndex = steps.findIndex((s) => s.key === step);
  const inputCls = "w-full rounded-xl border border-[#d9b8c4] bg-[#fdf9fb] px-3.5 py-2.5 text-sm text-[#241715] placeholder-[#c490aa] outline-none focus:border-[#703d57] focus:bg-white transition";

  return (
    <div className="min-h-screen bg-[#f7f0f4] flex flex-col">
      {/* Top bar */}
      <header className="h-16 bg-[#241715] flex items-center px-6 gap-3 flex-shrink-0">
        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-[#703d57]">
          <Scale className="h-4 w-4 text-white" />
        </div>
        <span className="text-lg font-bold text-white tracking-wide">CLAiR</span>
        <span className="ml-3 text-[#957186] text-sm hidden sm:block">Profile Setup</span>
      </header>

      {/* Progress steps */}
      <div className="bg-white border-b border-[#d9b8c4]/40">
        <div className="max-w-2xl mx-auto px-6 py-4">
          <div className="flex items-center gap-0">
            {steps.map((s, i) => (
              <div key={s.key} className="flex items-center flex-1">
                <div className="flex items-center gap-2.5">
                  <div
                    className={cn(
                      "h-7 w-7 rounded-full flex items-center justify-center text-xs font-bold transition-colors",
                      i < currentIndex
                        ? "bg-[#703d57] text-white"
                        : i === currentIndex
                        ? "bg-[#703d57] text-white ring-4 ring-[#703d57]/20"
                        : "bg-[#eedde8] text-[#957186]"
                    )}
                  >
                    {i < currentIndex ? <Check className="h-3.5 w-3.5" /> : i + 1}
                  </div>
                  <span
                    className={cn(
                      "text-sm font-medium hidden sm:block",
                      i === currentIndex ? "text-[#241715]" : "text-[#957186]"
                    )}
                  >
                    {s.label}
                  </span>
                </div>
                {i < steps.length - 1 && (
                  <div
                    className={cn(
                      "flex-1 h-px mx-4",
                      i < currentIndex ? "bg-[#703d57]" : "bg-[#d9b8c4]"
                    )}
                  />
                )}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Form area */}
      <div className="flex-1 flex items-start justify-center px-4 py-10">
        <div className="w-full max-w-2xl">

          {/* ── STEP 1: Personal ── */}
          {step === "personal" && (
            <div className="space-y-6">
              <div>
                <h2 className="text-xl font-bold text-[#241715]">Personal Information</h2>
                <p className="text-sm text-[#957186] mt-1">Tell us about yourself so we can set up your profile.</p>
              </div>

              <div className="bg-white rounded-2xl border border-[#d9b8c4]/40 p-6 space-y-5">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide">First Name <span className="text-red-500">*</span></label>
                    <input type="text" value={firstName} onChange={(e) => setFirstName(e.target.value)} placeholder="Juan" className={inputCls} />
                  </div>
                  <div className="space-y-1.5">
                    <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide">Middle Name</label>
                    <input type="text" value={middleName} onChange={(e) => setMiddleName(e.target.value)} placeholder="Reyes" className={inputCls} />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide">Last Name <span className="text-red-500">*</span></label>
                    <input type="text" value={lastName} onChange={(e) => setLastName(e.target.value)} placeholder="dela Cruz" className={inputCls} />
                  </div>
                  <div className="space-y-1.5">
                    <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide">Suffix</label>
                    <input type="text" value={suffix} onChange={(e) => setSuffix(e.target.value)} placeholder="Jr., Sr., III" className={inputCls} />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide">Display Name</label>
                    <input type="text" value={displayName} onChange={(e) => setDisplayName(e.target.value)} placeholder={`Atty. ${firstName || "Juan"}`} className={inputCls} />
                    <p className="text-[11px] text-[#c490aa]">Shown in the sidebar & header</p>
                  </div>
                  <div className="space-y-1.5">
                    <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide">Designation <span className="text-red-500">*</span></label>
                    <select value={designation} onChange={(e) => setDesignation(e.target.value)} className={inputCls + " appearance-none"}>
                      <option value="">Select…</option>
                      {designationOptions.map((d) => (
                        <option key={d} value={d}>
                          {d}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>

                <div className="space-y-1.5">
                  <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide">Bio / About</label>
                  <p className="text-[11px] text-[#957186]">A short introduction clients will see on your public profile.</p>
                  <textarea
                    value={bio}
                    onChange={(e) => setBio(e.target.value)}
                    rows={4}
                    placeholder="e.g. With over 10 years of experience in family and civil law, I help clients navigate complex legal matters with clarity and care."
                    className={inputCls + " resize-none"}
                  />
                </div>

                <div className="pt-2 border-t border-[#d9b8c4]/40">
                  <p className="text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-3">Office / Contact</p>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-1.5 col-span-2">
                      <label className="block text-xs font-medium text-[#957186]">Firm / Office Name</label>
                      <input type="text" value={firmName} onChange={(e) => setFirmName(e.target.value)} placeholder="Santos & Associates Law Office" className={inputCls} />
                    </div>
                    <div className="space-y-1.5">
                      <label className="block text-xs font-medium text-[#957186]">Mobile</label>
                      <input type="text" value={mobile} onChange={(e) => setMobile(e.target.value)} placeholder="+63 9XX XXX XXXX" className={inputCls} />
                    </div>
                    <div className="space-y-1.5">
                      <label className="block text-xs font-medium text-[#957186]">Office Phone</label>
                      <input type="text" value={officePhone} onChange={(e) => setOfficePhone(e.target.value)} placeholder="+63 32 XXX XXXX" className={inputCls} />
                    </div>
                    <div className="space-y-1.5 col-span-2">
                      <label className="block text-xs font-medium text-[#957186]">Office Email</label>
                      <input type="email" value={officeEmail} onChange={(e) => setOfficeEmail(e.target.value)} placeholder="atty@lawoffice.com" className={inputCls} />
                    </div>
                    <div className="space-y-1.5 col-span-2">
                      <label className="block text-xs font-medium text-[#957186]">Office Address</label>
                      <textarea value={officeAddress} onChange={(e) => setOfficeAddress(e.target.value)} placeholder="Unit/Floor, Building, Street, Barangay, City, Province" rows={2} className={inputCls + " resize-none"} />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ── STEP 2: Bar Credentials ── */}
          {step === "credentials" && (
            <div className="space-y-6">
              <div>
                <h2 className="text-xl font-bold text-[#241715]">Bar & Professional Credentials</h2>
                <p className="text-sm text-[#957186] mt-1">These credentials will be used in legal documents generated by CLAiR.</p>
              </div>

              <div className="bg-white rounded-2xl border border-[#d9b8c4]/40 p-6 space-y-5">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide">IBP Roll Number <span className="text-red-500">*</span></label>
                    <input type="text" value={ibpRoll} onChange={(e) => setIbpRoll(e.target.value)} placeholder="e.g. 123456" className={inputCls} />
                  </div>
                  <div className="space-y-1.5">
                    <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide">Year Admitted to the Bar <span className="text-red-500">*</span></label>
                    <input type="text" value={yearAdmitted} onChange={(e) => setYearAdmitted(e.target.value)} placeholder="e.g. 2015" maxLength={4} className={inputCls} />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide">IBP Chapter <span className="text-red-500">*</span></label>
                    <input type="text" value={ibpChapter} onChange={(e) => setIbpChapter(e.target.value)} placeholder="e.g. Cebu City Chapter" className={inputCls} />
                  </div>
                  <div className="space-y-1.5">
                    <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide">PTR Number</label>
                    <input type="text" value={ptrNumber} onChange={(e) => setPtrNumber(e.target.value)} placeholder="Professional Tax Receipt No." className={inputCls} />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide">MCLE Compliance No.</label>
                    <input type="text" value={mcleNumber} onChange={(e) => setMcleNumber(e.target.value)} placeholder="e.g. IV-0012345" className={inputCls} />
                  </div>
                  <div className="space-y-1.5">
                    <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide">Law School</label>
                    <input type="text" value={lawSchool} onChange={(e) => setLawSchool(e.target.value)} placeholder="e.g. University of San Carlos" className={inputCls} />
                  </div>
                </div>

                <div className="rounded-xl bg-[#f7f0f4] border border-[#d9b8c4]/50 px-4 py-3 text-xs text-[#957186] leading-relaxed">
                  <strong className="text-[#5a3046]">Why we collect this:</strong> Your IBP Roll Number, PTR, and MCLE compliance number will be automatically populated in pleadings, contracts, and other legal documents CLAiR generates on your behalf.
                </div>
              </div>
            </div>
          )}

          {/* ── STEP 3: Practice Areas ── */}
          {step === "practice" && (
            <div className="space-y-6">
              <div>
                <h2 className="text-xl font-bold text-[#241715]">Practice Areas</h2>
                <p className="text-sm text-[#957186] mt-1">Select all that apply. This helps CLAiR tailor document templates and case suggestions.</p>
              </div>

              <div className="bg-white rounded-2xl border border-[#d9b8c4]/40 p-6">
                <div className="flex flex-wrap gap-2.5">
                  {practiceAreaOptions.map((area) => {
                    const selected = practiceAreas.includes(area);
                    return (
                      <button
                        key={area}
                        type="button"
                        onClick={() => toggleArea(area)}
                        className={cn(
                          "px-4 py-2 rounded-full text-sm font-medium border transition-all",
                          selected
                            ? "bg-[#703d57] text-white border-[#703d57]"
                            : "bg-white text-[#703d57] border-[#d9b8c4] hover:border-[#703d57] hover:bg-[#f7f0f4]"
                        )}
                      >
                        {selected && <Check className="inline h-3 w-3 mr-1.5 -mt-0.5" />}
                        {area}
                      </button>
                    );
                  })}
                </div>
                {practiceAreas.length > 0 && (
                  <p className="mt-4 text-xs text-[#957186]">
                    {practiceAreas.length} area{practiceAreas.length > 1 ? "s" : ""} selected
                  </p>
                )}
              </div>

              {error && (
                <div className="rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
                  {error}
                </div>
              )}
            </div>
          )}

          {/* ── STEP 4: Office Details ── */}
          {step === "details" && (
            <div className="space-y-6">
              <div>
                <h2 className="text-xl font-bold text-[#241715]">Office Details</h2>
                <p className="text-sm text-[#957186] mt-1">Set your office hours and pin your location. These are visible to clients in the CLAiR app.</p>
              </div>

              {/* Office Hours */}
              <div className="bg-white rounded-2xl border border-[#d9b8c4]/40 p-6 space-y-5">
                <div>
                  <h3 className="text-sm font-semibold text-[#241715]">Office Hours</h3>
                  <p className="text-xs text-[#957186] mt-0.5">Toggle days and set your working hours. You can update these anytime from your profile.</p>
                </div>

                {/* Day pills */}
                <div>
                  <p className="text-xs text-[#957186] mb-3">Toggle days on/off</p>
                  <div className="flex gap-2">
                    {DAYS.map(({ key, short }) => (
                      <button
                        key={key}
                        type="button"
                        onClick={() => toggleDay(key)}
                        className={cn(
                          "h-9 w-9 rounded-lg text-sm font-bold transition-all",
                          schedule[key].enabled
                            ? "bg-[#703d57] text-white shadow-sm"
                            : "bg-[#f7f0f4] text-[#957186] hover:bg-[#eedde8]"
                        )}
                      >
                        {short}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Time ranges */}
                <div className="pt-2 border-t border-[#d9b8c4]/30">
                  <h4 className="text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-4">Working Hours</h4>
                  {enabledDays.length === 0 ? (
                    <p className="text-sm text-[#957186] text-center py-6">No days selected.</p>
                  ) : (
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
                      {enabledDays.map(({ key, label }) => (
                        <div key={key} className="space-y-2">
                          <div className="flex items-center gap-3">
                            <span className="text-sm font-bold text-[#241715] w-24">{label}</span>
                            <button
                              type="button"
                              onClick={() => applyAll(key)}
                              className="text-xs text-[#957186] hover:text-[#703d57] hover:underline transition-colors"
                            >
                              Apply All
                            </button>
                          </div>
                          <div className="space-y-2">
                            {schedule[key].ranges.map((range: TimeRange) => (
                              <div key={range.id} className="flex items-center gap-2">
                                <select
                                  value={range.start}
                                  onChange={(e) => updateRange(key, range.id, "start", e.target.value)}
                                  className={selectCls}
                                >
                                  {HALF_HOURS.map((t) => <option key={t}>{t}</option>)}
                                </select>
                                <span className="text-xs text-[#957186]">–</span>
                                <select
                                  value={range.end}
                                  onChange={(e) => updateRange(key, range.id, "end", e.target.value)}
                                  className={selectCls}
                                >
                                  {HALF_HOURS.map((t) => <option key={t}>{t}</option>)}
                                </select>
                              </div>
                            ))}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>

              {/* Office Location */}
              <div className="bg-white rounded-2xl border border-[#d9b8c4]/40 p-6 space-y-4">
                <div>
                  <h3 className="text-sm font-semibold text-[#241715]">Office Location</h3>
                  <p className="text-xs text-[#957186] mt-0.5">
                    Pin your office so clients can find you on the map in the CLAiR app.
                    Search an address or use "My location", then click or drag the pin to fine-tune.
                  </p>
                </div>
                <LocationPicker
                  lat={latitude}
                  lng={longitude}
                  onChange={(lat, lng) => { setLatitude(lat); setLongitude(lng); }}
                  onAddressInferred={setOfficeAddress}
                />
              </div>

              {error && (
                <div className="rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">
                  {error}
                </div>
              )}
            </div>
          )}

          {/* Navigation */}
          <div className="flex items-center justify-between mt-8">
            <button
              type="button"
              onClick={() => {
                if (step === "credentials") setStep("personal");
                else if (step === "practice") setStep("credentials");
                else if (step === "details") setStep("practice");
              }}
              className={cn(
                "flex items-center gap-2 px-5 py-2.5 rounded-xl border border-[#d9b8c4] bg-white text-sm font-medium text-[#957186] transition hover:bg-[#f7f0f4]",
                step === "personal" && "invisible"
              )}
            >
              <ChevronLeft className="h-4 w-4" />
              Back
            </button>

            {step !== "details" ? (
              <button
                type="button"
                onClick={() => {
                  setError("");
                  if (step === "personal" && canProceedPersonal()) setStep("credentials");
                  else if (step === "credentials" && canProceedCredentials()) setStep("practice");
                  else if (step === "practice" && practiceAreas.length > 0) setStep("details");
                  else setError("Please fill in the required fields.");
                }}
                disabled={
                  (step === "personal" && !canProceedPersonal()) ||
                  (step === "credentials" && !canProceedCredentials())
                }
                className="flex items-center gap-2 px-6 py-2.5 rounded-xl bg-[#703d57] text-sm font-semibold text-white transition hover:bg-[#5a3046] disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Continue
                <ChevronRight className="h-4 w-4" />
              </button>
            ) : (
              <button
                type="button"
                onClick={() => void handleFinish()}
                disabled={saving}
                className="flex items-center gap-2 px-6 py-2.5 rounded-xl bg-[#703d57] text-sm font-semibold text-white transition hover:bg-[#5a3046] disabled:opacity-60 disabled:cursor-not-allowed"
              >
                {saving ? "Saving…" : "Finish setup"}
                <Check className="h-4 w-4" />
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}