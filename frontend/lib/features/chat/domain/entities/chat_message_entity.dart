import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';

class ChatMessageEntity {
  final String text;
  final bool isUser;
  final String? feedback; // 'like', 'dislike', or null

  /// Lawyers suggested by the AI — populated only on assistant messages
  /// when the backend returned profile cards alongside the reply.
  final List<LawyerEntity> suggestedLawyers;

  const ChatMessageEntity({
    required this.text,
    required this.isUser,
    this.feedback,
    this.suggestedLawyers = const [],
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
    bool clearFeedback = false,
    List<LawyerEntity>? suggestedLawyers,
  }) {
    return ChatMessageEntity(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      suggestedLawyers: suggestedLawyers ?? this.suggestedLawyers,
    );
  }
}
