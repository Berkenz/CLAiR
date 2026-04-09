import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/history/domain/entities/conversation_entity.dart';

abstract class HistoryRepository {
  Future<List<ConversationEntity>> getConversations();
  Future<List<ChatMessageEntity>> getConversationMessages(String conversationId);
  Future<ConversationEntity> updateConversation(
    String conversationId, {
    String? title,
    bool? isPinned,
  });
  Future<void> deleteConversation(String conversationId);
}
