import 'package:flutter/material.dart';

import 'personalization_words_model.dart';

class PhraseView extends StatelessWidget {
  const PhraseView({super.key, required this.phrase});

  final PersonalizationWord phrase;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            phrase.phrase,
            style: Theme.of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Semantics(
              label: phrase.semanticsLabel,
              image: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  phrase.imageUri,
                  fit: BoxFit.fill,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
