import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/user/session_store.dart';
import 'api_client.dart';
import 'enrollment_clip.dart';

class NetworkSyncManager {
  NetworkSyncManager({ApiClient? apiClient}) : client = apiClient ?? ApiClient();

  final ApiClient client;

  Future<SessionUser> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await client.client.post(
      ApiEndpoints.signup,
      data: {'name': name, 'email': email, 'password': password},
    );
    return _saveAuthResponse(response.data as Map<String, dynamic>);
  }

  Future<SessionUser> login({
    required String email,
    required String password,
  }) async {
    final response = await client.client.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return _saveAuthResponse(response.data as Map<String, dynamic>);
  }

  Future<SessionUser> currentUser() async {
    final response = await client.client.get(ApiEndpoints.me);
    return SessionUser.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> personalizationStatus() async {
    final response = await client.client.get(ApiEndpoints.personalizationStatus);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> finalizePersonalization() async {
    final response = await client.client.post(ApiEndpoints.personalizationFinalize);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> uploadEnrollment({required List<EnrollmentClip> clips}) async {
    if (clips.isEmpty) return;
    for (final c in clips) {
      final form = FormData.fromMap({
        'phrase_id': c.index.toString(),
        'transcript': c.phrase,
        'intent': c.intent,
        'category': c.category,
        'file': await MultipartFile.fromFile(
          c.file.path,
          filename: c.file.uri.pathSegments.isNotEmpty
              ? c.file.uri.pathSegments.last
              : 'clip_${c.index}.wav',
        ),
      });
      await client.client.post(ApiEndpoints.enrollmentUpload, data: form);
    }
  }

  Future<Map<String, dynamic>> transcribe(File audioFile) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        audioFile.path,
        filename: audioFile.uri.pathSegments.isNotEmpty
            ? audioFile.uri.pathSegments.last
            : 'speech.wav',
      ),
      'include_tts': 'true',
    });
    final response = await client.client.post(ApiEndpoints.transcribe, data: form);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<SessionUser> _saveAuthResponse(Map<String, dynamic> data) async {
    final token = data['access_token'] as String;
    final user = SessionUser.fromJson(data['user'] as Map<String, dynamic>);
    await SessionStore.instance.save(token: token, user: user);
    return user;
  }
}
