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
    required this.isFinalizing,
    required this.enrollmentCount,
    required this.requiredCount,
    required this.isPersonalized,
    required this.hasPendingPersonalizationUpdate,
    required this.showFinalizeAction,
    required this.onPageChanged,
    required this.hasRecordingFor,
    this.finalizePersonalization,
    this.controller,
  });

  final Key pageStorageKey;
  final int index;
  final List<PersonalizationWord> phrases;
  final Future<bool> Function(int index) hasRecordingFor;
  final VoidCallback? nextPhrase;
  final VoidCallback? previousPhrase;
  final VoidCallback? record;
  final VoidCallback? play;
  final bool isRecording;
  final bool isPlaying;
  final bool isRecorded;
  final UploadStatus uploadStatus;
  final bool isFinalizing;
  final int enrollmentCount;
  final int requiredCount;
  final bool isPersonalized;
  final bool hasPendingPersonalizationUpdate;
  final bool showFinalizeAction;
  final ValueChanged<int> onPageChanged;
  final PageController? controller;
  final VoidCallback? finalizePersonalization;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    var sideLength = width;
    if (height < width) {
      sideLength = height - 180;
    }

    final body = OrientationBuilder(
      builder: (context, orientation) {
        final pageArea = PageView.builder(
          key: pageStorageKey,
          controller: controller,
          itemCount: phrases.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, pageIndex) {
            return PhraseView(
              phrase: phrases[pageIndex],
              hasRecording: () => hasRecordingFor(pageIndex),
            );
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
          _PersonalizationStatus(
            enrollmentCount: enrollmentCount,
            requiredCount: requiredCount,
            isPersonalized: isPersonalized,
            hasPendingPersonalizationUpdate: hasPendingPersonalizationUpdate,
          ),
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
            if (isFinalizing) ...[
              const SizedBox(height: 8),
              const Text('Personalization is running on the server...'),
            ],
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

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: showFinalizeAction ? 92 : 0),
          child: body,
        ),
        if (showFinalizeAction)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _FinalizePersonalizationBar(
              isPersonalized: isPersonalized,
              isFinalizing: isFinalizing,
              onPressed: finalizePersonalization,
            ),
          ),
      ],
    );
  }
}

class _FinalizePersonalizationBar extends StatelessWidget {
  const _FinalizePersonalizationBar({
    required this.isPersonalized,
    required this.isFinalizing,
    required this.onPressed,
  });

  final bool isPersonalized;
  final bool isFinalizing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (isFinalizing) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton.icon(
                onPressed: isFinalizing ? null : onPressed,
                icon: Icon(isPersonalized ? Icons.sync : Icons.auto_fix_high),
                label: Text(
                  isFinalizing
                      ? 'Personalization is running...'
                      : isPersonalized
                          ? 'Update Personalization'
                          : 'Start Personalization',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalizationStatus extends StatelessWidget {
  const _PersonalizationStatus({
    required this.enrollmentCount,
    required this.requiredCount,
    required this.isPersonalized,
    required this.hasPendingPersonalizationUpdate,
  });

  final int enrollmentCount;
  final int requiredCount;
  final bool isPersonalized;
  final bool hasPendingPersonalizationUpdate;

  @override
  Widget build(BuildContext context) {
    final statusText = isPersonalized
        ? (hasPendingPersonalizationUpdate
            ? 'Personalized. New recording pending update.'
            : 'Personalized. Free Speech is ready.')
        : 'Enrollment: $enrollmentCount / $requiredCount';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPersonalized ? Icons.verified : Icons.info_outline,
            color: isPersonalized
                ? WcagTheme.brandPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              statusText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
