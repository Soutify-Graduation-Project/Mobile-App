import 'package:flutter/material.dart';
import 'package:soutify/core/accessibility/wcag_theme.dart';

import 'personalization_words_model.dart';
import 'phrase_view.dart';
import 'upload_status.dart';

const _compactIconButtonStyle = ButtonStyle(
  padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
  minimumSize: WidgetStatePropertyAll(Size(40, 40)),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
);

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

  bool get _isUploadingPhrase =>
      uploadStatus == UploadStatus.started && !isFinalizing;

  @override
  Widget build(BuildContext context) {
    final body = LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
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

            final controls = <Widget>[
              _PersonalizationStatus(
                enrollmentCount: enrollmentCount,
                requiredCount: requiredCount,
                isPersonalized: isPersonalized,
                hasPendingPersonalizationUpdate: hasPendingPersonalizationUpdate,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Semantics(
                    label: 'العبارة السابقة',
                    hint: 'الانتقال إلى العبارة السابقة',
                    child: IconButton.outlined(
                      onPressed: previousPhrase,
                      iconSize: 32,
                      style: _compactIconButtonStyle,
                      icon: const Icon(Icons.skip_previous),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    label: 'تشغيل التسجيل',
                    hint: 'تشغيل أو إيقاف تسجيل العبارة الحالية',
                    child: IconButton.outlined(
                      onPressed: play,
                      iconSize: 32,
                      style: _compactIconButtonStyle,
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    label: 'العبارة التالية',
                    hint: 'الانتقال إلى العبارة التالية',
                    child: IconButton.outlined(
                      onPressed: nextPhrase,
                      iconSize: 32,
                      style: _compactIconButtonStyle,
                      icon: const Icon(Icons.skip_next),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              MaterialButton(
                onPressed: _isUploadingPhrase ? null : record,
                color: isRecording
                    ? WcagTheme.recordingRed
                    : (isRecorded ? WcagTheme.idleGrey : WcagTheme.brandPrimary),
                textColor: Colors.white,
                disabledColor: WcagTheme.brandPrimary.withValues(alpha: 0.7),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(80)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                child: _isUploadingPhrase
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isRecording
                            ? 'إيقاف التسجيل'
                            : (isRecorded ? 'إعادة التسجيل' : 'تسجيل'),
                        style: const TextStyle(fontSize: 18),
                      ),
              ),
            ];

            final controlsColumn = Column(
              mainAxisSize: MainAxisSize.min,
              children: controls,
            );

            if (orientation == Orientation.portrait) {
              return Column(
                children: [
                  Expanded(flex: 5, child: pageArea),
                  Flexible(
                    flex: 2,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: controlsColumn,
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: pageArea,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: controlsColumn,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: showFinalizeAction ? 104 : 0),
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
        if (isFinalizing)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Running personalization…',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Waiting for the server. This may take a minute.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
        child: isFinalizing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Personalization is running…',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              )
            : FilledButton.icon(
                onPressed: onPressed,
                icon: Icon(isPersonalized ? Icons.sync : Icons.auto_fix_high),
                label: Text(
                  isPersonalized
                      ? 'Update Personalization'
                      : 'Start Personalization',
                ),
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
