import '../models/user_session.dart';
import 'api_client.dart';
import 'offline_cache.dart';

/// Matches application/views/backend/teacher/manage_attendance.php's
/// status <select> exactly — the canonical definition on the website.
class AttendanceStatus {
  static const absent = 0;
  static const halfDay = 1;
  static const present = 2;

  static String label(int status) {
    switch (status) {
      case absent:
        return 'Absent';
      case halfDay:
        return 'Half Day';
      case present:
        return 'Present';
      default:
        return 'Unmarked';
    }
  }
}

class AttendanceService {
  static String _classesKey(UserSession s) => 'attendance_classes:${s.subdomain}';
  static String _rosterKey(UserSession s, int classId, String date) => 'attendance_roster:${s.subdomain}:$classId:$date';
  static String _pendingKey(UserSession s) => 'attendance_pending:${s.subdomain}';

  // ── Classes the teacher can take attendance for ─────────────────────────
  static Future<List<Map<String, dynamic>>> loadCachedClasses(UserSession session) =>
      OfflineCache.loadList(_classesKey(session));

  static Future<List<Map<String, dynamic>>> refreshClasses(UserSession session) async {
    final response = await ApiClient.get(session.baseUrl, '/api/attendance/my_classes', token: session.token);
    final classes = (response['classes'] as List).cast<Map<String, dynamic>>();
    await OfflineCache.saveList(_classesKey(session), classes);
    return classes;
  }

  // ── Roster for one class+date, each student's current status included ──
  static Future<List<Map<String, dynamic>>> loadCachedRoster(UserSession session, int classId, String date) =>
      OfflineCache.loadList(_rosterKey(session, classId, date));

  static Future<List<Map<String, dynamic>>> refreshRoster(UserSession session, int classId, String date) async {
    final response = await ApiClient.get(
      session.baseUrl,
      '/api/attendance/roster',
      query: {'class_id': classId.toString(), 'date': date},
      token: session.token,
    );
    final students = (response['students'] as List).cast<Map<String, dynamic>>();
    await OfflineCache.saveList(_rosterKey(session, classId, date), students);
    return students;
  }

  /// Updates one student's status in the locally cached roster immediately
  /// (so re-opening the screen shows it even before syncing).
  static Future<void> _updateCachedStatus(UserSession session, int classId, String date, int studentId, int status) async {
    final key = _rosterKey(session, classId, date);
    final roster = await OfflineCache.loadList(key);
    final idx = roster.indexWhere((r) => r['student_id'] == studentId);
    if (idx != -1) {
      roster[idx] = {...roster[idx], 'status': status};
      await OfflineCache.saveList(key, roster);
    }
  }

  // ── Pending queue (things marked while offline, waiting to sync) ───────
  static Future<List<Map<String, dynamic>>> loadPending(UserSession session) => OfflineCache.loadList(_pendingKey(session));

  static Future<void> _queuePending(UserSession session, int studentId, String date, int status) async {
    final pending = await loadPending(session);
    pending.removeWhere((r) => r['student_id'] == studentId && r['date'] == date); // latest wins
    pending.add({'student_id': studentId, 'date': date, 'status': status});
    await OfflineCache.saveList(_pendingKey(session), pending);
  }

  /// Sets one student's status (Absent/Half Day/Present) for a date. Tries
  /// the server immediately; if that fails (offline, timeout) the change
  /// is queued locally instead — [syncPending] flushes the queue later.
  /// Either way the local roster cache is updated instantly.
  static Future<bool> setStatus(UserSession session, int classId, int studentId, String date, int status) async {
    await _updateCachedStatus(session, classId, date, studentId, status);
    try {
      await ApiClient.post(
        session.baseUrl,
        '/api/attendance/mark',
        {'student_id': studentId.toString(), 'date': date, 'status': status.toString()},
        token: session.token,
      );
      return true;
    } catch (_) {
      await _queuePending(session, studentId, date, status);
      return false;
    }
  }

  /// Marks a scanned roll number Present directly (scan mode only ever
  /// marks present — matching the website's barcode-scan page). Returns
  /// the student's name on success/queue, or null if the roll isn't in
  /// the cached roster (can't resolve a name while offline).
  static Future<String?> markScannedPresent(UserSession session, int classId, String date, String roll, List<Map<String, dynamic>> roster) async {
    final student = roster.firstWhere(
      (r) => r['roll'].toString().toLowerCase() == roll.toLowerCase(),
      orElse: () => {},
    );
    if (student.isEmpty) return null;
    await setStatus(session, classId, student['student_id'] as int, date, AttendanceStatus.present);
    return student['name'] as String?;
  }

  /// Flushes everything queued while offline in one request. Returns how
  /// many records were sent (0 if nothing was pending or the sync failed).
  static Future<int> syncPending(UserSession session) async {
    final pending = await loadPending(session);
    if (pending.isEmpty) return 0;

    try {
      await ApiClient.post(
        session.baseUrl,
        '/api/attendance/mark_batch',
        {'records': _encodeRecords(pending)},
        token: session.token,
      );
      await OfflineCache.clear(_pendingKey(session));
      return pending.length;
    } catch (_) {
      return 0; // still offline / server error — stays queued for next try
    }
  }

  static String _encodeRecords(List<Map<String, dynamic>> records) {
    final buffer = StringBuffer('[');
    for (var i = 0; i < records.length; i++) {
      if (i > 0) buffer.write(',');
      buffer.write('{"student_id":${records[i]['student_id']},"date":"${records[i]['date']}","status":${records[i]['status']}}');
    }
    buffer.write(']');
    return buffer.toString();
  }
}
