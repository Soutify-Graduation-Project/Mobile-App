import 'package:flutter/material.dart';

import 'personalization_words_model.dart';

class PhraseView extends StatelessWidget {
  const PhraseView({
    super.key,
    required this.phrase,
    required this.hasRecording,
  });

  final PersonalizationWord phrase;
  final Future<bool> Function() hasRecording;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: hasRecording(),
      builder: (context, snapshot) {
        final isRecordingAvailable = snapshot.data == true;

        return OrientationBuilder(
          builder: (context, orientation) {
            final scheme = ColorScheme.of(context);

            return Card(
              margin: EdgeInsets.symmetric(
                vertical: orientation == Orientation.portrait ? 48 : 0,
                horizontal: 6,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(48)),
              ),
              color: isRecordingAvailable
                  ? scheme.onTertiary
                  : scheme.onSecondary,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${phrase.id}',
                            style: TextStyle(color: scheme.outline),
                          ),
                        ),
                        Container(
                          decoration: ShapeDecoration(
                            shape: const CircleBorder(),
                            color: isRecordingAvailable
                                ? Colors.blue
                                : Colors.transparent,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.check_rounded,
                            color: isRecordingAvailable
                                ? Colors.white
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      phrase.phrase,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: isRecordingAvailable
                                ? scheme.tertiary
                                : scheme.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Semantics(
                        label: phrase.semanticsLabel,
                        image: true,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            phrase.imageUri,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
