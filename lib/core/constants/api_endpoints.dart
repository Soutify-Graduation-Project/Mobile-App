abstract final class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'SOUTIFY_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String signup = '/auth/signup';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String personalizationStatus = '/personalization/status';
  static const String personalizationPrompts = '/personalization/prompts';
  static const String enrollmentUpload = '/personalization/enroll';
  static const String personalizationFinalize = '/personalization/finalize';
  static const String transcribe = '/inference/transcribe';
}
