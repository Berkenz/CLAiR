import 'dart:io';

import 'package:dio/dio.dart';

import 'package:clair/core/constants/app_constants.dart';
import 'package:clair/core/network/api_endpoints.dart';
import 'package:clair/features/chat/domain/entities/chat_message_entity.dart';
import 'package:clair/features/chat/domain/entities/chat_response_entity.dart';
import 'package:clair/features/chat/domain/entities/rag_source_entity.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<ChatResponseEntity> sendMessage({
    required String message,
    required List<ChatMessageEntity> history,
    String? conversationId,
    double? userLat,
    double? userLng,
    String locale = 'en',
  }) async {
    try {
      final data = <String, dynamic>{
        'message': message,
        'history': history.map((m) => m.toHistoryJson()).toList(),
        'locale': locale,
      };
      if (conversationId != null) {
        data['conversation_id'] = conversationId;
      }
      if (userLat != null && userLng != null) {
        data['user_lat'] = userLat;
        data['user_lng'] = userLng;
      }

      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.chatSend,
        data: data,
        // LLM responses can take well over 30 s — give the server 3 minutes.
        options: Options(
          receiveTimeout: const Duration(minutes: 3),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      final body = response.data;
      if (body == null) throw ChatException('Empty response from server');

      // Support both 'reply' and 'response' keys from the backend.
      final rawReply = body['reply'] ?? body['response'];
      if (rawReply == null) throw ChatException('No reply in server response');

      final replyText = rawReply is String
          ? rawReply
          : (rawReply is List ? rawReply.join('\n') : rawReply.toString());

      // conversation_id may be absent on some backends; fall back gracefully.
      final convId = (body['conversation_id'] as String?)?.trim() ?? '';

      final rawLawyers =
          body['suggested_lawyers'] as List<dynamic>? ?? [];
      final suggestedLawyers = <LawyerEntity>[];
      for (final e in rawLawyers) {
        if (e is! Map) continue;
        suggestedLawyers.add(
          LawyerEntity.fromJson(Map<String, dynamic>.from(e)),
        );
      }

      final bool? ragEnabled = body.containsKey('rag_enabled')
          ? body['rag_enabled'] == true
          : null;
      final rawRag = body['rag_sources'] as List<dynamic>? ?? [];
      final ragSources = rawRag
          .whereType<Map<String, dynamic>>()
          .map(RagSourceEntity.fromJson)
          .toList();

      return ChatResponseEntity(
        reply: replyText,
        conversationId: convId,
        conversationTitle: (body['conversation_title'] as String?)?.trim() ?? '',
        userMessageId: body['user_message_id']?.toString(),
        assistantMessageId: body['assistant_message_id']?.toString(),
        suggestedLawyers: suggestedLawyers,
        ragEnabled: ragEnabled,
        ragSources: ragSources,
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
      final targetUrl = '${AppConstants.baseUrl}${ApiEndpoints.chatSend}';
      final cause = e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout
          ? 'Request timed out.'
          : 'Network unreachable.';
      throw ChatException(
        'Could not reach CLAiR at $targetUrl. $cause Please check your connection or API base URL.',
      );
    }
  }

  Future<String> extractFileText(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.chatExtractFile,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final body = response.data;
      if (body == null || body['text'] == null) {
        throw ChatException('No text extracted from file.');
      }
      return body['text'] as String;
    } on DioException catch (e) {
      final detail = e.response?.data;
      if (detail is Map<String, dynamic> && detail['detail'] != null) {
        throw ChatException(detail['detail'].toString());
      }
      throw ChatException('Failed to read file. Please try again.');
    }
  }

  Future<void> reportConversation({
    required String category,
    required String explanation,
    required List<ChatMessageEntity> messages,
    String? conversationId,
    String? reportedMessageExcerpt,
  }) async {
    final data = <String, dynamic>{
      'category': category,
      'explanation': explanation,
      'messages': messages
          .map((m) => {'role': m.role, 'text': m.text})
          .toList(),
    };
    if (conversationId != null) data['conversation_id'] = conversationId;
    if (reportedMessageExcerpt != null) {
      data['reported_message_excerpt'] = reportedMessageExcerpt;
    }

    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.reportConversation,
        data: data,
      );
    } on DioException catch (e) {
      final detail = e.response?.data;
      if (detail is Map<String, dynamic> && detail['detail'] != null) {
        throw ChatException(detail['detail'].toString());
      }
      throw ChatException('Failed to submit report. Please try again.');
    }
  }

  Future<void> reportUser({
    String? reportedUserId,
    String? reportedLawyerProfileId,
    required String category,
    required String explanation,
  }) async {
    final data = <String, dynamic>{
      'category': category,
      'explanation': explanation,
    };
    if (reportedUserId != null) data['reported_user_id'] = reportedUserId;
    if (reportedLawyerProfileId != null) {
      data['reported_lawyer_profile_id'] = reportedLawyerProfileId;
    }

    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.reportUser,
        data: data,
      );
    } on DioException catch (e) {
      final detail = e.response?.data;
      if (detail is Map<String, dynamic> && detail['detail'] != null) {
        throw ChatException(detail['detail'].toString());
      }
      throw ChatException('Failed to submit report. Please try again.');
    }
  }
}

class ChatException implements Exception {
  ChatException(this.message);
  final String message;

  @override
  String toString() => message;
}
