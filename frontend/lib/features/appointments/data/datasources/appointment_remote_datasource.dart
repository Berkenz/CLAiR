import 'package:dio/dio.dart';

import 'package:clair/core/network/api_endpoints.dart';
import 'package:clair/features/appointments/domain/entities/appointment_entity.dart';

class AppointmentRemoteDataSource {
  AppointmentRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<({String id, String label})>> getCancellationReasons() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.appointmentCancellationReasons,
      );
      final raw = response.data;
      if (raw == null) return [];
      return raw.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return (
          id: '${m['id'] ?? ''}'.trim(),
          label: '${m['label'] ?? ''}'.trim(),
        );
      }).where((r) => r.id.isNotEmpty && r.label.isNotEmpty).toList();
    } on DioException catch (e) {
      throw AppointmentException(_extractError(e));
    }
  }

  Future<void> cancelAppointment(
    String appointmentId, {
    required String reason,
    String? otherDetails,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.appointmentCancel(appointmentId),
        data: <String, dynamic>{
          'reason': reason,
          if (otherDetails != null && otherDetails.trim().isNotEmpty)
            'other_details': otherDetails.trim(),
        },
      );
    } on DioException catch (e) {
      throw AppointmentException(_extractError(e));
    }
  }

  Future<List<String>> getAppointmentTypes() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.appointmentTypes,
      );
      final raw = response.data;
      if (raw == null) return [];
      return raw
          .map((e) => '$e'.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw AppointmentException(_extractError(e));
    }
  }

  Future<List<AppointmentEntity>> getMyAppointments({String? date}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.appointments,
        queryParameters: {
          if (date != null && date.trim().isNotEmpty) 'date': date.trim(),
        },
      );

      final data = response.data;
      if (data == null || data['appointments'] == null) return [];

      final rows = data['appointments'] as List<dynamic>;
      return rows
          .map((row) => AppointmentEntity.fromJson(
                Map<String, dynamic>.from(row as Map),
              ))
          .toList();
    } on DioException catch (e) {
      throw AppointmentException(_extractError(e));
    } catch (e) {
      throw AppointmentException(
        'Something went wrong. Please try again.',
      );
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your internet connection and try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect. Please check your internet connection and try again.';
      default:
        break;
    }

    final code = e.response?.statusCode;
    if (code != null) {
      return _messageForStatus(code);
    }
    return 'Could not complete the request. Please try again.';
  }

  String _messageForStatus(int code) {
    return switch (code) {
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You don\'t have permission to do that.',
      404 => 'The requested item was not found.',
      422 => 'Some information you provided is invalid. Please check and try again.',
      _ when code >= 500 => 'A server error occurred. Please try again later.',
      _ => 'Could not complete the request. Please try again.',
    };
  }
}

class AppointmentException implements Exception {
  AppointmentException(this.message);
  final String message;

  @override
  String toString() => message;
}
