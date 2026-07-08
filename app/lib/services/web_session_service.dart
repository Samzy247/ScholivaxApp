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
          '&password=${Uri.encodeQueryComponent(password)}';
      request.write(body);

      final response = await request.close().timeout(const Duration(seconds: 15));
      // A successful login redirects (302) to the right dashboard and sets
      // the session cookie on that same response. Drain the body either way.
      await response.drain();

      final cookies = response.cookies;
      final isRedirect = response.statusCode >= 300 && response.statusCode < 400;
      final hasSessionCookie = cookies.any((c) => c.name == 'ci_session');

      if (!isRedirect || !hasSessionCookie) {
        throw WebLoginException('Invalid login details.');
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
