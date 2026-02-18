import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:clair/core/constants/app_constants.dart';

class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  final Dio _dio;

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final token = await user.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {
        // Token refresh failed, continue without auth
      }
    }
    handler.next(options);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle specific error codes or transform errors as needed
    handler.next(err);
  }
}
