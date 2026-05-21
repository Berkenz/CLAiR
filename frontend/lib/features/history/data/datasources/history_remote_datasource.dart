import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:clair/core/network/api_endpoints.dart';
import 'package:clair/features/chat/data/mappers/chat_message_mapper.dart';
import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/history/domain/entities/conversation_entity.dart';

class HistoryRemoteDataSource {
  HistoryRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<ConversationEntity>> getConversations({String? query}) async {
    try {
      final q = query?.trim();
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.conversations,
        queryParameters:
            q != null && q.isNotEmpty ? <String, dynamic>{'q': q} : null,
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
      final messages = list
          .map((m) => chatMessageFromApiMap(m as Map<String, dynamic>))
          .toList();
      return orderChatMessages(messages);
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

  /// Server-side Gemini summary for lawyer appointment booking description.
  Future<String> summarizeConversationForAppointment(String conversationId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.conversationAppointmentSummary(conversationId),
      );
      final raw = response.data?['summary'];
      if (raw is! String) return '';
      return raw.trim();
    } on DioException catch (e) {
      throw HistoryException(_extractError(e));
    }
  }

  Future<Uint8List> downloadPdf(String conversationId) async {
    try {
      final response = await _dio.get<List<int>>(
        ApiEndpoints.conversationPdf(conversationId),
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data!);
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
