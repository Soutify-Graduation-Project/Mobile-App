import 'package:path/path.dart' as p;

bool _isForbiddenOrControlRune(int r) {
  if (r <= 0x1f) return true;
  if (r > 0x7f) return false;
  const forbidden = '<>:"/\\|?*';
  return forbidden.contains(String.fromCharCode(r));
}

bool _isWhitespaceRune(int r) {
  return r == 0x9 ||
      r == 0xA ||
      r == 0xC ||
      r == 0xD ||
      r == 0x20 ||
      r == 0x85 ||
      r == 0xA0 ||
      (r >= 0x2000 && r <= 0x200a) ||
      r == 0x2028 ||
      r == 0x2029 ||
      r == 0x202f ||
      r == 0x205f ||
      r == 0x3000;
}

String _sanitizePhraseForFilename(String phrase) {
  final sb = StringBuffer();
  var pendingUnderscore = false;

  for (final r in phrase.runes) {
    if (_isForbiddenOrControlRune(r)) {
      continue;
    }
    if (_isWhitespaceRune(r)) {
      pendingUnderscore = true;
      continue;
    }
    if (pendingUnderscore) {
      if (sb.isNotEmpty) sb.write('_');
      pendingUnderscore = false;
    }
    sb.writeCharCode(r);
  }

  return sb.toString().trim();
}

String enrollmentPhraseFileStem({
  required String userId,
  required String phrase,
  required int phraseIndex,
}) {
  final cleaned = _sanitizePhraseForFilename(phrase);
  final base = cleaned.isEmpty ? 'phrase_$phraseIndex' : cleaned;
  const maxLen = 72;
  final truncated =
      base.length > maxLen ? '${base.substring(0, maxLen)}_$phraseIndex' : base;
  return '${userId}__$truncated';
}

String enrollmentClipPath({
  required String enrollmentDir,
  required String userId,
  required String phrase,
  required int phraseIndex,
  required String extension,
}) {
  final stem = enrollmentPhraseFileStem(
    userId: userId,
    phrase: phrase,
    phraseIndex: phraseIndex,
  );
  return p.join(enrollmentDir, '$stem.$extension');
}
