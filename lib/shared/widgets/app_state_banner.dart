import 'package:flutter/material.dart';

import '../../core/accessibility/wcag_theme.dart';
class AppStateBanner extends StatefulWidget {
  const AppStateBanner({
    super.key,
    required this.state,
  });

  final AppWorkflowState state;

  @override
  State<AppStateBanner> createState() => _AppStateBannerState();
}

class _AppStateBannerState extends State<AppStateBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AppStateBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == AppWorkflowState.processing) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.state.bannerColor;
    final pulse = widget.state == AppWorkflowState.processing
        ? ColorTween(
            begin: baseColor.withValues(alpha: 0.65),
            end: baseColor,
          ).evaluate(
            CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
          )
        : baseColor;

    return Semantics(
      label: widget.state.semanticsLabel,
      liveRegion: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: pulse,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _labelFor(widget.state),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }

  String _labelFor(AppWorkflowState s) => switch (s) {
        AppWorkflowState.idle => 'وضع الانتظار',
        AppWorkflowState.recording => 'جاري التسجيل',
        AppWorkflowState.processing => 'جاري المعالجة',
      };
}
