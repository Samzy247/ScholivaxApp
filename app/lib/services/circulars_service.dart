import '../models/circular.dart';
import '../models/user_session.dart';
import 'api_client.dart';
import 'offline_cache.dart';

class CircularsService {
  static String _cacheKey(UserSession session) => 'circulars:${session.subdomain}';

  /// Whatever's cached locally — instant, works with no connection at all.
  static Future<List<Circular>> loadCached(UserSession session) async {
    final raw = await OfflineCache.loadList(_cacheKey(session));
    final circulars = raw.map(Circular.fromJson).toList();
    circulars.sort((a, b) => b.id.compareTo(a.id));
    return circulars;
  }

  /// Pulls anything newer than what's cached and merges it in. Throws
  /// [NoConnectionException]/[ApiException] on failure — callers should
  /// still have [loadCached] to fall back on when this fails.
  static Future<List<Circular>> refresh(UserSession session) async {
    final cached = await loadCached(session);
    final sinceId = cached.isEmpty ? 0 : cached.map((c) => c.id).reduce((a, b) => a > b ? a : b);

    final response = await ApiClient.get(
      session.baseUrl,
      '/api/circulars/list',
      query: {'since_id': sinceId.toString()},
      token: session.token,
    );

    final fresh = (response['circulars'] as List).cast<Map<String, dynamic>>().map(Circular.fromJson).toList();

    final merged = <int, Circular>{for (final c in cached) c.id: c};
    for (final c in fresh) {
      merged[c.id] = c;
    }
    final result = merged.values.toList()..sort((a, b) => b.id.compareTo(a.id));

    await OfflineCache.saveList(_cacheKey(session), result.map((c) => c.toJson()).toList());
    return result;
  }
}
