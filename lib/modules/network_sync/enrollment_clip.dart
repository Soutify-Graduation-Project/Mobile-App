import 'dart:io';

class EnrollmentClip {
  const EnrollmentClip({
    required this.index,
    required this.phrase,
    required this.intent,
    required this.category,
    required this.file,
  });

  final int index;
  final String phrase;
  final String intent;
  final String category;
  final File file;
}
