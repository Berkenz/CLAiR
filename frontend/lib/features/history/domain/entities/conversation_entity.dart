class ConversationEntity {
  final String id;
  final String title;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ConversationEntity({
    required this.id,
    required this.title,
    this.isPinned = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory ConversationEntity.fromJson(Map<String, dynamic> json) {
    return ConversationEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  ConversationEntity copyWith({
    String? title,
    bool? isPinned,
  }) {
    return ConversationEntity(
      id: id,
      title: title ?? this.title,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
