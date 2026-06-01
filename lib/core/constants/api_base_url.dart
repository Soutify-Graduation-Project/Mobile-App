import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Local API base URL for the running app.
///
/// The server may bind to `0.0.0.0:8000`; clients must use a reachable host
/// (`127.0.0.1`, `10.0.2.2` on Android emulator, or your PC's LAN IP on a
/// physical phone).
///
/// Override:
/// `flutter run --dart-define=SOUTIFY_API_BASE_URL=http://192.168.1.10:8000`
String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('SOUTIFY_API_BASE_URL');
  if (fromEnv.isNotEmpty) {
    return fromEnv;
  }
  if (kIsWeb) {
    return 'http://127.0.0.1:8000';
  }
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://127.0.0.1:8000';
}
