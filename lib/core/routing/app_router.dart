import 'package:flutter/material.dart';

import '../../features/personalization/personalization_screen.dart';
import '../../features/live_asr/live_asr_screen.dart';
import '../../features/auth/auth_gate.dart';

/// Named routes for the scaffold. Swap for [go_router] or similar later.
abstract final class AppRouter {
  static const String home = '/';
  static const String enrollment = '/enrollment';
  static const String liveAsr = '/live-asr';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case enrollment:
        return MaterialPageRoute<void>(
          builder: (_) => const PersonalizationScreen(),
          settings: settings,
        );
      case liveAsr:
        return MaterialPageRoute<void>(
          builder: (_) => const LiveAsrScreen(),
          settings: settings,
        );
      case home:
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const AuthGate(),
          settings: settings,
        );
    }
  }
}
