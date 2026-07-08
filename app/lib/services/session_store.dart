import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_session.dart';

/// Persists the logged-in session locally so the app doesn't ask for
/// school + role + login every time it's opened.
class SessionStore {
  static const _keys = ['token', 'userType', 'userId', 'name', 'schoolName', 'subdomain'];

  static Future<void> save(UserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final map = session.toPrefsMap();
    for (final key in _keys) {
      await prefs.setString(key, map[key] ?? '');
    }
  }

  static Future<UserSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final subdomain = prefs.getString('subdomain');
    if (token == null || token.isEmpty || subdomain == null || subdomain.isEmpty) {
      return null;
    }
    final map = <String, String>{};
    for (final key in _keys) {
      map[key] = prefs.getString(key) ?? '';
    }
    return UserSession.fromPrefsMap(map);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _keys) {
      await prefs.remove(key);
    }
  }
}
