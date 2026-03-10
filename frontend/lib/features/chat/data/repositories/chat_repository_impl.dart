import 'package:clair/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required ChatRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final ChatRemoteDataSource _remote;

  @override
  Future<String> sendMessage({
    required String message,
    required List<ChatMessageEntity> history,
  }) =>
      _remote.sendMessage(message: message, history: history);
}
