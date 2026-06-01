import 'dart:convert';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Streams or plays local TTS audio; includes a cache directory for chunks.
class SoundPlaybackService {
  SoundPlaybackService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  Future<Directory> cacheDirectory() async {
    final dir = await getTemporaryDirectory();
    final sub = Directory('${dir.path}/soutify_tts_cache');
    if (!await sub.exists()) {
      await sub.create(recursive: true);
    }
    return sub;
  }

  /// Play from remote URL (hybrid TTS). TODO: progressive download / stream.
  Future<void> playUrl(String url) async {
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> playFile(String path) async {
    await _player.setFilePath(path);
    await _player.play();
  }

  /// Decodes [base64Audio] to a temp file and plays it (e.g. transcribe TTS).
  Future<void> playBase64(String base64Audio, {String extension = 'wav'}) async {
    final bytes = base64Decode(base64Audio);
    final dir = await cacheDirectory();
    final path =
        '${dir.path}/playback_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final file = File(path);
    await file.writeAsBytes(bytes);
    await playFile(path);
  }

  Future<void> pause() => _player.pause();

  bool get isPlaying => _player.playing;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();
}
