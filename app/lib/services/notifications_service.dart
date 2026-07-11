import '../models/app_notification.dart';
import '../models/user_session.dart';
import 'api_client.dart';
import 'offline_cache.dart';

class NotificationsService {
  static String _cacheKey(UserSession s) => 'notifications:${s.subdomain}';

  static Future<List<AppNotification>> loadCached(UserSession session) async {
    final raw = await OfflineCache.loadList(_cacheKey(session));
    final list = raw.map(AppNotification.fromJson).toList();
    list.sort((a, b) => b.id.compareTo(a.id));
    return list;
  }

  static Future<List<AppNotification>> refresh(UserSession session) async {
    final cached = await loadCached(session);
    final sinceId = cached.isEmpty ? 0 : cached.map((n) => n.id).reduce((a, b) => a > b ? a : b);

    final response = await ApiClient.get(
      session.baseUrl,
      '/api/notifications/list_all',
      query: {'since_id': sinceId.toString()},
      token: session.token,
    );

    final fresh = (response['notifications'] as List).cast<Map<String, dynamic>>().map(AppNotification.fromJson).toList();

    final merged = <int, AppNotification>{for (final n in cached) n.id: n};
    for (final n in fresh) {
      merged[n.id] = n;
    }
    final result = merged.values.toList()..sort((a, b) => b.id.compareTo(a.id));
    await OfflineCache.saveList(_cacheKey(session), result.map((n) => n.toJson()).toList());
    return result;
  }

  /// Cheap poll used for the bell's badge — tries the server, falls back
  /// to counting whatever's cached locally when offline.
  static Future<int> unreadCount(UserSession session) async {
    try {
      final response = await ApiClient.get(session.baseUrl, '/api/notifications/unread_count', token: session.token);
      return int.tryParse('${response['unread_count']}') ?? 0;
    } catch (_) {
      final cached = await loadCached(session);
      return cached.where((n) => !n.read).length;
    }
  }

  static Future<void> markRead(UserSession session, {int? id}) async {
    // Reflect locally right away so the badge/list update instantly even offline.
    final cached = await loadCached(session);
    final updated = cached.map((n) => (id == null || n.id == id) ? n.copyWith(read: true) : n).toList();
    await OfflineCache.saveList(_cacheKey(session), updated.map((n) => n.toJson()).toList());

    try {
      await ApiClient.post(
        session.baseUrl,
        '/api/notifications/mark_read',
        id == null ? {} : {'id': id.toString()},
        token: session.token,
      );
    } catch (_) {
      // Best-effort — local state is already updated; the server side
      // will catch up next time this succeeds.
    }
  }
}
