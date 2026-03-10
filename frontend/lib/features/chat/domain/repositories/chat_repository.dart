import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';

abstract class ChatRepository {
  Future<String> sendMessage({
    required String message,
    required List<ChatMessageEntity> history,
  });
}
