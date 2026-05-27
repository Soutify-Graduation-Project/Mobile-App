import 'dart:convert';

import 'package:flutter/services.dart';

/// One personalization step: Arabic word, category, and illustration asset.
class PersonalizationWord {
  const PersonalizationWord({
    required this.id,
    required this.wordArabic,
    required this.category,
    required this.imageUri,
  });

  final int id;
  final String wordArabic;
  final String category;
  final String imageUri;

  String get phrase => wordArabic;

  String get intentLabel {
    switch (category) {
      case 'حيوانات':
        return 'animals';
      case 'أكل':
        return 'food';
      case 'ألوان':
        return 'colors';
      case 'أماكن':
      case 'طبيعة':
        return 'place';
      case 'أفعال':
        return 'habit';
      case 'جسم':
        return 'people';
      case 'بيت':
      case 'لبس':
        return 'object';
      default:
        return 'unknown';
    }
  }

  String get semanticsLabel =>
      'صورة $wordArabic. اضغط الميكروفون وقل كلمة $wordArabic.';

  factory PersonalizationWord.fromJson(Map<String, dynamic> json) {
    return PersonalizationWord(
      id: json['id'] as int,
      wordArabic: json['word_arabic'] as String,
      category: json['category'] as String,
      imageUri: json['image_uri'] as String,
    );
  }
}

const _assetPath = 'assets/personalization/personalization_words.json';

Future<List<PersonalizationWord>> loadPersonalizationWords() async {
  final raw = await rootBundle.loadString(_assetPath);
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final list = decoded['personalization_words'] as List<dynamic>;
  return list
      .map((word) => PersonalizationWord.fromJson(word as Map<String, dynamic>))
      .toList();
}
