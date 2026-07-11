import 'dart:io' as io;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Pushes the real website's session cookies (fetched via [WebSessionService])
/// into flutter_inappwebview's CookieManager.
///
/// This is the missing "bridge" between the app's token-based API login and
/// the actual website's cookie-based session. flutter_inappwebview's
/// CookieManager is backed by the platform's real WebView cookie store —
/// it's shared and persisted across every InAppWebView instance in the app
/// (and across app restarts), so applying cookies once here means ANY
/// InAppWebView opened afterwards — the main dashboard, or any portal page
/// opened from a card — is already logged in. No re-login, no per-screen
/// wiring needed.
class WebCookieBridge {
  static Future<void> apply(String baseUrl, List<io.Cookie> cookies) async {
    if (cookies.isEmpty) return;
    final host = Uri.parse(baseUrl).host;
    final cookieManager = CookieManager.instance();
    for (final cookie in cookies) {
      await cookieManager.setCookie(
        url: WebUri(baseUrl),
        name: cookie.name,
        value: cookie.value,
        domain: host,
        path: '/',
        isSecure: true,
      );
    }
  }

  /// Clears all cookies — call on logout so the next login doesn't inherit
  /// a stale session.
  static Future<void> clear() async {
    await CookieManager.instance().deleteAllCookies();
  }

  /// Reads back the cookies currently held for [baseUrl] as a single
  /// "name=value; name2=value2" header string — for the rare native call
  /// that needs to hit a website endpoint directly (not through a WebView)
  /// but still ride on the same logged-in session, e.g. switching which
  /// child is active, or changing a parent's password.
  static Future<String> cookieHeaderFor(String baseUrl) async {
    final cookies = await CookieManager.instance().getCookies(url: WebUri(baseUrl));
    return cookies.map((c) => '${c.name}=${c.value}').join('; ');
  }
}
