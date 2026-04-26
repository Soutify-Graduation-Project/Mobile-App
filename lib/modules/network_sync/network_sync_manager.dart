import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import 'api_client.dart';
import 'enrollment_clip.dart';

/// Uploads enrollment audio and other server calls (TTS, etc.).
///
/// TODO: Define multipart schema, auth headers, and streaming TTS protocol.
class NetworkSyncManager {
  NetworkSyncManager({ApiClient? apiClient}) : client = apiClient ?? ApiClient();

  /// Shared HTTP client for enrollment and TTS calls.
  final ApiClient client;

  /// Upload enrollment clips (paths on device) in one request or batch (TBD).
    Future<void> uploadEnrollment({
    required String userId,
    required List<EnrollmentClip> clips,
  }) async {
    if (clips.isEmpty) return;

    final phraseMeta = clips
        .map((c) => {'index': c.index, 'phrase': c.phrase})
        .toList();

    final form = FormData.fromMap({
      'user_id': userId,
      'phrases': jsonEncode(phraseMeta),
    });

    for (final c in clips) {
      form.files.add(
        MapEntry(
          'audio_${c.index}',
          await MultipartFile.fromFile(
            c.file.path,
            filename: c.file.uri.pathSegments.isNotEmpty
                ? c.file.uri.pathSegments.last
                : 'clip_${c.index}.m4a',
          ),
        ),
      );
    }

    await client.client.post(ApiEndpoints.enrollmentUpload, data: form);
  }

  /// Request cloned-voice TTS; returns playable URL or stream handle (TBD).
  Future<String> requestTts({
    required String text,
    required String voiceEmbeddingId,
  }) async {
    // TODO: POST → URL or SSE
    return '';
  }
}
