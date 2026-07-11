import 'dart:io' as io;
import '../models/school.dart';
import 'api_client.dart' show NoConnectionException;

/// Logs into the REAL website (not the token API) so we get back the same
/// ci_session cookie a browser would get. That cookie then gets handed to
/// the in-app WebView, which loads the actual site — full feature parity,
/// nothing rebuilt natively.
///
/// The web login endpoint (Login::validate_login -> loginFunctionForAllUsers)
/// takes a single "email" field for every role — it's the same field
/// checked against `roll` for students — so no role parameter is needed
/// here, unlike the token API.
///
/// We also send `app_embed=1` — the backend remembers this on the session
/// (see Login_model::loginFunctionForAllUsers) so every page it renders
/// afterwards, including ones reached by tapping links inside the WebView,
/// skips its own header/sidebar/footer instead of just the first page.
///
/// Uses `dart:io`'s Cookie type explicitly (aliased as `io.Cookie`) since
/// flutter_inappwebview ALSO defines a class called Cookie — without the
/// alias, Dart can't tell which one a bare `Cookie` reference means.
class WebSessionService {
  /// Returns the list of cookies to hand to the WebView, e.g. [ci_session=...].
  /// Throws [NoConnectionException] if the site can't be reached, or
  /// [WebLoginException] if the login itself was rejected.
  static Future<List<io.Cookie>> login({
    required School school,
    required String identifier,
    required String password,
  }) async {
    final client = io.HttpClient();
    try {
      final uri = Uri.parse('${school.baseUrl}/login/validate_login');
      final request = await client.postUrl(uri).timeout(const Duration(seconds: 15));
      request.followRedirects = false;
      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');

      final body = 'email=${Uri.encodeQueryComponent(identifier)}'
          '&password=${Uri.encodeQueryComponent(password)}'
          '&app_embed=1';
      request.write(body);

      final response = await request.close().timeout(const Duration(seconds: 15));
      await response.drain();

      final cookies = response.cookies;
      final hasSessionCookie = cookies.any((c) => c.name == 'ci_session');

      // IMPORTANT: this site's login controller always redirects using
      // CodeIgniter's redirect(..., 'refresh') mode, which sends a
      // `Refresh:` header on a normal 200 response — NOT a real HTTP 3xx.
      // So the redirect target has to be read from that header (or
      // `Location`, in case that ever changes), never from the status code.
      final refreshHeader = response.headers.value('refresh');
      final locationHeader = response.headers.value('location');
      final target = refreshHeader != null
          ? (RegExp(r'url=(.*)$', caseSensitive: false).firstMatch(refreshHeader)?.group(1) ?? '')
          : (locationHeader ?? '');
      final loggedIn = target.isNotEmpty && !target.toLowerCase().contains('/login');

      if (!loggedIn || !hasSessionCookie) {
        throw WebLoginException('Invalid login details.');
      }

      // The website sets a one-time "{Name} Successfully Login" flash
      // message on every successful login (Login_model.php), which
      // js.php auto-pops as a SweetAlert on whatever page loads next —
      // showing up in the app as an unexplained "welcome" modal the
      // instant a WebView opens. CodeIgniter flashdata is read-once: the
      // PHP view has to actually render for it to be consumed. So we
      // silently fetch that same redirect target here, in the background,
      // discarding the response — that consumes the flash message before
      // the person ever sees a rendered page, and by the time the visible
      // WebView loads the same URL a moment later, there's nothing left
      // to pop up. Best-effort: if this fails for any reason, the only
      // consequence is the popup still shows once, so it's not worth
      // failing the login over.
      try {
        final targetUri = target.startsWith('http') ? Uri.parse(target) : Uri.parse('${school.baseUrl}$target');
        final warmupRequest = await client.getUrl(targetUri).timeout(const Duration(seconds: 10));
        warmupRequest.headers.set('Cookie', cookies.map((c) => '${c.name}=${c.value}').join('; '));
        final warmupResponse = await warmupRequest.close().timeout(const Duration(seconds: 10));
        await warmupResponse.drain();
      } catch (_) {
        // Non-fatal — see comment above.
      }

      return cookies;
    } on io.SocketException {
      throw NoConnectionException();
    } on io.HttpException {
      throw NoConnectionException();
    } finally {
      client.close();
    }
  }
}

class WebLoginException implements Exception {
  final String message;
  WebLoginException(this.message);
}
