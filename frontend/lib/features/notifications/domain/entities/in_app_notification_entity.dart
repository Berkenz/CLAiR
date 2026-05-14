class InAppNotificationEntity {
  const InAppNotificationEntity({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.isRead,
    required this.createdAt,
    this.body,
    this.payload,
  });

  final String id;
  final String notificationType;
  final String title;
  final String? body;
  final Map<String, dynamic>? payload;
  final bool isRead;
  final DateTime createdAt;

  String? get appointmentId {
    final raw = payload?['appointment_id'];
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory InAppNotificationEntity.fromJson(Map<String, dynamic> json) {
    return InAppNotificationEntity(
      id: '${json['id'] ?? ''}'.trim(),
      notificationType: '${json['notification_type'] ?? ''}'.trim(),
      title: '${json['title'] ?? ''}'.trim(),
      body: json['body'] as String?,
      payload: json['payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : (json['payload'] is Map
              ? Map<String, dynamic>.from(json['payload'] as Map)
              : null),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse('${json['created_at']}'),
    );
  }
}
