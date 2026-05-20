import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/accessibility/wcag_theme.dart';
import '../../modules/speech_recording/speech_recording_service.dart';

enum _LivePhase { idle, recording, revealing }

class LiveAsrScreen extends StatefulWidget {
  const LiveAsrScreen({super.key});

  @override
  State<LiveAsrScreen> createState() => _LiveAsrScreenState();
}

class _LiveAsrScreenState extends State<LiveAsrScreen>
    with SingleTickerProviderStateMixin {
  final SpeechRecordingService _recorder = SpeechRecordingService();
  String? _activeRecordingPath;
  _LivePhase _phase = _LivePhase.idle;
  String _shownText = '';
  Timer? _typewriter;
  AnimationController? _pulseController;
  Animation<double>? _pulseScale;

  static const _mockCorrection =
      'تعالي نروح النادي';

  @override
  void initState() {
    super.initState();
    _ensurePulseAnimation();
  }

  void _ensurePulseAnimation() {
    if (_pulseController != null) return;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _typewriter?.cancel();
    unawaited(_recorder.dispose());
    super.dispose();
  }

  void _syncRecordingPulse() {
    if (!mounted) return;
    _ensurePulseAnimation();
    if (_phase == _LivePhase.recording) {
      _pulseController!.repeat(reverse: true);
    } else {
      _pulseController!
        ..stop()
        ..reset();
    }
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

  Future<void> _toggleMic() async {
    if (_phase == _LivePhase.revealing) return;
    if (_phase == _LivePhase.recording) {
      await _stopAndReveal();
      return;
    }
    if (!(await _ensureMic())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يلزم السماح باستخدام الميكروفون')),
        );
      }
      return;
    }
    await _startRecording();
  }

  Future<void> _startRecording() async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/soutify_live_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final file = File(path);
    if (await file.exists()) await file.delete();
    try {
      await _recorder.start(path: path);
      if (!mounted) return;
      setState(() {
        _activeRecordingPath = path;
        _phase = _LivePhase.recording;
        _shownText = '';
      });
      _syncRecordingPulse();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر التسجيل: $e')),
        );
      }
    }
  }

  Future<void> _stopAndReveal() async {
    final audioPath = _activeRecordingPath;
    try {
      await _recorder.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _activeRecordingPath = null;
      _phase = _LivePhase.revealing;
      _shownText = '';
    });
    _syncRecordingPulse();

    _queueServerProcessing(audioPath);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _runTypewriter();
  }

  void _runTypewriter() {
    _typewriter?.cancel();
    final graphemes = _mockCorrection.characters.toList();
    var i = 0;
    _typewriter = Timer.periodic(const Duration(milliseconds: 45), (timer) {
      if (i >= graphemes.length) {
        timer.cancel();
        Future<void>.delayed(const Duration(milliseconds: 3000)).then((_) {
          if (mounted) {
            setState(() {
              _phase = _LivePhase.idle;
              _shownText = '';
            });
            _syncRecordingPulse();
          }
        });
        return;
      }
      if (mounted) {
        setState(() => _shownText += graphemes[i]);
      }
      i++;
    });
  }

  void _queueServerProcessing(String? audioPath) {
    if (audioPath == null) return;
    // TODO: multipart POST to backend (ASR + AUD + RL); then setState with result text.
  }

  Future<void> _onBack() async {
    if (_phase == _LivePhase.recording) {
      try {
        await _recorder.stop();
      } catch (_) {}
      if (mounted) {
        setState(() => _activeRecordingPath = null);
      }
    }
    _typewriter?.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    _ensurePulseAnimation();
    final revealing = _phase == _LivePhase.revealing;
    final textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.black,
          height: 1.35,
        );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: revealing ? null : _onBack,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (revealing || _shownText.isNotEmpty)
                      Text(
                        _shownText,
                        style: textStyle,
                        textAlign: TextAlign.center,
                      ),
                    SizedBox(height: revealing || _shownText.isNotEmpty ? 40 : 0),
                    Semantics(
                      button: true,
                      label: _phase == _LivePhase.recording
                          ? 'إيقاف التسجيل'
                          : 'بدء التسجيل',
                      child: ScaleTransition(
                        scale: _phase == _LivePhase.recording
                            ? _pulseScale!
                            : const AlwaysStoppedAnimation(1.0),
                        child: Material(
                          color: _phase == _LivePhase.recording
                              ? WcagTheme.recordingRed
                              : WcagTheme.processingBlue,
                          elevation: 6,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: revealing ? null : () => _toggleMic(),
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: Icon(
                                _phase == _LivePhase.recording
                                    ? Icons.mic
                                    : Icons.circle,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
