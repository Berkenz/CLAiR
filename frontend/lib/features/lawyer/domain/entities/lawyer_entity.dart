class LawyerEntity {
  final String id;
  final String? displayName;
  final String? designation;
  final List<String> practiceAreas;
  final String? firstName;
  final String? lastName;
  /// Optional narrative from API — shown on lawyer overview when set.
  final String? bio;
  /// Office address or locality from API — optional until backend supports it.
  final String? officeLocation;
  /// Human-readable schedule line from API — optional until backend supports it.
  final String? officeHours;

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
  });

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

  factory LawyerEntity.fromJson(Map<String, dynamic> json) {
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
      officeLocation: json['office_location'] as String?,
      officeHours: json['office_hours'] as String?,
    );
  }
}
