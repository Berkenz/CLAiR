class ConversationEntity {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ConversationEntity({
    required this.id,
    required this.title,
    required this.createdAt,
    this.updatedAt,
  });

  factory ConversationEntity.fromJson(Map<String, dynamic> json) {
    return ConversationEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
