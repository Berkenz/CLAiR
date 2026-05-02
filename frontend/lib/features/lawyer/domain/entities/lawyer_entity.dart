class LawyerEntity {
  final String id;
  final String? displayName;
  final String? designation;
  final List<String> practiceAreas;
  final String? firstName;
  final String? lastName;

  const LawyerEntity({
    required this.id,
    this.displayName,
    this.designation,
    this.practiceAreas = const [],
    this.firstName,
    this.lastName,
  });

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
    );
  }
}
