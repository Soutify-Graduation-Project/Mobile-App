import 'package:flutter/material.dart';
import '../../core/accessibility/app_semantics.dart';

/// Single-tap primary control; large target for tremor / motor accessibility.
class LargePrimaryButton extends StatelessWidget {
  LargePrimaryButton({
    super.key,
    this.label,
    this.icon,
    required this.onPressed,
    this.semanticLabel,
  }) : assert(
          (label != null && label.isNotEmpty) || icon != null,
          'Provide a non-empty label and/or an icon.',
        );

  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final Widget childContent;
    if (icon != null &&
        (label == null || label!.isEmpty)) {
      childContent = Icon(icon, size: 40, color: onPrimary);
    } else if (icon != null && label != null && label!.isNotEmpty) {
      childContent = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: onPrimary),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label!,
              textAlign: TextAlign.center,
              style: TextStyle(color: onPrimary),
            ),
          ),
        ],
      );
    } else {
      childContent = Text(label!, textAlign: TextAlign.center);
    }

    final child = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      child: childContent,
    );

    final mergedLabel = semanticLabel ??
        (label != null && label!.isNotEmpty ? label! : 'زر');

    return AppSemantics.merge(
      label: mergedLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSemantics.minTapTarget,
        ),
        child: child,
      ),
    );
  }
}
