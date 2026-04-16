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

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String) return detail;
    }
    return 'Could not load lawyers. Please try again.';
  }
}

class LawyerException implements Exception {
  LawyerException(this.message);
  final String message;

  @override
  String toString() => message;
}
