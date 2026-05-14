import 'package:dio/dio.dart';

import 'package:clair/core/network/api_endpoints.dart';
import 'package:clair/features/appointments/domain/entities/appointment_entity.dart';

class AppointmentRemoteDataSource {
  AppointmentRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

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
        'Server returned data the app could not read. ($e)',
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
    final code = e.response?.statusCode;
    if (code != null) {
      return 'Request failed ($code).';
    }
    return 'Could not complete the request. Please try again.';
  }
}

class AppointmentException implements Exception {
  AppointmentException(this.message);
  final String message;

  @override
  String toString() => message;
}
