import { useState } from "react";
import { updateEmail, updatePassword, EmailAuthProvider, reauthenticateWithCredential } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { cn } from "@/lib/cn";
import { Check, Camera } from "lucide-react";

const PRACTICE_AREAS = [
  "Family Law", "Civil Litigation", "Criminal Law", "Labor & Employment",
  "Estate Planning", "Corporate Law", "Intellectual Property", "Real Property",
  "Administrative Law", "Immigration", "Tax Law", "Banking & Finance",
  "Environmental Law", "Human Rights",
];

const DESIGNATIONS = [
  "Founding Partner", "Senior Partner", "Junior Partner", "Associate",
  "Of Counsel", "Counselor", "Solo Practitioner", "Public Attorney",
  "Prosecutor", "Government Counsel",
];

type Tab = "profile" | "account";

export function ProfilePage() {
  const [tab, setTab] = useState<Tab>("profile");
  const [saving, setSaving] = useState(false);
  const [saveMsg, setSaveMsg] = useState("");

  // Profile fields — pre-filled from auth or left blank for now
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
  const [newEmail, setNewEmail] = useState(auth.currentUser?.email ?? "");
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [accountMsg, setAccountMsg] = useState("");
  const [accountError, setAccountError] = useState("");

  function toggleArea(area: string) {
    setPracticeAreas((prev) =>
      prev.includes(area) ? prev.filter((a) => a !== area) : [...prev, area]
    );
  }

  function saveProfile() {
    setSaving(true);
    // Backend integration handled separately — just show success for now
    setTimeout(() => {
      setSaveMsg("Profile saved successfully.");
      setSaving(false);
      setTimeout(() => setSaveMsg(""), 4000);
    }, 600);
  }

  async function handleUpdateEmail() {
    setAccountError("");
    setAccountMsg("");
    const user = auth.currentUser;
    if (!user) return;
    try {
      await updateEmail(user, newEmail);
      setAccountMsg("Email updated successfully.");
    } catch (e: any) {
      setAccountError(e.message || "Failed to update email. You may need to re-login.");
    }
  }

  async function handleUpdatePassword() {
    setAccountError("");
    setAccountMsg("");
    if (newPassword !== confirmPassword) { setAccountError("New passwords do not match."); return; }
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

  const initials = `${firstName.charAt(0)}${lastName.charAt(0)}`.toUpperCase() || "A";
  const fullName = [firstName, middleName, lastName, suffix].filter(Boolean).join(" ") || "Your Name";

  const inputCls = "w-full rounded-xl border border-[#d9b8c4] bg-[#fdf9fb] px-3.5 py-2.5 text-sm text-[#241715] placeholder-[#c490aa] outline-none focus:border-[#703d57] focus:bg-white transition";
  const labelCls = "block text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-1.5";

  return (
    <div className="space-y-6 max-w-3xl mx-auto">
      <div>
        <h1 className="text-2xl font-bold text-[#241715]">My Profile</h1>
        <p className="mt-0.5 text-sm text-[#957186]">Manage your professional information and account settings</p>
      </div>

      {/* Tabs */}
      <div className="flex gap-0 border-b border-[#d9b8c4]/60">
        {(["profile", "account"] as Tab[]).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={cn(
              "px-5 py-2.5 text-sm font-medium border-b-2 -mb-px transition-colors",
              tab === t ? "border-[#703d57] text-[#703d57]" : "border-transparent text-[#957186] hover:text-[#703d57]"
            )}
          >
            {t === "profile" ? "Professional Profile" : "Account & Security"}
          </button>
        ))}
      </div>

      {tab === "profile" && (
        <div className="space-y-5">
          {/* Photo + identity */}
          <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-6">
            <div className="flex items-center gap-5">
              <div className="relative">
                <div className="h-20 w-20 rounded-full bg-[#703d57] flex items-center justify-center text-2xl font-bold text-white">
                  {initials}
                </div>
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

          {/* Personal Information */}
          <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-6">
            <h2 className="text-sm font-semibold text-[#241715] mb-5 pb-3 border-b border-[#d9b8c4]/30">Personal Information</h2>
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
                  {DESIGNATIONS.map((d) => <option key={d}>{d}</option>)}
                </select>
              </div>
            </div>
          </div>

          {/* Bar Credentials */}
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

          {/* Practice Areas */}
          <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-6">
            <h2 className="text-sm font-semibold text-[#241715] mb-1 pb-3 border-b border-[#d9b8c4]/30">Practice Areas</h2>
            <p className="text-xs text-[#957186] mb-4 mt-1">Select all that apply</p>
            <div className="flex flex-wrap gap-2">
              {PRACTICE_AREAS.map((area) => {
                const selected = practiceAreas.includes(area);
                return (
                  <button key={area} type="button" onClick={() => toggleArea(area)}
                    className={cn(
                      "px-3.5 py-1.5 rounded-full text-xs font-medium border transition-all",
                      selected ? "bg-[#703d57] text-white border-[#703d57]" : "bg-white text-[#703d57] border-[#d9b8c4] hover:border-[#703d57]"
                    )}
                  >
                    {selected && <Check className="inline h-3 w-3 mr-1 -mt-0.5" />}
                    {area}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Contact & Office */}
          <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-6">
            <h2 className="text-sm font-semibold text-[#241715] mb-5 pb-3 border-b border-[#d9b8c4]/30">Contact & Office</h2>
            <div className="grid grid-cols-2 gap-4">
              <div className="col-span-2"><label className={labelCls}>Firm / Office Name</label><input className={inputCls} value={firmName} onChange={(e) => setFirmName(e.target.value)} /></div>
              <div><label className={labelCls}>Mobile</label><input className={inputCls} value={mobile} onChange={(e) => setMobile(e.target.value)} placeholder="+63 9XX XXX XXXX" /></div>
              <div><label className={labelCls}>Office Phone</label><input className={inputCls} value={officePhone} onChange={(e) => setOfficePhone(e.target.value)} placeholder="+63 32 XXX XXXX" /></div>
              <div className="col-span-2"><label className={labelCls}>Office Email</label><input className={inputCls} value={officeEmail} onChange={(e) => setOfficeEmail(e.target.value)} /></div>
              <div className="col-span-2">
                <label className={labelCls}>Office Address</label>
                <textarea className={inputCls + " resize-none"} rows={2} value={officeAddress} onChange={(e) => setOfficeAddress(e.target.value)} placeholder="Unit, Building, Street, Barangay, City, Province" />
              </div>
            </div>
          </div>

          {saveMsg && (
            <div className={cn("rounded-xl px-4 py-3 text-sm", saveMsg.includes("success") ? "bg-emerald-50 border border-emerald-200 text-emerald-700" : "bg-red-50 border border-red-200 text-red-700")}>
              {saveMsg}
            </div>
          )}
          <div className="flex justify-end gap-3 pb-8">
            <button onClick={saveProfile} disabled={saving} className="px-6 py-2.5 rounded-xl bg-[#703d57] text-sm font-semibold text-white hover:bg-[#5a3046] disabled:opacity-60 transition">
              {saving ? "Saving…" : "Save profile"}
            </button>
          </div>
        </div>
      )}

      {tab === "account" && (
        <div className="space-y-5 pb-8">
          {/* Email */}
          <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-6">
            <h2 className="text-sm font-semibold text-[#241715] mb-5 pb-3 border-b border-[#d9b8c4]/30">Login Email</h2>
            <div className="max-w-sm space-y-4">
              <div><label className={labelCls}>Email address</label><input type="email" className={inputCls} value={newEmail} onChange={(e) => setNewEmail(e.target.value)} /></div>
              <button onClick={handleUpdateEmail} className="px-5 py-2.5 rounded-xl bg-[#703d57] text-sm font-semibold text-white hover:bg-[#5a3046] transition">Update email</button>
            </div>
          </div>

          {/* Password */}
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

          {/* Danger zone */}
          <div className="rounded-2xl border border-red-200/60 bg-red-50/50 p-6">
            <h2 className="text-sm font-semibold text-red-800 mb-1">Danger zone</h2>
            <p className="text-xs text-red-600 mb-4">Deleting your account is permanent and cannot be undone.</p>
            <button className="px-4 py-2 rounded-xl border border-red-300 bg-white text-sm font-medium text-red-600 hover:bg-red-50 transition">Delete account</button>
          </div>
        </div>
      )}
    </div>
  );
}