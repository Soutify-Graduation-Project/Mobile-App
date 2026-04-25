import 'package:flutter/material.dart';

/// Minimum touch target per WCAG 2.1 AA (48 logical pixels).
abstract final class AppSemantics {
  static const double minTapTarget = 48;

  static Widget merge({
    required String label,
    required Widget child,
    String? hint,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      child: child,
    );
  }
}
