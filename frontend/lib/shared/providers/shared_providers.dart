import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/core/network/api_client.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio: dio);
});
