import 'package:flutter/material.dart';

import 'personalization_controller.dart';

/// Training tab: swipe through phrases, record, play back, and upload each clip.
class PersonalizationScreen extends StatelessWidget {
  const PersonalizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PersonalizationController();
  }
}
