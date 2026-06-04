import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
class UserIdStore {
  UserIdStore._();

  static final UserIdStore instance = UserIdStore._();

  static const _key = 'soutify_user_id';

  SharedPreferences? _prefs;

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String> getOrCreateUserId() async {
    await _ensurePrefs();
    var id = _prefs!.getString(_key);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await _prefs!.setString(_key, id);
    }
    return id;
  }
}