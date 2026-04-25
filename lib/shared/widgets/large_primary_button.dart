import 'package:flutter/material.dart';

import '../../core/accessibility/app_semantics.dart';

/// Single-tap primary control; large target for tremor / motor accessibility.
class LargePrimaryButton extends StatelessWidget {
  const LargePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final child = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );

    return AppSemantics.merge(
      label: semanticLabel ?? label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSemantics.minTapTarget,
        ),
        child: child,
      ),
    );
  }
}
