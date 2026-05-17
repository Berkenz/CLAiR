import 'package:clair/features/chat/domain/entities/rag_source_entity.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';

class ChatResponseEntity {
  final String reply;
  final String conversationId;
  final String conversationTitle;
  final String? userMessageId;
  final String? assistantMessageId;
  final List<LawyerEntity> suggestedLawyers;
  /// Whether the server had RAG URLs configured for this turn (`null` if the API did not send the field).
  final bool? ragEnabled;
  final List<RagSourceEntity> ragSources;

  const ChatResponseEntity({
    required this.reply,
    required this.conversationId,
    required this.conversationTitle,
    this.userMessageId,
    this.assistantMessageId,
    this.suggestedLawyers = const [],
    this.ragEnabled,
    this.ragSources = const [],
  });
}
