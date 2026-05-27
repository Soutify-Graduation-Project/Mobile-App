import 'package:flutter/material.dart';

import 'personalization_controller.dart';

/// Training tab: swipe through phrases, record, play back, and upload each clip.
class PersonalizationScreen extends StatelessWidget {
  const PersonalizationScreen({
    super.key,
    this.embedded = false,
    this.initialStatus = const {},
    this.onStatusChanged,
    this.onPersonalizationReady,
  });

  final bool embedded;
  final Map<String, dynamic> initialStatus;
  final ValueChanged<Map<String, dynamic>>? onStatusChanged;
  final ValueChanged<Map<String, dynamic>>? onPersonalizationReady;

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: PersonalizationController(
        initialStatus: initialStatus,
        onStatusChanged: onStatusChanged,
        onPersonalizationReady: onPersonalizationReady,
      ),
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      body: content,
    );
  }
}
