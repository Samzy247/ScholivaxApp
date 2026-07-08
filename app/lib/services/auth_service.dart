import '../models/school.dart';
import '../models/user_session.dart';
import 'api_client.dart';

class AuthService {
  /// [role] is 'admin', 'teacher', or 'student'.
  /// [identifier] is an email for admin/teacher, or the Reg No (roll) for students.
  static Future<UserSession> login({
    required School school,
    required String role,
    required String identifier,
    required String password,
  }) async {
    final data = await ApiClient.post(school.baseUrl, '/api/auth/login', {
      'role': role,
      'identifier': identifier,
      'password': password,
    });

    return UserSession(
      token: data['token'],
      userType: data['user_type'] ?? role,
      userId: data['user_id'] is int ? data['user_id'] : int.tryParse('${data['user_id']}') ?? 0,
      name: data['name'],
      schoolName: school.name,
      subdomain: school.subdomain,
    );
  }

  static Future<void> logout(UserSession session) async {
    try {
      await ApiClient.post(session.baseUrl, '/api/auth/logout', {}, token: session.token);
    } catch (_) {
      // Best-effort — even if this fails (no internet, token already
      // expired), we still clear the local session below.
    }
  }
}
