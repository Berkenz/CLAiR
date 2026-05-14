import 'package:dio/dio.dart';

import 'package:clair/features/appointments/domain/entities/direct_message_entity.dart';

class DirectMessageDataSource {
  DirectMessageDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<({List<DirectMessageEntity> messages, int unreadCount})> listMessages(
    String appointmentId, {
    DateTime? since,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/appointments/$appointmentId/messages',
        queryParameters: {
          if (since != null) 'since': since.toUtc().toIso8601String(),
        },
      );
      final data = response.data ?? {};
      final rows = (data['messages'] as List<dynamic>? ?? [])
          .map((e) => DirectMessageEntity.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return (
        messages: rows,
        unreadCount: data['unread_count'] as int? ?? 0,
      );
    } on DioException catch (e) {
      throw DirectMessageException(_extractError(e));
    }
  }

  Future<DirectMessageEntity> sendMessage(
    String appointmentId,
    String content,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/appointments/$appointmentId/messages',
        data: {'content': content},
      );
      return DirectMessageEntity.fromJson(
        Map<String, dynamic>.from(response.data!),
      );
    } on DioException catch (e) {
      throw DirectMessageException(_extractError(e));
    }
  }

  Future<DirectMessageEntity> uploadAttachment(
    String appointmentId, {
    required String filePath,
    required String fileName,
    required String mimeType,
    String? caption,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        if (caption != null && caption.trim().isNotEmpty) 'caption': caption.trim(),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/appointments/$appointmentId/messages/upload',
        data: formData,
      );
      return DirectMessageEntity.fromJson(
        Map<String, dynamic>.from(response.data!),
      );
    } on DioException catch (e) {
      throw DirectMessageException(_extractError(e));
    }
  }

  Future<void> markRead(String appointmentId) async {
    try {
      await _dio.patch<void>('/appointments/$appointmentId/messages/read');
    } on DioException {
      // Best-effort — don't throw for read receipts
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) return detail.trim();
    }
    final code = e.response?.statusCode;
    if (code != null) return 'Request failed ($code).';
    return 'Could not complete the request. Please try again.';
  }
}

class DirectMessageException implements Exception {
  DirectMessageException(this.message);
  final String message;

  @override
  String toString() => message;
}
