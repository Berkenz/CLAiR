import { useEffect, useRef, useState, type ChangeEvent } from "react";
import { useNavigate } from "react-router-dom";
import {
  updateEmail,
  updatePassword,
  EmailAuthProvider,
  reauthenticateWithCredential,
  deleteUser,
  signOut,
} from "firebase/auth";
import axios from "axios";
import { auth } from "@/lib/firebase";
import { api } from "@/lib/api";
import { getApiErrorMessage, getApiErrorMessageWithNetworkHint } from "@/lib/api-error";
import { useAuth, type LawyerState } from "@/features/auth/auth-provider";
import { buildLawyerProfileUpdateBody } from "@/features/lawyer/profile-update-body";
import { LocationPicker } from "@/features/profile/components/LocationPicker";
import { ProfilePhotoCropModal } from "@/components/profile-photo-crop-modal";
import { cn } from "@/lib/cn";
import { Check, Camera } from "lucide-react";

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

type Tab = "profile" | "account" | "hours" | "location";

// ─── Component ────────────────────────────────────────────────────────────────

export function ProfilePage() {
  const navigate = useNavigate();
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

  // Profile fields — name & practice areas sync to the CLAiR API
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
  const [bio, setBio] = useState("");

  // Account fields
  const [newEmail, setNewEmail] = useState("");
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [accountMsg, setAccountMsg] = useState("");
  const [accountError, setAccountError] = useState("");
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [deletePassword, setDeletePassword] = useState("");
  const [deleteConfirmed, setDeleteConfirmed] = useState(false);
  const [deletingAccount, setDeletingAccount] = useState(false);

  // Office location coordinates — persisted with the profile
  const [latitude, setLatitude] = useState<number | null>(null);
  const [longitude, setLongitude] = useState<number | null>(null);

  // Office hours — persisted to the backend via PUT /lawyer/profile
  const [schedule, setSchedule] = useState<Schedule>(JSON.parse(JSON.stringify(STANDARD_SCHEDULE)));
  const [hoursSaved, setHoursSaved] = useState(false);
  const [hoursSaving, setHoursSaving] = useState(false);
  const [hoursError, setHoursError] = useState("");

  const photoInputRef = useRef<HTMLInputElement>(null);
  const [photoUploading, setPhotoUploading] = useState(false);
  const [photoError, setPhotoError] = useState("");
  const [photoMsg, setPhotoMsg] = useState("");
  const [cropImageSrc, setCropImageSrc] = useState<string | null>(null);

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
    setBio(p.bio ?? "");
    if (p.office_hours) {
      setSchedule(p.office_hours as Schedule);
    }
    setLatitude(p.latitude ?? null);
    setLongitude(p.longitude ?? null);
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
        bio,
        latitude,
        longitude,
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

  function closeDeleteModal() {
    if (deletingAccount) return;
    setDeleteModalOpen(false);
    setDeletePassword("");
    setDeleteConfirmed(false);
    setAccountError("");
  }

  function firebaseAuthErrorMessage(err: unknown): string | null {
    const code =
      err && typeof err === "object" && "code" in err
        ? String((err as { code: string }).code)
        : "";
    const message =
      err && typeof err === "object" && "message" in err
        ? String((err as { message: string }).message)
        : "";
    switch (code) {
      case "auth/wrong-password":
      case "auth/invalid-credential":
        return "Incorrect password. Please try again.";
      case "auth/requires-recent-login":
        return "Session expired. Enter your password and try again.";
      case "auth/too-many-requests":
        return "Too many attempts. Please wait a moment and try again.";
      default:
        return message || null;
    }
  }

  async function handleDeleteAccount() {
    setAccountError("");
    const user = auth.currentUser;
    if (!user?.email) {
      setAccountError("You are not signed in. Please sign in and try again.");
      return;
    }
    if (!deletePassword.trim()) {
      setAccountError("Please enter your password to confirm account deletion.");
      return;
    }
    if (!deleteConfirmed) {
      setAccountError("Please confirm that you understand this action is permanent.");
      return;
    }

    setDeletingAccount(true);
    try {
      const cred = EmailAuthProvider.credential(user.email, deletePassword);
      await reauthenticateWithCredential(user, cred);
    } catch (err: unknown) {
      setAccountError(
        firebaseAuthErrorMessage(err) ?? "Could not verify your password. Please try again.",
      );
      setDeletingAccount(false);
      return;
    }

    try {
      await api.delete("/lawyer/auth/account");
    } catch (err: unknown) {
      if (axios.isAxiosError(err) && err.response?.status === 404) {
        setAccountError(
          "Delete account is not available on the server yet. Restart the API so it loads the latest code.",
        );
      } else {
        setAccountError(
          getApiErrorMessageWithNetworkHint(
            err,
            "Could not delete account on the server. Please try again.",
          ),
        );
      }
      setDeletingAccount(false);
      return;
    }

    try {
      await deleteUser(user);
    } catch (err: unknown) {
      setAccountError(
        firebaseAuthErrorMessage(err) ??
          "Your data was removed, but we could not delete your sign-in. Contact support or try again.",
      );
      setDeletingAccount(false);
      return;
    }

    try {
      await signOut(auth);
      navigate("/login", { replace: true });
    } catch {
      navigate("/login", { replace: true });
    } finally {
      setDeletingAccount(false);
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
  async function uploadProfilePhoto(file: File) {
    setPhotoError("");
    setPhotoMsg("");
    const fb = auth.currentUser;
    if (!fb) {
      setPhotoError("Not signed in.");
      return;
    }
    setPhotoUploading(true);
    try {
      await fb.getIdToken(true);
      const token = await fb.getIdToken();
      const fd = new FormData();
      fd.append("file", file);
      const envBase = import.meta.env.VITE_API_BASE_URL as string | undefined;
      const base = (envBase?.replace(/\/$/, "")) || "/api/v1";
      const res = await fetch(`${base}/users/me/photo`, {
        method: "POST",
        headers: { Authorization: `Bearer ${token}` },
        body: fd,
      });
      if (!res.ok) {
        let detail = `Upload failed (${res.status})`;
        try {
          const j = (await res.json()) as { detail?: unknown };
          const d = j.detail;
          if (typeof d === "string") detail = d;
          else if (Array.isArray(d))
            detail = d
              .map((x) => (typeof x === "object" && x && "msg" in x ? String((x as { msg: string }).msg) : ""))
              .filter(Boolean)
              .join(" ") || detail;
        } catch {
          /* keep detail */
        }
        throw new Error(detail);
      }
      await refreshLawyerState();
      setPhotoMsg("Profile photo updated.");
      setTimeout(() => setPhotoMsg(""), 4000);
    } catch (e: unknown) {
      setPhotoError(e instanceof Error ? e.message : "Could not upload photo.");
    } finally {
      setPhotoUploading(false);
      if (photoInputRef.current) photoInputRef.current.value = "";
    }
  }

  function closeCropModal() {
    if (cropImageSrc) URL.revokeObjectURL(cropImageSrc);
    setCropImageSrc(null);
    if (photoInputRef.current) photoInputRef.current.value = "";
  }

  function onPhotoPicked(e: ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setPhotoError("");
    setPhotoMsg("");
    if (!file.type.startsWith("image/")) {
      setPhotoError("Please choose an image (JPEG, PNG, WebP, or GIF).");
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      setPhotoError("Image must be 5 MB or smaller.");
      return;
    }
    setCropImageSrc(URL.createObjectURL(file));
  }

  function onCropConfirmed(file: File) {
    closeCropModal();
    void uploadProfilePhoto(file);
  }

  async function saveHours() {
    setHoursError("");
    setHoursSaving(true);
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
        bio,
        officeHours: schedule,
      });
      const { data } = await api.put<LawyerState>("/lawyer/profile", body);
      setLawyerState(data);
      setHoursSaved(true);
      setTimeout(() => setHoursSaved(false), 2500);
    } catch (err) {
      setHoursError(getApiErrorMessage(err, "Could not save office hours. Please try again."));
    } finally {
      setHoursSaving(false);
    }
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
    { key: "profile",  label: "Professional Profile" },
    { key: "account",  label: "Account & Security" },
    { key: "hours",    label: "Office Hours" },
    { key: "location", label: "Office Location" },
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
                <input
                  ref={photoInputRef}
                  type="file"
                  accept="image/jpeg,image/jpg,image/png,image/webp,image/gif"
                  className="hidden"
                  onChange={onPhotoPicked}
                />
                <div className="h-20 w-20 rounded-full bg-[#703d57] overflow-hidden flex items-center justify-center text-2xl font-bold text-white shrink-0">
                  {lawyerState?.user.photo_url ? (
                    <img
                      key={lawyerState.user.photo_url}
                      src={lawyerState.user.photo_url}
                      alt=""
                      className="h-full w-full object-cover"
                    />
                  ) : (
                    initials
                  )}
                </div>
                <button
                  type="button"
                  disabled={photoUploading || !lawyerState}
                  onClick={() => photoInputRef.current?.click()}
                  title="Upload profile photo"
                  className="absolute bottom-0 right-0 h-7 w-7 rounded-full bg-white border border-[#d9b8c4] flex items-center justify-center shadow-sm hover:bg-[#f7f0f4] transition disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <Camera className="h-3.5 w-3.5 text-[#703d57]" />
                </button>
              </div>
              <div className="min-w-0 flex-1">
                <p className="text-lg font-bold text-[#241715]">{fullName}</p>
                <p className="text-sm text-[#957186]">{designation || "—"} · {practiceAreas.slice(0, 2).join(", ") || "No practice areas set"}</p>
                {photoUploading && (
                  <p className="text-xs text-[#703d57] mt-2">Uploading…</p>
                )}
                {photoMsg && (
                  <p className="text-xs text-emerald-700 mt-2">{photoMsg}</p>
                )}
                {photoError && (
                  <p className="text-xs text-red-600 mt-2">{photoError}</p>
                )}
                <p className="text-[11px] text-[#c490aa] mt-2">
                  JPEG, PNG, WebP, or GIF · max 5 MB · crop before upload.
                </p>
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
              <div className="col-span-2">
                <label className={labelCls}>Bio / About</label>
                <textarea
                  className={inputCls + " resize-none"}
                  rows={4}
                  value={bio}
                  onChange={(e) => setBio(e.target.value)}
                  placeholder="Write a short bio that clients will see on your profile, e.g. areas of expertise, years of experience, approach to clients."
                />
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
            <button
              type="button"
              onClick={() => {
                setAccountError("");
                setDeletePassword("");
                setDeleteConfirmed(false);
                setDeleteModalOpen(true);
              }}
              className="px-4 py-2 rounded-xl border border-red-300 bg-white text-sm font-medium text-red-600 hover:bg-red-50 transition"
            >
              Delete account
            </button>
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

          <div className="flex flex-col items-end gap-2">
            {hoursError && <p className="text-xs text-red-500">{hoursError}</p>}
            <button
              onClick={saveHours}
              disabled={hoursSaving || !lawyerState}
              className="flex items-center gap-2 px-6 py-2.5 rounded-xl bg-[#703d57] text-sm font-semibold text-white hover:bg-[#5a3046] transition disabled:opacity-60 disabled:cursor-not-allowed"
            >
              {hoursSaved ? <><Check className="h-4 w-4" /> Saved!</> : hoursSaving ? "Saving…" : "Save office hours"}
            </button>
          </div>
        </div>
      )}

      {/* ── Tab: Office Location ── */}
      {tab === "location" && (
        <div className="space-y-5 pb-8">
          <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-6">
            <h2 className="text-sm font-semibold text-[#241715] mb-1 pb-3 border-b border-[#d9b8c4]/30">
              Office Location on Map
            </h2>
            <p className="text-xs text-[#957186] mt-3 mb-4">
              Pin your office location so clients can find you on the map in the CLAiR mobile app.
              Search your address or use "My location", then click the map or drag the pin to fine-tune.
            </p>
            <LocationPicker
              lat={latitude}
              lng={longitude}
              onChange={(lat, lng) => { setLatitude(lat); setLongitude(lng); }}
              onAddressInferred={setOfficeAddress}
            />
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
          <div className="flex justify-end">
            <button
              type="button"
              onClick={() => void saveProfile()}
              disabled={saving || !lawyerState}
              className="px-6 py-2.5 rounded-xl bg-[#703d57] text-sm font-semibold text-white hover:bg-[#5a3046] disabled:opacity-60 transition"
            >
              {saving ? "Saving…" : "Save location"}
            </button>
          </div>
        </div>
      )}

      {cropImageSrc && (
        <ProfilePhotoCropModal
          imageSrc={cropImageSrc}
          onCancel={closeCropModal}
          onConfirm={onCropConfirmed}
          confirming={photoUploading}
        />
      )}

      {deleteModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-2xl bg-white shadow-xl p-6">
            <h2 className="font-bold text-[#241715] text-lg mb-2">Delete account?</h2>
            <p className="text-sm text-[#957186] mb-4">
              This permanently removes your lawyer profile, appointments, messages, and
              notifications. This cannot be undone.
            </p>
            <div className="space-y-4">
              <div>
                <label className={labelCls}>Password</label>
                <input
                  type="password"
                  className={inputCls}
                  value={deletePassword}
                  onChange={(e) => setDeletePassword(e.target.value)}
                  placeholder="Enter your password to confirm"
                  disabled={deletingAccount}
                  autoComplete="current-password"
                />
              </div>
              <label className="flex items-start gap-2.5 cursor-pointer">
                <input
                  type="checkbox"
                  checked={deleteConfirmed}
                  onChange={(e) => setDeleteConfirmed(e.target.checked)}
                  disabled={deletingAccount}
                  className="mt-0.5 h-4 w-4 rounded border-[#d9b8c4] text-[#703d57] focus:ring-[#703d57]/30"
                />
                <span className="text-xs text-[#5a3046] leading-relaxed">
                  I understand this will permanently delete my account and all associated data.
                </span>
              </label>
            </div>
            {accountError && deleteModalOpen && (
              <p className="mt-4 text-sm text-red-600">{accountError}</p>
            )}
            <div className="flex gap-3 mt-6">
              <button
                type="button"
                onClick={closeDeleteModal}
                disabled={deletingAccount}
                className="flex-1 rounded-xl border border-[#d9b8c4]/60 py-2.5 text-sm font-semibold text-[#402a2c] hover:bg-[#f7f0f4] transition-colors disabled:opacity-60"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={() => void handleDeleteAccount()}
                disabled={deletingAccount || !deleteConfirmed || !deletePassword.trim()}
                className="flex-1 rounded-xl bg-red-600 py-2.5 text-sm font-semibold text-white hover:bg-red-700 transition-colors disabled:opacity-60"
              >
                {deletingAccount ? "Deleting…" : "Delete account"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}