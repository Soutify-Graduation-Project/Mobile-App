import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/user/user_id_store.dart';
import '../../modules/network_sync/enrollment_clip.dart';
import '../../modules/network_sync/network_sync_manager.dart';
import '../../modules/speech_recording/speech_recording_service.dart';
import '../../shared/widgets/large_primary_button.dart';
import 'enrollment_filename.dart';
import 'enrollment_prompts.dart';

/// One phrase at a time: record, re-record, submit; then upload all clips to the server.
class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  final SpeechRecordingService _recorder = SpeechRecordingService();
  final NetworkSyncManager _network = NetworkSyncManager();

  String? _userId;
  Directory? _enrollmentRoot;
  bool _loadingUser = true;

  int _phraseIndex = 0;
  bool _isRecording = false;
  bool _hasDraft = false;
  bool _uploading = false;
  bool _uploadFailed = false;

  final List<EnrollmentClip> _committed = [];

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final userId = await UserIdStore.instance.getOrCreateUserId();
      final docs = await getApplicationDocumentsDirectory();
      final root = Directory(p.join(docs.path, 'soutify_enrollment'));
      if (!await root.exists()) await root.create(recursive: true);
      if (!mounted) return;
      setState(() {
        _userId = userId;
        _enrollmentRoot = root;
        _loadingUser = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التهيئة: $e')),
        );
        setState(() => _loadingUser = false);
      }
    }
  }

  EnrollmentVisualPrompt get _currentPrompt =>
      enrollmentVisualPrompts[_phraseIndex];

  String get _currentPhrase => _currentPrompt.phrase;

  String _draftPath() {
    final uid = _userId!;
    final dir = _enrollmentRoot!.path;
    return p.join(dir, '${uid}_draft_p$_phraseIndex.m4a');
  }

  Future<bool> _ensureMic() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }
    if (status.isPermanentlyDenied && mounted) {
      await openAppSettings();
    }
    return status.isGranted;
  }

  Future<void> _startRecording() async {
    if (_userId == null || _loadingUser) return;
    if (!(await _ensureMic())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يلزم السماح باستخدام الميكروفون')),
        );
      }
      return;
    }
    final path = _draftPath();
    final file = File(path);
    if (await file.exists()) await file.delete();
    try {
      await _recorder.start(path: path);
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _hasDraft = false;
        _uploadFailed = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر بدء التسجيل: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stop();
      final file = File(_draftPath());
      final exists = await file.exists();
      final len = exists ? await file.length() : 0;
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _hasDraft = exists && len > 0;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إيقاف التسجيل: $e')),
        );
      }
    }
  }

  Future<void> _redoRecording() async {
    if (_isRecording) {
      try {
        await _recorder.stop();
      } catch (_) {}
    }
    final file = File(_draftPath());
    if (await file.exists()) await file.delete();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _hasDraft = false;
    });
  }

  Future<void> _commitAndAdvance() async {
    if (!_hasDraft || _userId == null) return;
    final draft = File(_draftPath());
    if (!await draft.exists()) return;

    final finalPath = enrollmentClipPath(
      enrollmentDir: _enrollmentRoot!.path,
      userId: _userId!,
      phrase: _currentPhrase,
      phraseIndex: _phraseIndex,
      extension: 'm4a',
    );
    final out = File(finalPath);
    if (await out.exists()) await out.delete();
    try {
      await draft.rename(out.path);
    } on FileSystemException {
      await draft.copy(out.path);
      await draft.delete();
    }

    _committed.add(
      EnrollmentClip(
        index: _phraseIndex,
        phrase: _currentPhrase,
        file: out,
      ),
    );

    final isLast = _phraseIndex >= enrollmentVisualPrompts.length - 1;
    if (isLast) {
      await _uploadAll();
      return;
    }

    if (!mounted) return;
    setState(() {
      _phraseIndex += 1;
      _hasDraft = false;
      _isRecording = false;
    });
  }

  Future<void> _uploadAll() async {
    if (_committed.isEmpty || _userId == null) return;
    setState(() {
      _uploading = true;
      _uploadFailed = false;
    });
    try {
      await _network.uploadEnrollment(
        userId: _userId!,
        clips: List<EnrollmentClip>.from(_committed),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال التسجيلات للخادم بنجاح')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _uploadFailed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإرسال: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser || _userId == null || _enrollmentRoot == null) {
      return Scaffold(
        appBar: AppBar(
          title: Semantics(
            label: 'التخصيص',
            child: const Icon(Icons.record_voice_over_outlined, size: 26),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final total = enrollmentVisualPrompts.length;
    final lastPhrase = _phraseIndex >= total - 1;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'التخصيص',
          child: const Icon(Icons.record_voice_over_outlined, size: 26),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _uploading ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExcludeSemantics(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(total, (i) {
                        final done = i < _phraseIndex;
                        final current = i == _phraseIndex;
                        final scheme = Theme.of(context).colorScheme;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.circle,
                            size: current ? 18 : 12,
                            color: done || current
                                ? scheme.primary
                                : scheme.outlineVariant,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPrompt.phrase,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Semantics(
                              label: _currentPrompt.semanticsLabel,
                              image: true,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  _currentPrompt.imageAsset,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isRecording)
                    LargePrimaryButton(
                      icon: Icons.stop_circle_outlined,
                      semanticLabel: 'إيقاف التسجيل',
                      onPressed: _uploading ? null : _stopRecording,
                    )
                  else
                    LargePrimaryButton(
                      icon: Icons.mic,
                      semanticLabel: 'بدء التسجيل',
                      onPressed: (_uploading || _hasDraft) ? null : _startRecording,
                    ),
                  const SizedBox(height: 12),
                  LargePrimaryButton(
                    icon: Icons.replay,
                    semanticLabel: 'إعادة التسجيل',
                    onPressed: (_uploading || (!_isRecording && !_hasDraft))
                        ? null
                        : _redoRecording,
                  ),
                  const SizedBox(height: 12),
                  LargePrimaryButton(
                    icon: lastPhrase ? Icons.cloud_upload_outlined : Icons.arrow_forward,
                    semanticLabel:
                        lastPhrase ? 'إرسال كل التسجيلات وإنهاء' : 'حفظ والانتقال للصورة التالية',
                    onPressed:
                        (_uploading || !_hasDraft || _isRecording)
                            ? null
                            : _commitAndAdvance,
                  ),
                  if (_uploadFailed) ...[
                    const SizedBox(height: 12),
                    LargePrimaryButton(
                      icon: Icons.refresh,
                      semanticLabel: 'إعادة إرسال للخادم',
                      onPressed: _uploading ? null : _uploadAll,
                    ),
                  ],
                ],
              ),
            ),
            if (_uploading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
