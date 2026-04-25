import 'dart:io';

class EnrollmentClip {
  const EnrollmentClip({
    required this.index,
    required this.phrase,
    required this.file,
  });

  final int index;
  final String phrase;
  final File file;
}