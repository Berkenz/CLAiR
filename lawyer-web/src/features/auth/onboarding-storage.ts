function flowKey(uid: string, step: "passwordChanged" | "profileComplete") {
  return `clair_${uid}_${step}`;
}

export function markPasswordChanged(uid: string) {
  localStorage.setItem(flowKey(uid, "passwordChanged"), "true");
}

export function markProfileComplete(uid: string) {
  localStorage.setItem(flowKey(uid, "profileComplete"), "true");
}

export function clearPasswordChanged(uid: string) {
  localStorage.removeItem(flowKey(uid, "passwordChanged"));
}

export function clearProfileComplete(uid: string) {
  localStorage.removeItem(flowKey(uid, "profileComplete"));
}

export function hasChangedPassword(uid: string) {
  return localStorage.getItem(flowKey(uid, "passwordChanged")) === "true";
}

export function hasCompletedProfile(uid: string) {
  return localStorage.getItem(flowKey(uid, "profileComplete")) === "true";
}

export type OnboardingProfileFlags = {
  must_change_password: boolean;
  is_profile_complete: boolean;
};

/** Prefer backend profile flags when available (localStorage can be stale). */
export function getNextStep(
  uid: string,
  profile?: OnboardingProfileFlags | null,
): "/change-password" | "/profile-setup" | "/" {
  if (profile) {
    if (profile.must_change_password) return "/change-password";
    if (!profile.is_profile_complete) return "/profile-setup";
    return "/";
  }
  if (!hasChangedPassword(uid)) return "/change-password";
  if (!hasCompletedProfile(uid)) return "/profile-setup";
  return "/";
}

export function syncOnboardingFromProfile(
  uid: string,
  profile: OnboardingProfileFlags,
): void {
  if (profile.must_change_password) {
    clearPasswordChanged(uid);
    clearProfileComplete(uid);
  } else {
    markPasswordChanged(uid);
  }
  if (profile.is_profile_complete) {
    markProfileComplete(uid);
  } else {
    clearProfileComplete(uid);
  }
}
