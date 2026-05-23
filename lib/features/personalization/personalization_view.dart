import 'package:flutter/material.dart';
import 'package:soutify/core/accessibility/wcag_theme.dart';

import 'personalization_words_model.dart';
import 'phrase_view.dart';
import 'upload_status.dart';

class PersonalizationView extends StatelessWidget {
  const PersonalizationView({
    super.key,
    required this.pageStorageKey,
    required this.index,
    required this.phrases,
    required this.nextPhrase,
    required this.previousPhrase,
    required this.record,
    required this.play,
    required this.isRecording,
    required this.isPlaying,
    required this.isRecorded,
    required this.uploadStatus,
    required this.onPageChanged,
    this.controller,
  });

  final Key pageStorageKey;
  final int index;
  final List<PersonalizationWord> phrases;
  final VoidCallback? nextPhrase;
  final VoidCallback? previousPhrase;
  final VoidCallback? record;
  final VoidCallback? play;
  final bool isRecording;
  final bool isPlaying;
  final bool isRecorded;
  final UploadStatus uploadStatus;
  final ValueChanged<int> onPageChanged;
  final PageController? controller;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    var sideLength = width;
    if (height < width) {
      sideLength = height - 180;
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        final pageArea = PageView.builder(
          key: pageStorageKey,
          controller: controller,
          itemCount: phrases.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, pageIndex) {
            return PhraseView(phrase: phrases[pageIndex]);
          },
        );

        final firstHalf = <Widget>[
          SizedBox(
            width: orientation == Orientation.landscape
                ? (width * 2 / 3) - 100
                : sideLength,
            height: sideLength,
            child: pageArea,
          ),
        ];

        final secondHalf = <Widget>[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: 'العبارة السابقة',
                hint: 'الانتقال إلى العبارة السابقة',
                child: IconButton.outlined(
                  onPressed: previousPhrase,
                  iconSize: 48,
                  icon: const Icon(Icons.skip_previous),
                ),
              ),
              const SizedBox(width: 24),
              Semantics(
                label: 'تشغيل التسجيل',
                hint: 'تشغيل أو إيقاف تسجيل العبارة الحالية',
                child: IconButton.outlined(
                  onPressed: play,
                  iconSize: 48,
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                ),
              ),
              const SizedBox(width: 24),
              Semantics(
                label: 'العبارة التالية',
                hint: 'الانتقال إلى العبارة التالية',
                child: IconButton.outlined(
                  onPressed: nextPhrase,
                  iconSize: 48,
                  icon: const Icon(Icons.skip_next),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          MaterialButton(
            onPressed: record,
            color: isRecording
                ? WcagTheme.recordingRed
                : (isRecorded ? WcagTheme.idleGrey : WcagTheme.brandPrimary),
            textColor: Colors.white,
            disabledColor: Colors.grey,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(80)),
            ),
            padding: const EdgeInsets.fromLTRB(80, 24, 80, 24),
            child: Text(
              isRecording
                  ? 'إيقاف التسجيل'
                  : (isRecorded ? 'إعادة التسجيل' : 'تسجيل'),
              style: const TextStyle(fontSize: 24),
            ),
          ),
          if (uploadStatus == UploadStatus.started) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ];

        return orientation == Orientation.portrait
            ? Column(children: [...firstHalf, ...secondHalf])
            : Row(
                children: [
                  Column(children: firstHalf),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      child: Column(children: secondHalf),
                    ),
                  ),
                ],
              );
      },
    );
  }
}
