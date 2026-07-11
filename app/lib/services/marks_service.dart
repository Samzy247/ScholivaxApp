import '../models/user_session.dart';
import 'api_client.dart';
import 'offline_cache.dart';

class MarksService {
  static String _subjectsKey(UserSession s) => 'marks_subjects:${s.subdomain}';
  static String _examsKey(UserSession s) => 'marks_exams:${s.subdomain}';
  static String _rosterKey(UserSession s, int examId, int classId, int subjectId) =>
      'marks_roster:${s.subdomain}:$examId:$classId:$subjectId';
  static String _dirtyKey(UserSession s, int examId, int classId, int subjectId) =>
      'marks_dirty:${s.subdomain}:$examId:$classId:$subjectId';

  // ── What this teacher teaches (subject + class pairs) ──────────────────
  static Future<List<Map<String, dynamic>>> loadCachedSubjects(UserSession session) =>
      OfflineCache.loadList(_subjectsKey(session));

  static Future<List<Map<String, dynamic>>> refreshSubjects(UserSession session) async {
    final response = await ApiClient.get(session.baseUrl, '/api/marks/my_subjects', token: session.token);
    final subjects = (response['subjects'] as List).cast<Map<String, dynamic>>();
    await OfflineCache.saveList(_subjectsKey(session), subjects);
    return subjects;
  }

  // ── Exams list ───────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> loadCachedExams(UserSession session) => OfflineCache.loadList(_examsKey(session));

  static Future<List<Map<String, dynamic>>> refreshExams(UserSession session) async {
    final response = await ApiClient.get(session.baseUrl, '/api/marks/exams', token: session.token);
    final exams = (response['exams'] as List).cast<Map<String, dynamic>>();
    await OfflineCache.saveList(_examsKey(session), exams);
    return exams;
  }

  // ── Score sheet: field layout (varies per school's report template) +
  //    each student's existing values ─────────────────────────────────────
  static Future<Map<String, dynamic>?> loadCachedSheet(UserSession session, int examId, int classId, int subjectId) =>
      OfflineCache.loadMap(_rosterKey(session, examId, classId, subjectId));

  static Future<Map<String, dynamic>> refreshSheet(UserSession session, int examId, int classId, int subjectId) async {
    final response = await ApiClient.get(
      session.baseUrl,
      '/api/marks/roster',
      query: {'exam_id': examId.toString(), 'class_id': classId.toString(), 'subject_id': subjectId.toString()},
      token: session.token,
    );
    await OfflineCache.saveMap(_rosterKey(session, examId, classId, subjectId), response);
    return response;
  }

  /// Updates one student's field values locally (works with no connection)
  /// and flags them as not-yet-submitted. Call [submitPending] once online.
  static Future<void> editScoreLocally(
    UserSession session,
    int examId,
    int classId,
    int subjectId,
    int studentId,
    Map<String, String> values,
    String comment,
  ) async {
    final key = _rosterKey(session, examId, classId, subjectId);
    final sheet = await OfflineCache.loadMap(key);
    if (sheet != null) {
      final students = (sheet['students'] as List).cast<Map<String, dynamic>>();
      final idx = students.indexWhere((s) => s['student_id'] == studentId);
      if (idx != -1) {
        students[idx] = {...students[idx], 'values': values, 'comment': comment};
        sheet['students'] = students;
        await OfflineCache.saveMap(key, sheet);
      }
    }

    final dirtyKey = _dirtyKey(session, examId, classId, subjectId);
    final dirty = await OfflineCache.loadList(dirtyKey);
    final dIdx = dirty.indexWhere((r) => r['student_id'] == studentId);
    final entry = {'student_id': studentId, 'values': values, 'comment': comment};
    if (dIdx != -1) {
      dirty[dIdx] = entry;
    } else {
      dirty.add(entry);
    }
    await OfflineCache.saveList(dirtyKey, dirty);
  }

  static Future<int> pendingCount(UserSession session, int examId, int classId, int subjectId) async {
    final dirty = await OfflineCache.loadList(_dirtyKey(session, examId, classId, subjectId));
    return dirty.length;
  }

  /// Submits every locally-edited score for this exam/class/subject sheet
  /// in one request. Returns how many were sent (0 if none pending, or the
  /// request failed and everything stays queued for next time).
  static Future<int> submitPending(UserSession session, int examId, int classId, int subjectId) async {
    final dirtyKey = _dirtyKey(session, examId, classId, subjectId);
    final dirty = await OfflineCache.loadList(dirtyKey);
    if (dirty.isEmpty) return 0;

    try {
      await ApiClient.post(
        session.baseUrl,
        '/api/marks/submit',
        {
          'exam_id': examId.toString(),
          'class_id': classId.toString(),
          'subject_id': subjectId.toString(),
          'entries': _encodeEntries(dirty),
        },
        token: session.token,
      );
      await OfflineCache.clear(dirtyKey);
      return dirty.length;
    } catch (_) {
      return 0;
    }
  }

  static String _encodeEntries(List<Map<String, dynamic>> entries) {
    final buffer = StringBuffer('[');
    for (var i = 0; i < entries.length; i++) {
      if (i > 0) buffer.write(',');
      final e = entries[i];
      final comment = e['comment'].toString().replaceAll('"', '\\"');
      final values = (e['values'] as Map).cast<String, String>();
      final valuesJson = values.entries.map((kv) => '"${kv.key}":"${kv.value}"').join(',');
      buffer.write('{"student_id":${e['student_id']},"values":{$valuesJson},"comment":"$comment"}');
    }
    buffer.write(']');
    return buffer.toString();
  }
}
