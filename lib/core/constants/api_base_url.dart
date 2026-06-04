import 'dart:io' show Platform;

// override using `flutter run --dart-define=SOUTIFY_API_BASE_URL=http://192.168.1.10:8000`
String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('SOUTIFY_API_BASE_URL');
  if (fromEnv.isNotEmpty) {
    return fromEnv;
  }
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://127.0.0.1:8000';
}
