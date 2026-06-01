import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/accessibility/wcag_theme.dart';
import '../../modules/network_sync/network_sync_manager.dart';
import '../../modules/sound_playback/sound_playback_service.dart';
import '../../modules/speech_recording/speech_recording_service.dart';

enum _LivePhase { idle, recording, processing, revealing }

class LiveAsrScreen extends StatefulWidget {
  const LiveAsrScreen({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<LiveAsrScreen> createState() => _LiveAsrScreenState();
}

class _LiveAsrScreenState extends State<LiveAsrScreen>
    with SingleTickerProviderStateMixin {
  final SpeechRecordingService _recorder = SpeechRecordingService();
  final NetworkSyncManager _network = NetworkSyncManager();
  final SoundPlaybackService _playback = SoundPlaybackService();

  String? _activeRecordingPath;
  _LivePhase _phase = _LivePhase.idle;
  String _shownText = '';
  String _resultText = '';
  Timer? _typewriter;
  AnimationController? _pulseController;
  Animation<double>? _pulseScale;

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
    unawaited(_playback.dispose());
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
    if (_phase == _LivePhase.processing || _phase == _LivePhase.revealing) {
      return;
    }
    if (_phase == _LivePhase.recording) {
      await _stopAndReveal();
      return;
    }
    if (!(await _ensureMic())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required.')),
        );
      }
      return;
    }
    await _startRecording();
  }

  Future<void> _startRecording() async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/soutify_live_${DateTime.now().millisecondsSinceEpoch}.wav';
    final file = File(path);
    if (await file.exists()) await file.delete();
    try {
      await _playback.stop();
      await _recorder.start(path: path);
      if (!mounted) return;
      setState(() {
        _activeRecordingPath = path;
        _phase = _LivePhase.recording;
        _shownText = '';
        _resultText = '';
      });
      _syncRecordingPulse();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $e')),
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
      _phase = _LivePhase.processing;
      _shownText = '';
      _resultText = '';
    });
    _syncRecordingPulse();

    try {
      final result = await _sendToServer(audioPath);
      if (!mounted) return;
      setState(() {
        _resultText =
            result.text.isEmpty ? 'No speech detected.' : result.text;
        _phase = _LivePhase.revealing;
      });
      if (result.ttsAudioBase64 != null) {
        unawaited(_playback.playBase64(result.ttsAudioBase64!));
      }
      _runTypewriter();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech processing failed: $e')),
      );
      setState(() {
        _phase = _LivePhase.idle;
        _shownText = '';
      });
      _syncRecordingPulse();
    }
  }

  Future<({String text, String? ttsAudioBase64})> _sendToServer(
    String? audioPath,
  ) async {
    if (audioPath == null) {
      return (text: '', ttsAudioBase64: null);
    }
    final response = await _network.transcribe(File(audioPath));
    final text = (response['text'] as String? ?? '').trim();
    final corrected = text.isNotEmpty
        ? text
        : (response['raw_asr_text'] as String? ?? '').trim();

    String? ttsAudioBase64;
    final tts = response['tts'];
    if (tts is Map) {
      ttsAudioBase64 = (tts['audio_base64'] as String?)?.trim();
      if (ttsAudioBase64 != null && ttsAudioBase64.isEmpty) {
        ttsAudioBase64 = null;
      }
    }

    return (text: corrected, ttsAudioBase64: ttsAudioBase64);
  }

  void _runTypewriter() {
    _typewriter?.cancel();
    final graphemes = _resultText.characters.toList();
    var i = 0;
    _typewriter = Timer.periodic(const Duration(milliseconds: 45), (timer) {
      if (i >= graphemes.length) {
        timer.cancel();
        Future<void>.delayed(const Duration(seconds: 3)).then((_) {
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

  @override
  Widget build(BuildContext context) {
    _ensurePulseAnimation();
    final content = _buildContent(context);

    if (widget.embedded) {
      return ColoredBox(
        color: Colors.white,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    final processing = _phase == _LivePhase.processing;
    final revealing = _phase == _LivePhase.revealing;
    final textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.black,
          height: 1.35,
        );
    final resultVisible = revealing || _shownText.isNotEmpty;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (resultVisible)
                Text(
                  _shownText,
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: resultVisible ? 40 : 0),
              Semantics(
                button: true,
                label: switch (_phase) {
                  _LivePhase.recording => 'Stop recording',
                  _LivePhase.processing => 'Processing speech',
                  _ => 'Start recording',
                },
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
                      onTap: processing || revealing ? null : _toggleMic,
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: processing
                            ? const Padding(
                                padding: EdgeInsets.all(28),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
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
    );
  }
}
