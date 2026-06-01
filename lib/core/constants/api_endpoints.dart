import 'api_base_url.dart';

abstract final class ApiEndpoints {
  static final String baseUrl = resolveApiBaseUrl();

  static const String signup = '/auth/signup';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String personalizationStatus = '/personalization/status';
  static const String personalizationPrompts = '/personalization/prompts';
  static const String enrollmentUpload = '/personalization/enroll';
  static const String personalizationFinalize = '/personalization/finalize';
  static const String transcribe = '/inference/transcribe';
}
