import '../models/user_session.dart';
import 'api_client.dart';

/// Fetches the native dashboard's analytics data from
/// GET /api/dashboard/summary (see controllers/api/Dashboard.php).
/// The shape of `dashboard` depends on the role — callers read the fields
/// relevant to their own role's UserSession.userType.
class DashboardService {
  static Future<Map<String, dynamic>> fetchSummary(UserSession session) async {
    final response = await ApiClient.get(
      session.baseUrl,
      '/api/dashboard/summary',
      token: session.token,
    );
    return (response['dashboard'] as Map).cast<String, dynamic>();
  }

  /// Parent-only: the same rich per-student dashboard a student sees
  /// logging in themselves, but for one of the parent's children.
  static Future<Map<String, dynamic>> fetchChildSummary(UserSession session, int studentId) async {
    final response = await ApiClient.get(
      session.baseUrl,
      '/api/dashboard/child_summary',
      query: {'student_id': studentId.toString()},
      token: session.token,
    );
    return (response['dashboard'] as Map).cast<String, dynamic>();
  }
}
