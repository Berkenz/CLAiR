import { useEffect, useState } from "react";
import { updateEmail, updatePassword, EmailAuthProvider, reauthenticateWithCredential } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { api } from "@/lib/api";
import { getApiErrorMessage } from "@/lib/api-error";
import { useAuth, type LawyerState } from "@/features/auth/auth-provider";
import { buildLawyerProfileUpdateBody } from "@/features/lawyer/profile-update-body";
import { cn } from "@/lib/cn";
import { Check, Camera, X, Plus } from "lucide-react";

// ─── Constants ────────────────────────────────────────────────────────────────

const FALLBACK_PRACTICE_AREAS = [
  "Family Law",
  "Corporate Law",
  "Criminal Law",
  "Labor Law",
  "Other",
];

const FALLBACK_DESIGNATIONS = [
  "Associate",
  "Senior Associate",
  "Senior Partner",
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

// ─── Types ────────────────────────────────────────────────────────────────────

type Tab = "profile" | "account" | "hours";

// ─── Component ────────────────────────────────────────────────────────────────

export function ProfilePage() {
  const {
    lawyerState,
    setLawyerState,
    refreshLawyerState,
    firebaseUser,
    loading: authLoading,
  } = useAuth();
  const [tab, setTab] = useState<Tab>("profile");
  const [saving, setSaving] = useState(false);
  const [saveMsg, setSaveMsg] = useState("");
  const [saveError, setSaveError] = useState("");
  const [retryingProfile, setRetryingProfile] = useState(false);
  const [practiceAreaOptions, setPracticeAreaOptions] = useState<string[]>(FALLBACK_PRACTICE_AREAS);
  const [designationOptions, setDesignationOptions] = useState<string[]>(FALLBACK_DESIGNATIONS);

  // Profile fields — name & practice areas sync to the CLAiR API; office hours UI is local until backend supports them.
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

  // Account fields
  const [newEmail, setNewEmail] = useState("");
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [accountMsg, setAccountMsg] = useState("");
  const [accountError, setAccountError] = useState("");

  // Office hours (UI state; persist via API when backend supports it)
  const [schedule, setSchedule] = useState<Schedule>(JSON.parse(JSON.stringify(STANDARD_SCHEDULE)));
  const [hoursSaved, setHoursSaved] = useState(false);

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
        /* fallbacks */
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (!lawyerState) return;
    const u = lawyerState.user;
    const p = lawyerState.profile;
    setFirstName(u.first_name ?? "");
    setMiddleName(u.middle_name ?? "");
    setLastName(u.last_name ?? "");
    setSuffix(u.name_suffix ?? "");
    setDisplayName(p.display_name ?? "");
    setDesignation(p.designation ?? "");
    setPracticeAreas(p.practice_areas ?? []);
    setIbpRoll(p.ibp_roll_number ?? "");
    setYearAdmitted(p.year_admitted ?? "");
    setIbpChapter(p.ibp_chapter ?? "");
    setPtrNumber(p.ptr_number ?? "");
    setMcleNumber(p.mcle_compliance_number ?? "");
    setLawSchool(p.law_school ?? "");
    setFirmName(p.firm_name ?? "");
    setOfficePhone(p.office_phone ?? "");
    setMobile(p.mobile_phone ?? "");
    setOfficeEmail(p.office_email ?? "");
    setOfficeAddress(p.office_address ?? "");
  }, [lawyerState]);

  useEffect(() => {
    setNewEmail(firebaseUser?.email ?? "");
  }, [firebaseUser?.email]);

  function toggleArea(area: string) {
    setPracticeAreas((prev) =>
      prev.includes(area) ? prev.filter((a) => a !== area) : [...prev, area]
    );
  }

  async function saveProfile() {
    setSaveMsg("");
    setSaveError("");
    const fn = firstName.trim();
    const ln = lastName.trim();
    const des = designation.trim();
    const dn =
      displayName.trim() ||
      (fn && ln ? `Atty. ${fn} ${ln}` : "");
    if (!fn || !ln || !dn || !des || practiceAreas.length === 0) {
      setSaveError(
        "First name, last name, display name, designation, and at least one practice area are required.",
      );
      return;
    }
    setSaving(true);
    try {
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
      });
      const { data } = await api.put<LawyerState>("/lawyer/profile", body);
      setLawyerState(data);
      setSaveMsg("Profile saved successfully.");
      setTimeout(() => setSaveMsg(""), 4000);
    } catch (err) {
      setSaveError(getApiErrorMessage(err, "Could not save profile. Please try again."));
    } finally {
      setSaving(false);
    }
  }

  async function handleUpdateEmail() {
    setAccountError(""); setAccountMsg("");
    const user = auth.currentUser;
    if (!user) return;
    try {
      await updateEmail(user, newEmail);
      setAccountMsg("Email updated successfully.");
    } catch (e: any) {
      setAccountError(e.message || "Failed to update email.");
    }
  }

  async function handleUpdatePassword() {
    setAccountError(""); setAccountMsg("");
    if (newPassword !== confirmPassword) { setAccountError("Passwords do not match."); return; }
    if (newPassword.length < 6) { setAccountError("Password must be at least 6 characters."); return; }
    const user = auth.currentUser;
    if (!user || !user.email) return;
    try {
      const cred = EmailAuthProvider.credential(user.email, currentPassword);
      await reauthenticateWithCredential(user, cred);
      await updatePassword(user, newPassword);
      setAccountMsg("Password updated successfully.");
      setCurrentPassword(""); setNewPassword(""); setConfirmPassword("");
    } catch {
      setAccountError("Current password is incorrect or session expired.");
    }
  }

  // Office hours helpers
  function toggleDay(day: string) {
    setSchedule((prev) => {
      const next = JSON.parse(JSON.stringify(prev));
      next[day].enabled = !next[day].enabled;
      if (next[day].enabled && next[day].ranges.length === 0) next[day].ranges.push(defaultRange());
      return next;
    });
  }
  function updateRange(day: string, id: string, field: "start" | "end", value: string) {
    setSchedule((prev) => {
      const next = JSON.parse(JSON.stringify(prev));
      const r = next[day].ranges.find((r: TimeRange) => r.id === id);
      if (r) r[field] = value;
      return next;
    });
  }
  function addRange(day: string) {
    setSchedule((prev) => {
      const next = JSON.parse(JSON.stringify(prev));
      next[day].ranges.push(defaultRange());
      return next;
    });
  }
  function removeRange(day: string, id: string) {
    setSchedule((prev) => {
      const next = JSON.parse(JSON.stringify(prev));
      next[day].ranges = next[day].ranges.filter((r: TimeRange) => r.id !== id);
      return next;
    });
  }
  function applyAll(day: string) {
    const source = schedule[day].ranges[0];
    if (!source) return;
    setSchedule((prev) => {
      const next = JSON.parse(JSON.stringify(prev));
      DAYS.forEach(({ key }) => {
        if (next[key].enabled && next[key].ranges.length > 0) {
          next[key].ranges[0].start = source.start;
          next[key].ranges[0].end = source.end;
        }
      });
      return next;
    });
  }
  function saveHours() {
    setHoursSaved(true);
    setTimeout(() => setHoursSaved(false), 2500);
  }

  const initials =
    `${firstName.trim().charAt(0)}${lastName.trim().charAt(0)}`.toUpperCase() ||
    (displayName.trim().slice(0, 2).toUpperCase() || "?");
  const fullName =
    [firstName, middleName, lastName, suffix].filter(Boolean).join(" ") ||
    lawyerState?.profile.display_name ||
    "Your Name";

  const profileIncompleteBanner =
    !authLoading && Boolean(firebaseUser) && lawyerState === null;

  const enabledDays = DAYS.filter(({ key }) => schedule[key].enabled);

  const inputCls = "w-full rounded-xl border border-[#d9b8c4] bg-[#fdf9fb] px-3.5 py-2.5 text-sm text-[#241715] placeholder-[#c490aa] outline-none focus:border-[#703d57] focus:bg-white transition";
  const labelCls = "block text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-1.5";
  const selectCls = "rounded-lg border border-[#d9b8c4] bg-[#fdf9fb] px-2.5 py-1.5 text-xs text-[#241715] outline-none focus:border-[#703d57] focus:bg-white transition appearance-none";

  const TABS: { key: Tab; label: string }[] = [
    { key: "profile", label: "Professional Profile" },
    { key: "account", label: "Account & Security" },
    { key: "hours",   label: "Office Hours" },
  ];

  return (
    <div className="space-y-6 max-w-3xl mx-auto">
      <div>
        <h1 className="text-2xl font-bold text-[#241715]">My Profile</h1>
        <p className="mt-0.5 text-sm text-[#957186]">Manage your professional information, account settings, and office hours</p>
        {profileIncompleteBanner && (
          <div className="mt-3 flex flex-wrap items-center gap-3 rounded-xl bg-amber-50 border border-amber-200 px-4 py-3 text-sm text-amber-900">
            <span>Could not load your profile from the server. Check that the API is running.</span>
            <button
              type="button"
              disabled={retryingProfile}
              onClick={() => {
                setRetryingProfile(true);
                void refreshLawyerState().finally(() => setRetryingProfile(false));
              }}
              className="rounded-lg bg-amber-800/90 px-3 py-1.5 text-xs font-semibold text-white hover:bg-amber-900 disabled:opacity-60"
            >
              {retryingProfile ? "Retrying…" : "Retry"}
            </button>
          </div>
        )}
      </div>

      {/* Tabs */}
      <div className="flex gap-0 border-b border-[#d9b8c4]/60">
        {TABS.map(({ key, label }) => (
          <button
            key={key}
            onClick={() => setTab(key)}
            className={cn(
              "px-5 py-2.5 text-sm font-medium border-b-2 -mb-px transition-colors",
              tab === key ? "border-[#703d57] text-[#703d57]" : "border-transparent text-[#957186] hover:text-[#703d57]"
            )}
          >
            {label}
          </button>
        ))}
      </div>

      {/* ── Tab: Professional Profile ── */}
      {tab === "profile" && (
        <div className="space-y-5">
          <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-6">
            <div className="flex items-center gap-5">
              <div className="relative">
                <div className="h-20 w-20 rounded-full bg-[#703d57] flex items-center justify-center text-2xl font-bold text-white">{initials}</div>
                <button className="absolute bottom-0 right-0 h-7 w-7 rounded-full bg-white border border-[#d9b8c4] flex items-center justify-center shadow-sm hover:bg-[#f7f0f4] transition">
                  <Camera className="h-3.5 w-3.5 text-[#703d57]" />
                </button>
              </div>
              <div>
                <p className="text-lg font-bold text-[#241715]">{fullName}</p>
                <p className="text-sm text-[#957186]">{designation || "—"} · {practiceAreas.slice(0, 2).join(", ") || "No practice areas set"}</p>
              </div>
            </div>
          </div>

          <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-6">
            <h2 className="text-sm font-semibold text-[#241715] mb-5 pb-3 border-b border-[#d9b8c4]/30">Personal Information</h2>
            <p className="text-xs text-[#957186] mb-4">
              Updates are saved to your CLAiR account and used across the lawyer portal.
            </p>
            <div className="grid grid-cols-2 gap-4">
              <div><label className={labelCls}>First Name</label><input className={inputCls} value={firstName} onChange={(e) => setFirstName(e.target.value)} /></div>
              <div><label className={labelCls}>Middle Name</label><input className={inputCls} value={middleName} onChange={(e) => setMiddleName(e.target.value)} /></div>
              <div><label className={labelCls}>Last Name</label><input className={inputCls} value={lastName} onChange={(e) => setLastName(e.target.value)} /></div>
              <div><label className={labelCls}>Suffix</label><input className={inputCls} value={suffix} onChange={(e) => setSuffix(e.target.value)} placeholder="Jr., Sr." /></div>
              <div><label className={labelCls}>Display Name</label><input className={inputCls} value={displayName} onChange={(e) => setDisplayName(e.target.value)} /></div>
              <div>
                <label className={labelCls}>Designation</label>
                <select className={inputCls + " appearance-none"} value={designation} onChange={(e) => setDesignation(e.target.value)}>
                  <option value="">Select…</option>
                  {designationOptions.map((d) => (
                    <option key={d} value={d}>
                      {d}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </div>

          <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-6">
            <h2 className="text-sm font-semibold text-[#241715] mb-5 pb-3 border-b border-[#d9b8c4]/30">Bar & Professional Credentials</h2>
            <div className="grid grid-cols-2 gap-4">
              <div><label className={labelCls}>IBP Roll Number</label><input className={inputCls} value={ibpRoll} onChange={(e) => setIbpRoll(e.target.value)} placeholder="e.g. 123456" /></div>
              <div><label className={labelCls}>Year Admitted</label><input className={inputCls} value={yearAdmitted} onChange={(e) => setYearAdmitted(e.target.value)} placeholder="e.g. 2015" /></div>
              <div><label className={labelCls}>IBP Chapter</label><input className={inputCls} value={ibpChapter} onChange={(e) => setIbpChapter(e.target.value)} placeholder="e.g. Cebu City Chapter" /></div>
              <div><label className={labelCls}>PTR Number</label><input className={inputCls} value={ptrNumber} onChange={(e) => setPtrNumber(e.target.value)} placeholder="Professional Tax Receipt No." /></div>
              <div><label className={labelCls}>MCLE Compliance No.</label><input className={inputCls} value={mcleNumber} onChange={(e) => setMcleNumber(e.target.value)} placeholder="e.g. IV-0012345" /></div>
              <div><label className={labelCls}>Law School</label><input className={inputCls} value={lawSchool} onChange={(e) => setLawSchool(e.target.value)} placeholder="e.g. University of San Carlos" /></div>
            </div>
          </div>

          <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-6">
            <h2 className="text-sm font-semibold text-[#241715] mb-1 pb-3 border-b border-[#d9b8c4]/30">Practice Areas</h2>
            <p className="text-xs text-[#957186] mb-4 mt-1">Select all that apply</p>
            <div className="flex flex-wrap gap-2">
              {practiceAreaOptions.map((area) => {
                const selected = practiceAreas.includes(area);
                return (
                  <button key={area} type="button" onClick={() => toggleArea(area)}
                    className={cn("px-3.5 py-1.5 rounded-full text-xs font-medium border transition-all",
                      selected ? "bg-[#703d57] text-white border-[#703d57]" : "bg-white text-[#703d57] border-[#d9b8c4] hover:border-[#703d57]"
                    )}>
                    {selected && <Check className="inline h-3 w-3 mr-1 -mt-0.5" />}{area}
                  </button>
                );
              })}
            </div>
          </div>

          <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-6">
            <h2 className="text-sm font-semibold text-[#241715] mb-5 pb-3 border-b border-[#d9b8c4]/30">Contact & Office</h2>
            <div className="grid grid-cols-2 gap-4">
              <div className="col-span-2"><label className={labelCls}>Firm / Office Name</label><input className={inputCls} value={firmName} onChange={(e) => setFirmName(e.target.value)} /></div>
              <div><label className={labelCls}>Mobile</label><input className={inputCls} value={mobile} onChange={(e) => setMobile(e.target.value)} placeholder="+63 9XX XXX XXXX" /></div>
              <div><label className={labelCls}>Office Phone</label><input className={inputCls} value={officePhone} onChange={(e) => setOfficePhone(e.target.value)} placeholder="+63 32 XXX XXXX" /></div>
              <div className="col-span-2"><label className={labelCls}>Office Email</label><input className={inputCls} value={officeEmail} onChange={(e) => setOfficeEmail(e.target.value)} /></div>
              <div className="col-span-2"><label className={labelCls}>Office Address</label><textarea className={inputCls + " resize-none"} rows={2} value={officeAddress} onChange={(e) => setOfficeAddress(e.target.value)} placeholder="Unit, Building, Street, Barangay, City, Province" /></div>
            </div>
          </div>

          {saveMsg && (
            <div className="rounded-xl px-4 py-3 text-sm bg-emerald-50 border border-emerald-200 text-emerald-700">
              {saveMsg}
            </div>
          )}
          {saveError && (
            <div className="rounded-xl px-4 py-3 text-sm bg-red-50 border border-red-200 text-red-700">
              {saveError}
            </div>
          )}
          <div className="flex justify-end gap-3 pb-8">
            <button
              type="button"
              onClick={() => void saveProfile()}
              disabled={saving || !lawyerState}
              className="px-6 py-2.5 rounded-xl bg-[#703d57] text-sm font-semibold text-white hover:bg-[#5a3046] disabled:opacity-60 transition"
            >
              {saving ? "Saving…" : "Save profile"}
            </button>
          </div>
        </div>
      )}

      {/* ── Tab: Account & Security ── */}
      {tab === "account" && (
        <div className="space-y-5 pb-8">
          <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-6">
            <h2 className="text-sm font-semibold text-[#241715] mb-5 pb-3 border-b border-[#d9b8c4]/30">Login Email</h2>
            <div className="max-w-sm space-y-4">
              <div><label className={labelCls}>Email address</label><input type="email" className={inputCls} value={newEmail} onChange={(e) => setNewEmail(e.target.value)} /></div>
              <button onClick={handleUpdateEmail} className="px-5 py-2.5 rounded-xl bg-[#703d57] text-sm font-semibold text-white hover:bg-[#5a3046] transition">Update email</button>
            </div>
          </div>
          <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-6">
            <h2 className="text-sm font-semibold text-[#241715] mb-5 pb-3 border-b border-[#d9b8c4]/30">Change Password</h2>
            <div className="max-w-sm space-y-4">
              <div><label className={labelCls}>Current password</label><input type="password" className={inputCls} value={currentPassword} onChange={(e) => setCurrentPassword(e.target.value)} placeholder="••••••••" /></div>
              <div><label className={labelCls}>New password</label><input type="password" className={inputCls} value={newPassword} onChange={(e) => setNewPassword(e.target.value)} placeholder="••••••••" /></div>
              <div><label className={labelCls}>Confirm new password</label><input type="password" className={inputCls} value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} placeholder="••••••••" /></div>
              <button onClick={handleUpdatePassword} className="px-5 py-2.5 rounded-xl bg-[#703d57] text-sm font-semibold text-white hover:bg-[#5a3046] transition">Update password</button>
            </div>
          </div>
          {accountMsg && <div className="rounded-xl bg-emerald-50 border border-emerald-200 px-4 py-3 text-sm text-emerald-700">{accountMsg}</div>}
          {accountError && <div className="rounded-xl bg-red-50 border border-red-200 px-4 py-3 text-sm text-red-700">{accountError}</div>}
          <div className="rounded-2xl border border-red-200/60 bg-red-50/50 p-6">
            <h2 className="text-sm font-semibold text-red-800 mb-1">Danger zone</h2>
            <p className="text-xs text-red-600 mb-4">Deleting your account is permanent and cannot be undone.</p>
            <button className="px-4 py-2 rounded-xl border border-red-300 bg-white text-sm font-medium text-red-600 hover:bg-red-50 transition">Delete account</button>
          </div>
        </div>
      )}

      {/* ── Tab: Office Hours ── */}
      {tab === "hours" && (
        <div className="space-y-5 pb-8">
          <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-6 space-y-5">
            <div>
              <h2 className="text-sm font-semibold text-[#241715] mb-1">Availability Schedule</h2>
              <p className="text-xs text-[#957186]">Set your working hours to display on your public lawyer profile.</p>
            </div>

            {/* Day pills */}
            <div>
              <p className="text-xs text-[#957186] mb-3">Toggle days on/off</p>
              <div className="flex gap-2">
                {DAYS.map(({ key, short }) => (
                  <button key={key} onClick={() => toggleDay(key)}
                    className={cn("h-9 w-9 rounded-lg text-sm font-bold transition-all",
                      schedule[key].enabled ? "bg-[#703d57] text-white shadow-sm" : "bg-[#f7f0f4] text-[#957186] hover:bg-[#eedde8]"
                    )}>
                    {short}
                  </button>
                ))}
              </div>
            </div>

            {/* Time ranges */}
            <div className="pt-2 border-t border-[#d9b8c4]/30">
              <h3 className="text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-4">Working Hours</h3>
              {enabledDays.length === 0 ? (
                <p className="text-sm text-[#957186] text-center py-6">No days selected.</p>
              ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
                  {enabledDays.map(({ key, label }) => (
                    <div key={key} className="space-y-2">
                      <div className="flex items-center gap-3">
                        <span className="text-sm font-bold text-[#241715] w-24">{label}</span>
                        <button onClick={() => addRange(key)} className="text-xs text-[#703d57] font-semibold hover:underline flex items-center gap-0.5">
                          <Plus className="h-3 w-3" />hours
                        </button>
                        <button onClick={() => applyAll(key)} className="text-xs text-[#957186] hover:text-[#703d57] hover:underline transition-colors">
                          Apply All
                        </button>
                      </div>
                      <div className="space-y-2">
                        {schedule[key].ranges.map((range: TimeRange) => (
                          <div key={range.id} className="flex items-center gap-2">
                            <select value={range.start} onChange={(e) => updateRange(key, range.id, "start", e.target.value)} className={selectCls}>
                              {HALF_HOURS.map((t) => <option key={t}>{t}</option>)}
                            </select>
                            <span className="text-xs text-[#957186]">–</span>
                            <select value={range.end} onChange={(e) => updateRange(key, range.id, "end", e.target.value)} className={selectCls}>
                              {HALF_HOURS.map((t) => <option key={t}>{t}</option>)}
                            </select>
                            {schedule[key].ranges.length > 1 && (
                              <button onClick={() => removeRange(key, range.id)} className="p-1 rounded-lg text-gray-300 hover:text-red-400 transition">
                                <X className="h-3.5 w-3.5" />
                              </button>
                            )}
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Preview */}
          <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-6">
            <h2 className="text-sm font-semibold text-[#241715] mb-4 pb-3 border-b border-[#d9b8c4]/30">Preview — as seen by clients</h2>
            <div className="space-y-2">
              {DAYS.map(({ key, label }) => {
                const day = schedule[key];
                return (
                  <div key={key} className="flex items-center gap-4 py-2 border-b border-gray-50 last:border-0">
                    <span className={cn("text-sm w-28 font-medium", day.enabled ? "text-[#241715]" : "text-gray-300")}>{label}</span>
                    {day.enabled && day.ranges.length > 0 ? (
                      <div className="flex flex-wrap gap-2">
                        {day.ranges.map((r: TimeRange) => (
                          <span key={r.id} className="text-xs bg-[#f7f0f4] text-[#703d57] border border-[#d9b8c4]/40 px-2.5 py-1 rounded-lg font-medium">
                            {r.start} – {r.end}
                          </span>
                        ))}
                      </div>
                    ) : (
                      <span className="text-xs text-gray-300">Unavailable</span>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          <div className="flex justify-end">
            <button onClick={saveHours} className="flex items-center gap-2 px-6 py-2.5 rounded-xl bg-[#703d57] text-sm font-semibold text-white hover:bg-[#5a3046] transition">
              {hoursSaved ? <><Check className="h-4 w-4" /> Saved!</> : "Save office hours"}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}