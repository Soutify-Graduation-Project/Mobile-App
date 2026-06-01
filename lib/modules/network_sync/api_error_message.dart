import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';

String formatApiError(Object error) {
  if (error is! DioException) {
    return error.toString();
  }

  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Cannot reach the API at ${ApiEndpoints.baseUrl}. '
          'Start the backend on port 8000. On a physical device, use your PC\'s '
          'LAN IP (not 0.0.0.0): '
          'flutter run --dart-define=SOUTIFY_API_BASE_URL=http://<your-ip>:8000';
    default:
      break;
  }

  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final detail = data['detail'];
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }
    if (detail is List) {
      final messages = <String>[];
      for (final item in detail) {
        if (item is Map && item['msg'] is String) {
          messages.add(item['msg'] as String);
        }
      }
      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }
  }

  final status = error.response?.statusCode;
  if (status != null) {
    return 'Request failed (HTTP $status).';
  }
  return error.message ?? error.toString();
}
