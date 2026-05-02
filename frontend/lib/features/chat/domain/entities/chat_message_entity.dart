class ChatMessageEntity {
  final String text;
  final bool isUser;
  final String? feedback; // 'like', 'dislike', or null

  const ChatMessageEntity({
    required this.text,
    required this.isUser,
    this.feedback,
  });

  String get role => isUser ? 'user' : 'model';

  Map<String, dynamic> toHistoryJson() => {
        'role': role,
        'text': text,
      };

  ChatMessageEntity copyWith({
    String? text,
    bool? isUser,
    String? feedback,
  }) {
    return ChatMessageEntity(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      feedback: feedback ?? this.feedback,
    );
  }
}
