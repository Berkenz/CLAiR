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

      return response.data!['reply'] as String;
    } on DioException catch (e) {
      final detail = e.response?.data;
      if (detail is Map<String, dynamic> && detail['detail'] != null) {
        throw ChatException(detail['detail'] as String);
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
