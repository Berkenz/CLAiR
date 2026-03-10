class ChatMessageEntity {
  final String text;
  final bool isUser;

  const ChatMessageEntity({required this.text, required this.isUser});

  String get role => isUser ? 'user' : 'model';

  Map<String, dynamic> toHistoryJson() => {
        'role': role,
        'text': text,
      };
}
