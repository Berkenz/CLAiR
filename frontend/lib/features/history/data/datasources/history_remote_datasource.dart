import 'package:dio/dio.dart';

import 'package:clair/core/network/api_endpoints.dart';
import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/history/domain/entities/conversation_entity.dart';

class HistoryRemoteDataSource {
  HistoryRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<ConversationEntity>> getConversations() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.conversations,
      );

      final data = response.data;
      if (data == null || data['conversations'] == null) return [];

      final list = data['conversations'] as List;
      return list
          .map((c) => ConversationEntity.fromJson(c as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw HistoryException(_extractError(e));
    }
  }

  Future<List<ChatMessageEntity>> getConversationMessages(
    String conversationId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.conversationDetail(conversationId),
      );

      final data = response.data;
      if (data == null || data['messages'] == null) return [];

      final list = data['messages'] as List;
      return list.map((m) {
        final map = m as Map<String, dynamic>;
        return ChatMessageEntity(
          text: map['text'] as String,
          isUser: map['role'] == 'user',
        );
      }).toList();
    } on DioException catch (e) {
      throw HistoryException(_extractError(e));
    }
  }

  Future<ConversationEntity> updateConversation(
    String conversationId, {
    String? title,
    bool? isPinned,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (isPinned != null) body['is_pinned'] = isPinned;

      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.conversationUpdate(conversationId),
        data: body,
      );

      return ConversationEntity.fromJson(response.data!);
    } on DioException catch (e) {
      throw HistoryException(_extractError(e));
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _dio.delete<void>(
        ApiEndpoints.conversationDetail(conversationId),
      );
    } on DioException catch (e) {
      throw HistoryException(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String) return detail;
    }
    return 'Something went wrong. Please try again.';
  }
}

class HistoryException implements Exception {
  HistoryException(this.message);
  final String message;

  @override
  String toString() => message;
}
