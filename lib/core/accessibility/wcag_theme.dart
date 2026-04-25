import 'package:flutter/material.dart';

enum AppWorkflowState {
  idle,
  recording,
  processing,
}

extension AppWorkflowStateColors on AppWorkflowState {
  Color get bannerColor => switch (this) {
        AppWorkflowState.idle => WcagTheme.idleGrey,
        AppWorkflowState.recording => WcagTheme.recordingRed,
        AppWorkflowState.processing => WcagTheme.processingBlue,
      };

  String get semanticsLabel => switch (this) {
        AppWorkflowState.idle => 'التطبيق في وضع الانتظار',
        AppWorkflowState.recording => 'جاري التسجيل',
        AppWorkflowState.processing => 'جاري المعالجة',
      };
}

abstract final class WcagTheme {
  static const Color idleGrey = Color(0xFF5C5C5C);
  static const Color recordingRed = Color(0xFFC62828);
  static const Color brandPrimary = Color(0xFF0F6380);
  static const Color processingBlue = brandPrimary;

  static ThemeData buildTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandPrimary,
        brightness: Brightness.light,
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontSize: 18,
          height: 1.35,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
