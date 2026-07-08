import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Thrown when the request never reached the server — no internet,
/// DNS failure, timeout, etc. Screens should show the "No Internet" view
/// for this one, with a Retry button.
class NoConnectionException implements Exception {
  final String message;
  NoConnectionException([this.message = 'No internet connection.']);
}

/// Thrown when the server responded but with an error (bad login,
/// validation failure, 500, etc). Screens should show this message inline,
/// not the no-internet view.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
}

class ApiClient {
  static const _timeout = Duration(seconds: 15);

  /// GET request. [baseUrl] example: https://greenfield.scholivax.top
  static Future<Map<String, dynamic>> get(
    String baseUrl,
    String path, {
    Map<String, String>? query,
    String? token,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    try {
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(_timeout);
      return _decode(response);
    } on TimeoutException {
      throw NoConnectionException('The request timed out. Check your internet and try again.');
    } on SocketException {
      throw NoConnectionException();
    } on HttpException {
      throw NoConnectionException();
    }
  }

  /// POST request with form-encoded body (matches the PHP backend's
  /// $this->input->post() expectations).
  static Future<Map<String, dynamic>> post(
    String baseUrl,
    String path,
    Map<String, String> body, {
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await http
          .post(uri, headers: _headers(token), body: body)
          .timeout(_timeout);
      return _decode(response);
    } on TimeoutException {
      throw NoConnectionException('The request timed out. Check your internet and try again.');
    } on SocketException {
      throw NoConnectionException();
    } on HttpException {
      throw NoConnectionException();
    }
  }

  static Map<String, String> _headers(String? token) {
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // Server returned something that isn't JSON (e.g. a raw PHP error
      // page or a 404 HTML page) — surface a clean message instead of
      // crashing on the parse.
      throw ApiException(
        'Unexpected response from server (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300 && data['status'] == 'success') {
      return data;
    }

    final message = data['message']?.toString() ?? 'Something went wrong. Please try again.';
    throw ApiException(message, statusCode: response.statusCode);
  }
}
