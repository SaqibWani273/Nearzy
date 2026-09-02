import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import 'session_manager.dart';

/// The app's HTTP entry point.
///
/// Everything that talks to the Nearzy backend goes through here so two rules
/// hold everywhere at once:
///
///   * **One place attaches the token.** Callers ask for `auth: true` and
///     never touch storage themselves, so no call site can end up sending a
///     token that a refresh has since replaced.
///   * **A 401 is retried, once.** Access tokens are short-lived. When one is
///     rejected the client renews it and replays the request, so an expiry
///     mid-session is invisible instead of surfacing as a spurious "please
///     sign in again". If the renewal fails, the 401 is returned as-is and the
///     session manager has already ended the session.
class NearzyHttp {
  /// Sent on every request: skips ngrok's free-tier browser interstitial,
  /// which otherwise replaces the JSON body with an HTML warning page.
  static const Map<String, String> _baseHeaders = {
    'ngrok-skip-browser-warning': 'true',
  };

  static const Duration _timeout = Duration(seconds: 30);

  static Future<http.Response> get(
    Uri url, {
    bool auth = false,
    Map<String, String>? headers,
  }) =>
      _send('GET', url, auth: auth, headers: headers);

  static Future<http.Response> post(
    Uri url, {
    bool auth = false,
    Map<String, String>? headers,
    Object? body,
  }) =>
      _send('POST', url, auth: auth, headers: headers, body: body);

  static Future<http.Response> put(
    Uri url, {
    bool auth = false,
    Map<String, String>? headers,
    Object? body,
  }) =>
      _send('PUT', url, auth: auth, headers: headers, body: body);

  static Future<http.Response> patch(
    Uri url, {
    bool auth = false,
    Map<String, String>? headers,
    Object? body,
  }) =>
      _send('PATCH', url, auth: auth, headers: headers, body: body);

  static Future<http.Response> delete(
    Uri url, {
    bool auth = false,
    Map<String, String>? headers,
    Object? body,
  }) =>
      _send('DELETE', url, auth: auth, headers: headers, body: body);

  /// Convenience for the common case: JSON in, authenticated.
  static Future<http.Response> postJson(
    Uri url, {
    bool auth = false,
    Object? json,
    Map<String, String>? headers,
  }) =>
      post(
        url,
        auth: auth,
        headers: {'Content-Type': 'application/json', ...?headers},
        body: json == null ? null : jsonEncode(json),
      );

  static Future<http.Response> _send(
    String method,
    Uri url, {
    required bool auth,
    Map<String, String>? headers,
    Object? body,
    bool isRetry = false,
  }) async {
    final merged = <String, String>{..._baseHeaders, ...?headers};
    final resolved =
        auth ? await SessionManager.instance.authorize(merged) : merged;

    final request = http.Request(method, url)..headers.addAll(resolved);
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List<int>) {
        request.bodyBytes = body;
      } else if (body is Map<String, String>) {
        request.bodyFields = body;
      } else {
        request.body = jsonEncode(body);
      }
    }

    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 401 || !auth || isRetry) return response;

    // Only an expired or otherwise rejected *token* is worth retrying. A role
    // mismatch answers 403, and a request that carried no token in the first
    // place has nothing to renew.
    if (!resolved.containsKey('Authorization')) return response;

    log('401 on ${url.path} — refreshing and retrying once');
    final renewed = await SessionManager.instance.refreshActive();
    if (!renewed) return response;

    return _send(method, url,
        auth: auth, headers: headers, body: body, isRetry: true);
  }
}
