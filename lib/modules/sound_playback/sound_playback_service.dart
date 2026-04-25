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

  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();
}
