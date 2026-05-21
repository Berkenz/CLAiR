import 'package:clair/shared/utils/profile_photo_url.dart';

class UserEntity {
  const UserEntity({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.location,
    required this.authProvider,
    required this.isEmailVerified,
    required this.isAnonymous,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final String? location;
  final String authProvider;
  final bool isEmailVerified;
  final bool isAnonymous;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    if (isAnonymous) return 'Guest';
    return email ?? 'User';
  }

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    final rawPhoto = json['photo_url'] as String?;
    final photoUrl = rawPhoto != null && rawPhoto.trim().isNotEmpty
        ? profilePhotoCanonicalUrl(rawPhoto)
        : null;

    return UserEntity(
      id: json['id'].toString(),
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      photoUrl: photoUrl,
      location: json['location'] as String?,
      authProvider: json['auth_provider'] as String? ?? 'email',
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toUtc()
          : null,
    );
  }
}
