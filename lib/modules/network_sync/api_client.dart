import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';

/// Thin Dio wrapper for discrete API calls.
class ApiClient {
  ApiClient({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? ApiEndpoints.baseUrlPlaceholder,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 60),
              ),
            );

  final Dio _dio;

  Dio get client => _dio;
}
