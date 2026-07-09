import '../models/user_session.dart';
import 'api_client.dart';
import 'offline_cache.dart';

class AttendanceService {
  static String _classesKey(UserSession s) => 'attendance_classes:${s.subdomain}';
  static String _rosterKey(UserSession s, int classId) => 'attendance_roster:${s.subdomain}:$classId';
  static String _markedKey(UserSession s, int classId, String date) =>
      'attendance_marked:${s.subdomain}:$classId:$date';
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

  // ── Roster for one class — cached so scanning/tapping works offline ────
  static Future<List<Map<String, dynamic>>> loadCachedRoster(UserSession session, int classId) =>
      OfflineCache.loadList(_rosterKey(session, classId));

  static Future<List<Map<String, dynamic>>> refreshRoster(UserSession session, int classId) async {
    final response = await ApiClient.get(
      session.baseUrl,
      '/api/attendance/roster',
      query: {'class_id': classId.toString()},
      token: session.token,
    );
    final students = (response['students'] as List).cast<Map<String, dynamic>>();
    await OfflineCache.saveList(_rosterKey(session, classId), students);
    return students;
  }

  // ── Which students are already marked present today (for this class) ──
  static Future<Set<String>> loadMarkedRolls(UserSession session, int classId, String date) async {
    final rows = await OfflineCache.loadList(_markedKey(session, classId, date));
    return rows.map((r) => r['roll'].toString()).toSet();
  }

  static Future<void> _addMarkedRoll(UserSession session, int classId, String date, String roll) async {
    final rows = await OfflineCache.loadList(_markedKey(session, classId, date));
    if (rows.any((r) => r['roll'] == roll)) return;
    rows.add({'roll': roll});
    await OfflineCache.saveList(_markedKey(session, classId, date), rows);
  }

  // ── Pending queue (things marked while offline, waiting to sync) ───────
  static Future<List<Map<String, dynamic>>> loadPending(UserSession session) => OfflineCache.loadList(_pendingKey(session));

  static Future<void> _queuePending(UserSession session, String roll, String date) async {
    final pending = await loadPending(session);
    pending.add({'roll': roll, 'date': date});
    await OfflineCache.saveList(_pendingKey(session), pending);
  }

  /// Marks one student present. Tries the server immediately; if that
  /// fails for any reason (offline, timeout), the mark is queued locally
  /// instead so it isn't lost — [syncPending] flushes the queue later.
  /// Either way, the roll is recorded as "marked" locally right away so
  /// the UI reflects it instantly.
  static Future<bool> markPresent(UserSession session, int classId, String roll, String date) async {
    await _addMarkedRoll(session, classId, date, roll);
    try {
      await ApiClient.post(
        session.baseUrl,
        '/api/attendance/mark',
        {'roll': roll, 'date': date},
        token: session.token,
      );
      return true; // synced immediately
    } catch (_) {
      await _queuePending(session, roll, date);
      return false; // queued for later
    }
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
    // Kept as a tiny local encoder (rather than importing dart:convert in
    // every call site) — matches the JSON the backend expects for the
    // `records` form field.
    final buffer = StringBuffer('[');
    for (var i = 0; i < records.length; i++) {
      if (i > 0) buffer.write(',');
      buffer.write('{"roll":"${records[i]['roll']}","date":"${records[i]['date']}"}');
    }
    buffer.write(']');
    return buffer.toString();
  }
}
