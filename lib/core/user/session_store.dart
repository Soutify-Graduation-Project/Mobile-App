import 'package:shared_preferences/shared_preferences.dart';

class SessionUser {
  const SessionUser({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}

class SessionStore {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  static const _tokenKey = 'soutify_access_token';
  static const _userIdKey = 'soutify_user_id';
  static const _nameKey = 'soutify_user_name';
  static const _emailKey = 'soutify_user_email';

  SharedPreferences? _prefs;

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String?> get accessToken async {
    await _ensurePrefs();
    return _prefs!.getString(_tokenKey);
  }

  Future<SessionUser?> get user async {
    await _ensurePrefs();
    final id = _prefs!.getString(_userIdKey);
    final name = _prefs!.getString(_nameKey);
    final email = _prefs!.getString(_emailKey);
    if (id == null || name == null || email == null) return null;
    return SessionUser(id: id, name: name, email: email);
  }

  Future<void> save({required String token, required SessionUser user}) async {
    await _ensurePrefs();
    await _prefs!.setString(_tokenKey, token);
    await _prefs!.setString(_userIdKey, user.id);
    await _prefs!.setString(_nameKey, user.name);
    await _prefs!.setString(_emailKey, user.email);
  }

  Future<void> clear() async {
    await _ensurePrefs();
    await _prefs!.remove(_tokenKey);
    await _prefs!.remove(_userIdKey);
    await _prefs!.remove(_nameKey);
    await _prefs!.remove(_emailKey);
  }
}
