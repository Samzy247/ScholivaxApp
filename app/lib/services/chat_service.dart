import '../models/user_session.dart';
import 'api_client.dart';

class ChatService {
  /// Parent-only: opens (creating if needed) the conversation with a
  /// child's current class teacher.
  static Future<Map<String, dynamic>> openThreadForChild(UserSession session, int studentId) async {
    final response = await ApiClient.get(
      session.baseUrl,
      '/api/chat/thread',
      query: {'student_id': studentId.toString()},
      token: session.token,
    );
    return response;
  }

  static Future<List<Map<String, dynamic>>> fetchMessages(UserSession session, int threadId, {int sinceId = 0}) async {
    final response = await ApiClient.get(
      session.baseUrl,
      '/api/chat/messages',
      query: {'thread_id': threadId.toString(), 'since_id': sinceId.toString()},
      token: session.token,
    );
    return (response['messages'] as List).cast<Map<String, dynamic>>();
  }

  static Future<void> sendMessage(UserSession session, {required int threadId, required String body}) async {
    await ApiClient.post(
      session.baseUrl,
      '/api/chat/send',
      {'thread_id': threadId.toString(), 'body': body},
      token: session.token,
    );
  }

  static Future<void> markRead(UserSession session, int threadId) async {
    await ApiClient.post(
      session.baseUrl,
      '/api/chat/mark_read',
      {'thread_id': threadId.toString()},
      token: session.token,
    );
  }

  // Teacher-only.
  static Future<List<Map<String, dynamic>>> fetchInbox(UserSession session) async {
    final response = await ApiClient.get(session.baseUrl, '/api/chat/inbox', token: session.token);
    return (response['threads'] as List).cast<Map<String, dynamic>>();
  }
}
