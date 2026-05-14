class DirectMessageEntity {
  const DirectMessageEntity({
    required this.id,
    required this.appointmentId,
    required this.senderType,
    required this.isRead,
    required this.createdAt,
    this.content,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentContentType,
  });

  final String id;
  final String appointmentId;

  /// "client" or "lawyer"
  final String senderType;

  final String? content;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentContentType;
  final bool isRead;
  final DateTime createdAt;

  bool get isFromClient => senderType == 'client';
  bool get isFromLawyer => senderType == 'lawyer';
  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;

  bool get isImage {
    final ct = attachmentContentType?.toLowerCase() ?? '';
    return ct.startsWith('image/');
  }

  factory DirectMessageEntity.fromJson(Map<String, dynamic> json) {
    return DirectMessageEntity(
      id: '${json['id'] ?? ''}',
      appointmentId: '${json['appointment_id'] ?? ''}',
      senderType: '${json['sender_type'] ?? 'client'}',
      content: json['content'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      attachmentName: json['attachment_name'] as String?,
      attachmentContentType: json['attachment_content_type'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse('${json['created_at']}'),
    );
  }
}
