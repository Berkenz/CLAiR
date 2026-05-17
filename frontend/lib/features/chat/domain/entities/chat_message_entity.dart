import 'package:clair/features/chat/domain/entities/rag_source_entity.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';

class ChatMessageEntity {
  final String? id;
  final String text;
  final bool isUser;
  final String? feedback; // 'like', 'dislike', or null

  /// Lawyers suggested by the AI — populated only on assistant messages
  /// when the backend returned profile cards alongside the reply.
  final List<LawyerEntity> suggestedLawyers;

  /// Retrieved law excerpts for this assistant turn (RAG), when any.
  final List<RagSourceEntity> ragSources;

  /// Whether the server had RAG configured for this turn (`null` = e.g. history load).
  final bool? ragEnabled;

  /// A lawyer flagged this assistant reply during QA (shown when reopening saved chats).
  final bool lawyerReported;

  const ChatMessageEntity({
    this.id,
    required this.text,
    required this.isUser,
    this.feedback,
    this.suggestedLawyers = const [],
    this.ragSources = const [],
    this.ragEnabled,
    this.lawyerReported = false,
  });

  String get role => isUser ? 'user' : 'model';

  Map<String, dynamic> toHistoryJson() => {
        'role': role,
        'text': text,
      };

  ChatMessageEntity copyWith({
    String? id,
    String? text,
    bool? isUser,
    String? feedback,
    bool clearFeedback = false,
    List<LawyerEntity>? suggestedLawyers,
    List<RagSourceEntity>? ragSources,
    bool? ragEnabled,
    bool clearRagEnabled = false,
    bool? lawyerReported,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      suggestedLawyers: suggestedLawyers ?? this.suggestedLawyers,
      ragSources: ragSources ?? this.ragSources,
      ragEnabled: clearRagEnabled ? null : (ragEnabled ?? this.ragEnabled),
      lawyerReported: lawyerReported ?? this.lawyerReported,
    );
  }
}
