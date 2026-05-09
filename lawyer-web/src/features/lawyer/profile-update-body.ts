/** Request body for `PUT /lawyer/profile` (matches backend `LawyerProfileUpdate`). */

type OfficeHoursSchedule = Record<
  string,
  { enabled: boolean; ranges: { id: string; start: string; end: string }[] }
>;

export interface LawyerProfileUpdateBody {
  first_name: string;
  last_name: string;
  display_name: string;
  designation: string;
  practice_areas: string[];
  middle_name?: string | null;
  name_suffix?: string | null;
  ibp_roll_number?: string | null;
  year_admitted?: string | null;
  ibp_chapter?: string | null;
  ptr_number?: string | null;
  mcle_compliance_number?: string | null;
  law_school?: string | null;
  firm_name?: string | null;
  office_phone?: string | null;
  mobile_phone?: string | null;
  office_email?: string | null;
  office_address?: string | null;
  bio?: string | null;
  office_hours?: OfficeHoursSchedule | null;
  latitude?: number | null;
  longitude?: number | null;
}

function emptyToNull(s: string): string | null {
  const t = s.trim();
  return t.length ? t : null;
}

export function buildLawyerProfileUpdateBody(input: {
  firstName: string;
  middleName: string;
  lastName: string;
  suffix: string;
  displayName: string;
  designation: string;
  practiceAreas: string[];
  ibpRoll: string;
  yearAdmitted: string;
  ibpChapter: string;
  ptrNumber: string;
  mcleNumber: string;
  lawSchool: string;
  firmName: string;
  officePhone: string;
  mobile: string;
  officeEmail: string;
  officeAddress: string;
  bio?: string | null;
  officeHours?: OfficeHoursSchedule | null;
  latitude?: number | null;
  longitude?: number | null;
}): LawyerProfileUpdateBody {
  const fn = input.firstName.trim();
  const ln = input.lastName.trim();
  const display =
    input.displayName.trim() ||
    (fn && ln ? `Atty. ${fn} ${ln}` : fn || ln || "Lawyer");

  return {
    first_name: fn,
    last_name: ln,
    display_name: display,
    designation: input.designation.trim(),
    practice_areas: input.practiceAreas,
    middle_name: emptyToNull(input.middleName),
    name_suffix: emptyToNull(input.suffix),
    ibp_roll_number: emptyToNull(input.ibpRoll),
    year_admitted: emptyToNull(input.yearAdmitted),
    ibp_chapter: emptyToNull(input.ibpChapter),
    ptr_number: emptyToNull(input.ptrNumber),
    mcle_compliance_number: emptyToNull(input.mcleNumber),
    law_school: emptyToNull(input.lawSchool),
    firm_name: emptyToNull(input.firmName),
    office_phone: emptyToNull(input.officePhone),
    mobile_phone: emptyToNull(input.mobile),
    office_email: emptyToNull(input.officeEmail),
    office_address: emptyToNull(input.officeAddress),
    bio: input.bio != null ? (input.bio.trim() || null) : null,
    office_hours: input.officeHours ?? null,
    latitude: input.latitude ?? null,
    longitude: input.longitude ?? null,
  };
}
