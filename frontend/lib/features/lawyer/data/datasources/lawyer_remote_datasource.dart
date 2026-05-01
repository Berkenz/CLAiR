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
  }) async {
    try {
      await _dio.post<void>(
        ApiEndpoints.appointments,
        data: {
          'lawyer_profile_id': lawyerProfileId,
          if (appointmentDate != null) 'appointment_date': appointmentDate,
          if (appointmentTime != null) 'appointment_time': appointmentTime,
          if (appointmentType != null) 'appointment_type': appointmentType,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
    } on DioException catch (e) {
      throw LawyerException(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String) return detail;
    }
    return 'Could not complete the request. Please try again.';
  }
}

class LawyerException implements Exception {
  LawyerException(this.message);
  final String message;

  @override
  String toString() => message;
}
