import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:clair/core/network/api_endpoints.dart';
import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';

class LawyerRemoteDataSource {
  LawyerRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<LawyerEntity>> getLawyers() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.lawyerDirectory,
      );

      final data = response.data;
      if (data == null || data['lawyers'] == null) return [];

      final list = data['lawyers'] as List;
      return list
          .map((l) => LawyerEntity.fromJson(l as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw LawyerException(_extractError(e));
    }
  }

  Future<void> bookAppointment({
    required String lawyerProfileId,
    String? appointmentDate,
    String? appointmentTime,
    String? appointmentType,
    String? description,
    String? attachedConversationId,
  }) async {
    try {
      final trimmedLawyerId = lawyerProfileId.trim();
      final trimmedAttach = attachedConversationId?.trim();
      await _dio.post<void>(
        ApiEndpoints.appointments,
        data: {
          'lawyer_profile_id': trimmedLawyerId,
          if (appointmentDate != null) 'appointment_date': appointmentDate,
          if (appointmentTime != null) 'appointment_time': appointmentTime,
          if (appointmentType != null) 'appointment_type': appointmentType,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (trimmedAttach != null && trimmedAttach.isNotEmpty)
            'attached_conversation_id': trimmedAttach,
        },
      );
    } on DioException catch (e) {
      throw LawyerException(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    final raw = e.response?.data;
    Map<String, dynamic>? map;
    if (raw is Map<String, dynamic>) {
      map = raw;
    } else if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) map = decoded;
      } catch (_) {}
    }

    if (map != null) {
      final detail = map['detail'];
      if (detail is String && detail.trim().isNotEmpty) return detail.trim();
      if (detail is List) {
        final parts = detail.map((item) {
          if (item is Map && item['msg'] != null) {
            final msg = item['msg'].toString().trim();
            final loc = item['loc'];
            if (loc is List && loc.isNotEmpty) {
              final path = loc
                  .where((e) => e != null && '$e'.isNotEmpty)
                  .map((e) => e.toString())
                  .join('.');
              if (path.isNotEmpty) return '$path: $msg';
            }
            return msg;
          }
          return item.toString();
        }).where((s) => s.isNotEmpty);
        final joined = parts.join(' ');
        if (joined.isNotEmpty) return joined;
      }
    }

    final code = e.response?.statusCode;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check that the API is running and reachable.';
      case DioExceptionType.connectionError:
        return 'Cannot reach server. On Android emulator use 10.0.2.2; on a '
            'physical phone use your PC LAN IP or '
            '--dart-define=API_BASE_URL=http://192.168.x.x:8000/api/v1 '
            '(see DEVELOPMENT.md).';
      default:
        break;
    }

    if (code != null) {
      return 'Request failed ($code). ${_messageForStatus(code)}';
    }
    return 'Could not complete the request. Please try again.';
  }

  String _messageForStatus(int code) {
    return switch (code) {
      401 => 'Sign in again — your session may have expired.',
      403 => 'You are not allowed to do this.',
      404 => 'Not found.',
      422 => 'Invalid data sent to server.',
      500 => 'Server error.',
      _ => '',
    };
  }
}

class LawyerException implements Exception {
  LawyerException(this.message);
  final String message;

  @override
  String toString() => message;
}
