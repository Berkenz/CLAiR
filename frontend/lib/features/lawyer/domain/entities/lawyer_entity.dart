class LawyerEntity {
  final String id;
  final String? displayName;
  final String? designation;
  final List<String> practiceAreas;
  final String? firstName;
  final String? lastName;

  /// Lawyer's written bio shown in the "About" section.
  final String? bio;

  /// Office address text (from `office_address` on the backend).
  final String? officeLocation;

  /// Pre-formatted hours summary derived from [officeHoursData].
  final String? officeHours;

  /// Raw JSONB office-hours schedule from the API (day → {enabled, ranges}).
  final Map<String, dynamic>? officeHoursData;

  /// Contact details.
  final String? officePhone;
  final String? mobilePhone;
  final String? officeEmail;

  /// GPS coordinates set by the lawyer on their profile.
  final double? latitude;
  final double? longitude;

  const LawyerEntity({
    required this.id,
    this.displayName,
    this.designation,
    this.practiceAreas = const [],
    this.firstName,
    this.lastName,
    this.bio,
    this.officeLocation,
    this.officeHours,
    this.officeHoursData,
    this.officePhone,
    this.mobilePhone,
    this.officeEmail,
    this.latitude,
    this.longitude,
  });

  // ── Computed helpers ───────────────────────────────────────────────────────

  String get categoryLine =>
      practiceAreas.isEmpty ? (designation ?? 'Legal practice') : practiceAreas.join(' · ');

  String get shortBioFallback =>
      designation != null && designation!.trim().isNotEmpty
          ? '${designation!.trim()}, supporting clients in matters related to $specialty and related topics.'
          : 'Experienced legal professional focused on $specialty.';

  String get bioOrDefault =>
      (bio?.trim().isNotEmpty ?? false) ? bio!.trim() : shortBioFallback;

  String get officeLocationOrDefault =>
      (officeLocation?.trim().isNotEmpty ?? false)
          ? officeLocation!.trim()
          : 'Provided when your appointment is confirmed.';

  String get officeHoursOrDefault =>
      (officeHours?.trim().isNotEmpty ?? false)
          ? officeHours!.trim()
          : 'Typical weekday hours apply; confirm after booking.';

  bool get hasContactInfo =>
      (officePhone?.trim().isNotEmpty ?? false) ||
      (mobilePhone?.trim().isNotEmpty ?? false) ||
      (officeEmail?.trim().isNotEmpty ?? false);

  String get name {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    final full = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return full.isEmpty ? 'Unknown Lawyer' : full;
  }

  String get specialty =>
      practiceAreas.isNotEmpty ? practiceAreas.first : (designation ?? '—');

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      final a = parts.first.isNotEmpty ? parts.first[0] : '';
      final b = parts.last.isNotEmpty ? parts.last[0] : '';
      return (a + b).toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // ── Parsing ────────────────────────────────────────────────────────────────

  factory LawyerEntity.fromJson(Map<String, dynamic> json) {
    final rawHours = json['office_hours'] as Map<String, dynamic>?;
    return LawyerEntity(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      designation: json['designation'] as String?,
      practiceAreas: (json['practice_areas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      bio: json['bio'] as String?,
      officeLocation: json['office_address'] as String?,
      officeHours: rawHours != null ? _formatOfficeHours(rawHours) : null,
      officeHoursData: rawHours,
      officePhone: json['office_phone'] as String?,
      mobilePhone: json['mobile_phone'] as String?,
      officeEmail: json['office_email'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  /// Converts the JSONB schedule map into a compact human-readable string.
  static String _formatOfficeHours(Map<String, dynamic> raw) {
    const dayOrder = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    const dayLabels = <String, String>{
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'sun': 'Sun',
    };
    final lines = <String>[];
    for (final day in dayOrder) {
      final dayData = raw[day] as Map<String, dynamic>?;
      if (dayData == null) continue;
      final enabled = dayData['enabled'] as bool? ?? false;
      if (!enabled) continue;
      final ranges = dayData['ranges'] as List<dynamic>?;
      if (ranges == null || ranges.isEmpty) continue;
      final range = ranges.first as Map<String, dynamic>;
      final start = range['start'] as String? ?? '';
      final end = range['end'] as String? ?? '';
      if (start.isNotEmpty && end.isNotEmpty) {
        lines.add('${dayLabels[day] ?? day}: $start – $end');
      }
    }
    return lines.isEmpty ? '' : lines.join('\n');
  }
}
