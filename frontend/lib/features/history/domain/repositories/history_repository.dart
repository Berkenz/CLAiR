import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/history/domain/entities/conversation_entity.dart';

abstract class HistoryRepository {
  Future<List<ConversationEntity>> getConversations();
  Future<List<ChatMessageEntity>> getConversationMessages(String conversationId);
  Future<void> deleteConversation(String conversationId);
}
