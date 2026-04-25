import 'dart:async';
import 'package:record/record.dart';
import '../../core/constants/audio_config.dart';

class SpeechRecordingService {
  SpeechRecordingService({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Starts recording to [path]. Stub: caller supplies a temp file path.
  Future<void> start({required String path}) async {
    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits, // Best for Wav2Vec ASR models (faster to process and no compression)
        sampleRate: AudioConfig.targetSampleRateHz,
        bitRate: 256000,
      ),
      path: path,
    );
  }

  Future<void> stop() => _recorder.stop();

  Future<void> dispose() => _recorder.dispose();
}
