class UserEntity {
  const UserEntity({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.photoUrl,
    required this.authProvider,
    required this.isEmailVerified,
    required this.isAnonymous,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final String authProvider;
  final bool isEmailVerified;
  final bool isAnonymous;
  final bool isActive;
  final DateTime createdAt;

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    if (isAnonymous) return 'Guest';
    return email ?? 'User';
  }

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      authProvider: json['auth_provider'] as String? ?? 'email',
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
