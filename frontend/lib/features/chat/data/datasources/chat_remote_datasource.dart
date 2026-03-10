import 'package:dio/dio.dart';

import 'package:clair/core/network/api_endpoints.dart';
import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<String> sendMessage({
    required String message,
    required List<ChatMessageEntity> history,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.chatSend,
        data: {
          'message': message,
          'history': history.map((m) => m.toHistoryJson()).toList(),
        },
      );

      if (response.data == null || response.data!['reply'] == null) {
        throw ChatException('Invalid response from server');
      }

      final reply = response.data!['reply'];
      if (reply is String) return reply;
      if (reply is List) return reply.join('\n');
      return reply.toString();
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
