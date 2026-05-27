import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/user/session_store.dart';

class ApiClient {
  ApiClient({Dio? dio, String? baseUrl, SessionStore? sessionStore})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(minutes: 30),
              ),
            ),
        _sessionStore = sessionStore ?? SessionStore.instance {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _sessionStore.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final SessionStore _sessionStore;

  Dio get client => _dio;
}
