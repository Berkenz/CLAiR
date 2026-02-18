class UserEntity {
  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isActive;
  final DateTime createdAt;
}
