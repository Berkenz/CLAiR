import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/history/data/datasources/history_remote_datasource.dart';
import 'package:clair/features/history/domain/entities/conversation_entity.dart';
import 'package:clair/features/history/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl({required HistoryRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final HistoryRemoteDataSource _remote;

  @override
  Future<List<ConversationEntity>> getConversations() =>
      _remote.getConversations();

  @override
  Future<List<ChatMessageEntity>> getConversationMessages(
    String conversationId,
  ) =>
      _remote.getConversationMessages(conversationId);

  @override
  Future<void> deleteConversation(String conversationId) =>
      _remote.deleteConversation(conversationId);
}
