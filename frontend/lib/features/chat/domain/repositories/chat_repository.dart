import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/chat/domain/entities/chat_response_entity.dart';

abstract class ChatRepository {
  Future<ChatResponseEntity> sendMessage({
    required String message,
    required List<ChatMessageEntity> history,
    String? conversationId,
    double? userLat,
    double? userLng,
    String locale = 'en',
  });
}
