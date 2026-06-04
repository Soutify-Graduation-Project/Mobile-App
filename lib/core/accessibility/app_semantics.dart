import 'package:flutter/material.dart';

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
