import 'dart:io' as io;
import '../models/user_session.dart';
import 'api_client.dart';
import 'web_cookie_bridge.dart';

/// Both calls here hit the ACTUAL website directly (not the token API),
/// reusing whatever session cookie is already sitting in the WebView's
/// cookie store from login — the same approach WebSessionService uses,
/// just for two follow-up actions instead of the login itself.
class ParentService {
  /// Flips which child's data every parent portal page shows, by asking
  /// the website to switch its session over to that child's parent row
  /// (see Parents::switch_child() on the backend for why this is needed —
  /// siblings can be split across separate parent rows sharing one phone).
  /// After this succeeds, reloading any parent WebView page shows the new
  /// child — no app-side state to track.
  static Future<void> switchChild(UserSession session, int studentId) async {
    final client = io.HttpClient();
    try {
      final cookieHeader = await WebCookieBridge.cookieHeaderFor(session.baseUrl);
      final uri = Uri.parse('${session.baseUrl}/parents/switch_child/$studentId');
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 15));
      request.headers.set('Cookie', cookieHeader);
      request.followRedirects = true;
      final response = await request.close().timeout(const Duration(seconds: 15));
      await response.drain();
    } finally {
      client.close();
    }
  }

  /// Sets a new password via the website's own existing
  /// parents/manage_profile/change_password endpoint — no new backend
  /// code needed for this part, it already exists and already works.
  static Future<void> changePassword(UserSession session, String newPassword) async {
    final client = io.HttpClient();
    try {
      final cookieHeader = await WebCookieBridge.cookieHeaderFor(session.baseUrl);
      final uri = Uri.parse('${session.baseUrl}/parents/manage_profile/change_password');
      final request = await client.postUrl(uri).timeout(const Duration(seconds: 15));
      request.headers.set('Cookie', cookieHeader);
      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');
      request.followRedirects = false;

      final body = 'new_password=${Uri.encodeQueryComponent(newPassword)}'
          '&confirm_new_password=${Uri.encodeQueryComponent(newPassword)}';
      request.write(body);

      final response = await request.close().timeout(const Duration(seconds: 15));
      await response.drain();
    } finally {
      client.close();
    }
  }

  /// Today's marked-or-not status for every linked child, for the "Track
  /// Attendance" section on the parent dashboard — this is the token API
  /// (Attendance::child_status()), not a website call like the two above.
  static Future<List<Map<String, dynamic>>> fetchTodayAttendance(UserSession session) async {
    final response = await ApiClient.get(session.baseUrl, '/api/attendance/child_status', token: session.token);
    return (response['children'] as List).cast<Map<String, dynamic>>();
  }
}
