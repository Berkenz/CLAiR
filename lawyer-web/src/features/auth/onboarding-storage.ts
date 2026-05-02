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

export function getNextStep(uid: string): "/change-password" | "/profile-setup" | "/" {
  if (!hasChangedPassword(uid)) return "/change-password";
  if (!hasCompletedProfile(uid)) return "/profile-setup";
  return "/";
}
