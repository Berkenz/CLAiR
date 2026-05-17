import 'dart:typed_data';

import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/history/data/datasources/history_remote_datasource.dart';
import 'package:clair/features/history/domain/entities/conversation_entity.dart';
import 'package:clair/features/history/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl({required HistoryRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final HistoryRemoteDataSource _remote;

  @override
  Future<List<ConversationEntity>> getConversations({String? query}) =>
      _remote.getConversations(query: query);

  @override
  Future<List<ChatMessageEntity>> getConversationMessages(
    String conversationId,
  ) =>
      _remote.getConversationMessages(conversationId);

  @override
  Future<String> summarizeConversationForAppointment(String conversationId) =>
      _remote.summarizeConversationForAppointment(conversationId);

  @override
  Future<ConversationEntity> updateConversation(
    String conversationId, {
    String? title,
    bool? isPinned,
  }) =>
      _remote.updateConversation(conversationId, title: title, isPinned: isPinned);

  @override
  Future<Uint8List> downloadPdf(String conversationId) =>
      _remote.downloadPdf(conversationId);

  @override
  Future<void> deleteConversation(String conversationId) =>
      _remote.deleteConversation(conversationId);
}
