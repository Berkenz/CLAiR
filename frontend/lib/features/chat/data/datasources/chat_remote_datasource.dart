import 'package:dio/dio.dart';

import 'package:clair/core/network/api_endpoints.dart';
import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/chat/domain/entities/chat_response_entity.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<ChatResponseEntity> sendMessage({
    required String message,
    required List<ChatMessageEntity> history,
    String? conversationId,
  }) async {
    try {
      final data = <String, dynamic>{
        'message': message,
        'history': history.map((m) => m.toHistoryJson()).toList(),
      };
      if (conversationId != null) {
        data['conversation_id'] = conversationId;
      }

      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.chatSend,
        data: data,
      );

      if (response.data == null || response.data!['reply'] == null) {
        throw ChatException('Invalid response from server');
      }

      final reply = response.data!['reply'];
      final replyText =
          reply is String ? reply : (reply is List ? reply.join('\n') : reply.toString());

      return ChatResponseEntity(
        reply: replyText,
        conversationId: response.data!['conversation_id'] as String,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['detail'] != null) {
        final detail = data['detail'];
        if (detail is String) throw ChatException(detail);
        if (detail is List && detail.isNotEmpty) {
          final msg = detail.first;
          if (msg is Map<String, dynamic>) {
            throw ChatException(msg['msg'] as String? ?? 'Validation error');
          }
          throw ChatException(msg.toString());
        }
      }
      throw ChatException('Could not reach CLAiR. Please check your connection.');
    }
  }
}

class ChatException implements Exception {
  ChatException(this.message);
  final String message;

  @override
  String toString() => message;
}
