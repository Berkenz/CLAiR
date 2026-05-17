import 'package:clair/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/chat/domain/entities/chat_response_entity.dart';
import 'package:clair/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required ChatRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final ChatRemoteDataSource _remote;

  @override
  Future<ChatResponseEntity> sendMessage({
    required String message,
    required List<ChatMessageEntity> history,
    String? conversationId,
    double? userLat,
    double? userLng,
    String locale = 'en',
  }) =>
      _remote.sendMessage(
        message: message,
        history: history,
        conversationId: conversationId,
        userLat: userLat,
        userLng: userLng,
        locale: locale,
      );

  @override
  Future<void> reportConversation({
    required String category,
    required String explanation,
    required List<ChatMessageEntity> messages,
    String? conversationId,
    String? reportedMessageExcerpt,
  }) =>
      _remote.reportConversation(
        category: category,
        explanation: explanation,
        messages: messages,
        conversationId: conversationId,
        reportedMessageExcerpt: reportedMessageExcerpt,
      );

  @override
  Future<void> reportUser({
    String? reportedUserId,
    String? reportedLawyerProfileId,
    required String category,
    required String explanation,
  }) =>
      _remote.reportUser(
        reportedUserId: reportedUserId,
        reportedLawyerProfileId: reportedLawyerProfileId,
        category: category,
        explanation: explanation,
      );
}
