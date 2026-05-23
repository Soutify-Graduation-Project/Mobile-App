import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/user/user_id_store.dart';
import '../../modules/network_sync/enrollment_clip.dart';
import '../../modules/network_sync/network_sync_manager.dart';
import '../../modules/sound_playback/sound_playback_service.dart';
import '../../modules/speech_recording/speech_recording_service.dart';
import 'personalization_filename.dart';
import 'personalization_view.dart';
import 'personalization_words_model.dart';
import 'upload_status.dart';

class PersonalizationController extends StatefulWidget {
  const PersonalizationController({super.key});

  @override
  State<PersonalizationController> createState() =>
      _PersonalizationControllerState();
}

class _PersonalizationControllerState extends State<PersonalizationController> {
  final SpeechRecordingService _recorder = SpeechRecordingService();
  final SoundPlaybackService _player = SoundPlaybackService();
  final NetworkSyncManager _network = NetworkSyncManager();

  final Key _pageStorageKey = GlobalKey();
  final PageController _pageController =
      PageController(initialPage: 0, viewportFraction: 0.8);

  List<PersonalizationWord> _prompts = [];
  String? _userId;
  Directory? _enrollmentRoot;
  bool _loading = true;
  int _currentIndex = 0;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isRecorded = false;
  UploadStatus _uploadStatus = UploadStatus.notStarted;

  StreamSubscription<PlayerState>? _playerSub;

  @override
  void initState() {
    super.initState();
    _playerSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      final playing = state.playing;
      if (playing != _isPlaying) {
        setState(() => _isPlaying = playing);
      }
    });
    _init();
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    unawaited(_recorder.dispose());
    unawaited(_player.dispose());
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final userId = await UserIdStore.instance.getOrCreateUserId();
      final docs = await getApplicationDocumentsDirectory();
      final root = Directory(p.join(docs.path, 'soutify_enrollment'));
      if (!await root.exists()) await root.create(recursive: true);
      final prompts = await loadPersonalizationWords();
      if (!mounted) return;

      setState(() {
        _userId = userId;
        _enrollmentRoot = root;
        _prompts = prompts;
        _loading = false;
      });

      final lastRecorded = await _lastRecordedIndex();
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(lastRecorded);
      await _refreshRecordedState(lastRecorded);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التهيئة: $e')),
        );
        setState(() => _loading = false);
      }
    }
  }

  PersonalizationWord get _currentPrompt => _prompts[_currentIndex];

  String _clipPath(int index) {
    final prompt = _prompts[index];
    return enrollmentClipPath(
      enrollmentDir: _enrollmentRoot!.path,
      userId: _userId!,
      phrase: prompt.phrase,
      phraseIndex: index,
      extension: 'm4a',
    );
  }

  Future<bool> _hasRecording(int index) async {
    final file = File(_clipPath(index));
    if (!await file.exists()) return false;
    return await file.length() > 0;
  }

  Future<int> _lastRecordedIndex() async {
    for (var i = _prompts.length - 1; i >= 0; i--) {
      if (await _hasRecording(i)) return i;
    }
    return 0;
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

  Future<void> _refreshRecordedState(int index) async {
    final recorded = await _hasRecording(index);
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
      _isRecorded = recorded;
    });
  }

  void _jumpToPhrase(int index) {
    unawaited(_refreshRecordedState(index));
    setState(() => _uploadStatus = UploadStatus.notStarted);
  }

  Future<void> _previousPhrase() async {
    if (_currentIndex == 0) return;
    await _player.stop();
    final nextIndex = _currentIndex - 1;
    setState(() => _uploadStatus = UploadStatus.notStarted);
    await _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
    );
    await _refreshRecordedState(nextIndex);
  }

  Future<void> _nextPhrase() async {
    if (_currentIndex >= _prompts.length - 1) return;
    await _player.stop();
    final nextIndex = _currentIndex + 1;
    setState(() => _uploadStatus = UploadStatus.notStarted);
    await _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
    );
    await _refreshRecordedState(nextIndex);
  }

  Future<void> _toggleRecording() async {
    if (_isPlaying) return;

    if (!_isRecording) {
      if (_userId == null || _loading) return;
      if (!(await _ensureMic())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يلزم السماح باستخدام الميكروفون')),
          );
        }
        return;
      }

      final path = _clipPath(_currentIndex);
      final file = File(path);
      if (await file.exists()) await file.delete();

      try {
        await _recorder.start(path: path);
        if (!mounted) return;
        setState(() {
          _isRecording = true;
          _isRecorded = false;
          _uploadStatus = UploadStatus.notStarted;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر بدء التسجيل: $e')),
          );
        }
      }
      return;
    }

    try {
      await _recorder.stop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إيقاف التسجيل: $e')),
        );
      }
    }

    if (!mounted) return;
    setState(() => _isRecording = false);

    if (!(await _hasRecording(_currentIndex))) return;
    setState(() => _isRecorded = true);
    await _uploadCurrentPhrase();
  }

  Future<void> _uploadCurrentPhrase() async {
    if (_userId == null) return;

    setState(() => _uploadStatus = UploadStatus.started);
    try {
      await _network.uploadEnrollment(
        userId: _userId!,
        clips: [
          EnrollmentClip(
            index: _currentIndex,
            phrase: _currentPrompt.phrase,
            file: File(_clipPath(_currentIndex)),
          ),
        ],
      );
      if (!mounted) return;
      setState(() => _uploadStatus = UploadStatus.completed);
    } catch (e) {
      if (mounted) {
        setState(() => _uploadStatus = UploadStatus.interrupted);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإرسال: $e')),
        );
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_isRecording || !await _hasRecording(_currentIndex)) return;

    if (_isPlaying) {
      await _player.pause();
      return;
    }

    try {
      await _player.playFile(_clipPath(_currentIndex));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تشغيل التسجيل: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _userId == null || _enrollmentRoot == null || _prompts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return PersonalizationView(
      pageStorageKey: _pageStorageKey,
      index: _currentIndex,
      phrases: _prompts,
      controller: _pageController,
      onPageChanged: _jumpToPhrase,
      previousPhrase: _currentIndex == 0 ? null : _previousPhrase,
      nextPhrase: _currentIndex >= _prompts.length - 1 ? null : _nextPhrase,
      record: _isPlaying ? null : _toggleRecording,
      isRecording: _isRecording,
      play: _isRecorded && !_isRecording ? _togglePlayback : null,
      isPlaying: _isPlaying,
      isRecorded: _isRecorded,
      uploadStatus: _uploadStatus,
    );
  }
}
