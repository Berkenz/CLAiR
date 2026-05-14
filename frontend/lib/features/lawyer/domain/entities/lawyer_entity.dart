class LawyerEntity {
  final String id;
  final String? displayName;
  final String? designation;
  final List<String> practiceAreas;
  final String? firstName;
  final String? lastName;

  /// Public profile photo URL (Supabase `profile-photos`; set from lawyer web / users API).
  final String? photoUrl;

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
    this.photoUrl,
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

  /// Fills [photoUrl] from [other] when this entity has no photo (e.g. chat
  /// suggested-lawyer payloads merged with directory cache).
  LawyerEntity mergePhotoFrom(LawyerEntity? other) {
    if (other == null) return this;
    if (id != other.id) return this;
    final o = other.photoUrl?.trim();
    if (o == null || o.isEmpty) return this;
    final mine = photoUrl?.trim();
    if (mine != null && mine.isNotEmpty) return this;
    return LawyerEntity(
      id: id,
      displayName: displayName,
      designation: designation,
      practiceAreas: practiceAreas,
      firstName: firstName,
      lastName: lastName,
      photoUrl: o,
      bio: bio,
      officeLocation: officeLocation,
      officeHours: officeHours,
      officeHoursData: officeHoursData,
      officePhone: officePhone,
      mobilePhone: mobilePhone,
      officeEmail: officeEmail,
      latitude: latitude,
      longitude: longitude,
    );
  }

  // ── Parsing ────────────────────────────────────────────────────────────────

  static String? _photoUrlFromJson(Map<String, dynamic> json) {
    const keys = ['photo_url', 'photoUrl', 'profile_photo_url'];
    for (final key in keys) {
      final v = json[key];
      if (v is String) {
        final s = v.trim();
        if (s.isNotEmpty) return s;
      }
      if (v is Map) {
        final m = Map<String, dynamic>.from(v);
        final nested = m['publicUrl'] ?? m['public_url'];
        if (nested is String && nested.trim().isNotEmpty) {
          return nested.trim();
        }
      }
    }
    return null;
  }

  factory LawyerEntity.fromJson(Map<String, dynamic> json) {
    final id = '${json['id'] ?? ''}'.trim();
    if (id.isEmpty) {
      throw const FormatException('Lawyer directory item missing id');
    }

    final rawHours = _parseOfficeHoursMap(json['office_hours']);
    String? hoursText;
    if (rawHours != null) {
      try {
        hoursText = _formatOfficeHours(rawHours);
      } catch (_) {
        hoursText = null;
      }
    }

    return LawyerEntity(
      id: id,
      displayName: json['display_name'] as String?,
      designation: json['designation'] as String?,
      practiceAreas: _parsePracticeAreas(json['practice_areas']),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      photoUrl: _photoUrlFromJson(json),
      bio: json['bio'] as String?,
      officeLocation: json['office_address'] as String?,
      officeHours: hoursText,
      officeHoursData: rawHours,
      officePhone: json['office_phone'] as String?,
      mobilePhone: json['mobile_phone'] as String?,
      officeEmail: json['office_email'] as String?,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
    );
  }

  static Map<String, dynamic>? _parseOfficeHoursMap(Object? value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<String> _parsePracticeAreas(Object? value) {
    if (value is! List) return [];
    final out = <String>[];
    for (final e in value) {
      if (e is String && e.trim().isNotEmpty) {
        out.add(e.trim());
      } else if (e != null) {
        final s = e.toString().trim();
        if (s.isNotEmpty) out.add(s);
      }
    }
    return out;
  }

  static double? _parseDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
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
      final dayVal = raw[day];
      if (dayVal is! Map) continue;
      final dayData = Map<String, dynamic>.from(dayVal);
      final enabled = dayData['enabled'] as bool? ?? false;
      if (!enabled) continue;
      final rangesRaw = dayData['ranges'];
      if (rangesRaw is! List || rangesRaw.isEmpty) continue;
      final first = rangesRaw.first;
      if (first is! Map) continue;
      final range = Map<String, dynamic>.from(first);
      final start = '${range['start'] ?? ''}'.trim();
      final end = '${range['end'] ?? ''}'.trim();
      if (start.isNotEmpty && end.isNotEmpty) {
        lines.add('${dayLabels[day] ?? day}: $start – $end');
      }
    }
    return lines.isEmpty ? '' : lines.join('\n');
  }
}
