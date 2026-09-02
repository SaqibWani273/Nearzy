import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../constants/bottom_navbar_items.dart';
import '../constants/rest_api_const.dart';
import '../data/models/auth_session.dart';
import '../utils/secure_storage.dart';

/// What happened to the signed-in identity. The app shell rebuilds on
/// [signedIn], [switched] and [signedOut]; [refreshed] is routine token
/// maintenance and must not disturb anything on screen.
enum SessionChange { signedIn, switched, signedOut, refreshed, expired }

class SessionEvent {
  const SessionEvent(this.change, {this.email, this.message});

  final SessionChange change;
  final String? email;

  /// Set on [SessionChange.expired] — what to tell the user about why they
  /// are being asked to sign in again.
  final String? message;
}

/// Every account signed into on this device, and which one is live.
///
/// Two jobs that are really one:
///
///   * **Switching.** Signing out to try another account meant retyping a
///     password every time. Sessions are kept per account, so switching is a
///     tap and the previous account is still signed in when you come back.
///   * **Refreshing.** Access tokens are short-lived. [accessToken] renews the
///     active one before handing it out, and [refreshActive] is what the HTTP
///     layer calls when the server rejects a token anyway. Both funnel through
///     a single in-flight future, so twenty parallel requests hitting an
///     expired token produce one refresh, not twenty — which matters because
///     refresh tokens rotate, and racing refreshes would each invalidate the
///     others and log the user out.
class SessionManager {
  SessionManager._();

  static final SessionManager instance = SessionManager._();

  static const String _storageKey = 'nearzy_accounts';

  /// Where builds before multi-account kept the one and only token.
  static const String _legacyTokenKey = 'jwt_token';

  final Map<String, StoredAccount> _accounts = {};
  String? _activeEmail;

  /// Held rather than a bool: a second caller arriving mid-load must wait for
  /// the same load, not sail past a flag into an empty account map.
  Future<void>? _restoring;

  Future<AuthSession?>? _inFlightRefresh;

  /// Which account [_inFlightRefresh] belongs to, so a refresh for one account
  /// is never handed to a caller asking about another.
  String? _refreshingEmail;

  final StreamController<SessionEvent> _events =
      StreamController<SessionEvent>.broadcast();

  Stream<SessionEvent> get events => _events.stream;

  /// Signed-in accounts, most recently used first.
  List<StoredAccount> get accounts {
    final list = _accounts.values.toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    return list;
  }

  StoredAccount? get active =>
      _activeEmail == null ? null : _accounts[_activeEmail];

  String? get activeEmail => _activeEmail;

  bool get isSignedIn => active != null;

  /// Whether an account is signed in, restoring from storage first. Callers
  /// that run before the app has restored (a cold start, a background fetch)
  /// must use this rather than [isSignedIn].
  Future<bool> hasSession() async {
    await restore();
    return active != null;
  }

  /// Accounts other than the live one — what the switcher offers.
  List<StoredAccount> get otherAccounts =>
      accounts.where((a) => a.email != _activeEmail).toList();

  // ── Persistence ───────────────────────────────────────────────────────

  /// Loads saved accounts. Safe to call more than once and from anywhere:
  /// concurrent callers all await the same load.
  Future<void> restore() => _restoring ??= _restore();

  Future<void> _restore() async {
    try {
      final raw = await SecureStorage.getData(key: _storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final entry in (decoded['accounts'] as List? ?? const [])) {
            if (entry is! Map) continue;
            final account =
                StoredAccount.tryFromJson(Map<String, dynamic>.from(entry));
            if (account != null) _accounts[account.email] = account;
          }
          final active = decoded['active'] as String?;
          if (active != null && _accounts.containsKey(active)) {
            _activeEmail = active;
          }
        }
      }

      // One-time migration: a bare token from before this file existed becomes
      // an account with no refresh half, so an updated app doesn't sign
      // everyone out on first launch.
      if (_accounts.isEmpty) {
        final legacy = await SecureStorage.getData(key: _legacyTokenKey);
        final session = legacy == null || legacy.isEmpty
            ? null
            : AuthSession.tryParse(legacy);
        if (session != null) {
          final email = _emailFromJwt(session.accessToken) ?? 'signed-in';
          _accounts[email] = StoredAccount(
            email: email,
            displayName: email.split('@').first,
            role: _roleFromJwt(session.accessToken) ?? Roles.ROLE_CUSTOMER,
            session: session,
            lastUsedAt: DateTime.now(),
          );
          _activeEmail = email;
          await _persist();
        }
      }
    } catch (e) {
      log('SessionManager.restore failed: $e');
    }
  }

  Future<void> _persist() async {
    try {
      await SecureStorage.storeData(
        key: _storageKey,
        value: jsonEncode({
          'active': _activeEmail,
          'accounts': _accounts.values.map((a) => a.toJson()).toList(),
        }),
      );
      // Mirrored so any straggler still reading the old key sees the live
      // token rather than a stale one from two accounts ago.
      final token = active?.session.accessToken;
      if (token == null || token.isEmpty) {
        await SecureStorage.deleteData(key: _legacyTokenKey);
      } else {
        await SecureStorage.storeData(key: _legacyTokenKey, value: token);
      }
    } catch (e) {
      log('SessionManager persist failed: $e');
    }
  }

  // ── Sign in / out / switch ────────────────────────────────────────────

  /// Records a successful sign-in and makes that account active.
  ///
  /// [responseBody] is the raw `/login` body; [fallbackRole] covers the older
  /// response shape, which carried no role.
  Future<AuthSession> signIn({
    required String responseBody,
    required Roles fallbackRole,
    String? email,
    String? displayName,
  }) async {
    await restore();
    final session = AuthSession.tryParse(responseBody);
    if (session == null) {
      throw const FormatException('Sign-in response carried no token');
    }

    final decoded = _tryDecodeMap(responseBody);
    final resolvedEmail = (decoded?['email'] as String?) ??
        email ??
        _emailFromJwt(session.accessToken) ??
        'signed-in';
    final resolvedRole = rolesFromWire(decoded?['role'] as String?) ??
        _roleFromJwt(session.accessToken) ??
        fallbackRole;

    final existing = _accounts[resolvedEmail];
    _accounts[resolvedEmail] = StoredAccount(
      email: resolvedEmail,
      displayName: (decoded?['username'] as String?) ??
          displayName ??
          existing?.displayName ??
          resolvedEmail.split('@').first,
      role: resolvedRole,
      session: session,
      lastUsedAt: DateTime.now(),
      avatarUrl: existing?.avatarUrl,
    );
    _activeEmail = resolvedEmail;
    await _persist();
    _events.add(SessionEvent(SessionChange.signedIn, email: resolvedEmail));
    return session;
  }

  /// Makes an already-signed-in account live.
  ///
  /// Returns false when its session could not be renewed — the account stays
  /// in the list so the switcher can offer to sign in again, but nothing is
  /// switched, because a half-authenticated shell is worse than staying put.
  Future<bool> switchTo(String email) async {
    await restore();
    final target = _accounts[email];
    if (target == null) return false;
    if (email == _activeEmail) return true;

    final previous = _activeEmail;
    _activeEmail = email;
    _accounts[email] = target.copyWith(lastUsedAt: DateTime.now());
    await _persist();

    final token = await accessToken();
    if (token == null) {
      _activeEmail = previous;
      await _persist();
      return false;
    }

    _events.add(SessionEvent(SessionChange.switched, email: email));
    return true;
  }

  /// Signs out of the active account and falls back to the next most recent
  /// one, if there is one.
  ///
  /// [everywhere] ends that account's sessions on other devices too.
  Future<void> signOutActive({bool everywhere = false}) async {
    await restore();
    final account = active;
    if (account == null) return;

    await _revokeOnServer(account, everywhere: everywhere);

    _accounts.remove(account.email);
    _activeEmail = accounts.isEmpty ? null : accounts.first.email;
    await _persist();
    _events.add(SessionEvent(SessionChange.signedOut, email: account.email));
  }

  /// Removes an account from the device without touching the active one —
  /// unless it *is* the active one, in which case this is a sign-out.
  ///
  /// Emits nothing when a background account is dropped: who the app is signed
  /// in as has not changed, and rebuilding the shell would tear down the very
  /// sheet the tap came from.
  Future<void> forget(String email) async {
    await restore();
    if (email == _activeEmail) return signOutActive();
    final account = _accounts.remove(email);
    if (account == null) return;
    await _revokeOnServer(account);
    await _persist();
  }

  Future<void> _revokeOnServer(StoredAccount account,
      {bool everywhere = false}) async {
    if (!account.session.canRefresh && !everywhere) return;
    try {
      await http
          .post(
            Uri.parse(ApiConst.logoutUrl),
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
              if (everywhere)
                'Authorization': 'Bearer ${account.session.accessToken}',
            },
            body: jsonEncode({
              'refreshToken': account.session.refreshToken,
              if (everywhere) 'allDevices': true,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      // The device is signing out either way — a refresh token left live on an
      // unreachable server is not a reason to keep the user signed in here.
      log('logout revoke failed (ignored): $e');
    }
  }

  // ── Tokens ────────────────────────────────────────────────────────────

  /// A usable access token for the active account, renewing it first if it is
  /// at or near expiry. Null when nobody is signed in or the session is dead.
  Future<String?> accessToken() async {
    await restore();
    final account = active;
    if (account == null) return null;
    if (!account.session.isExpired) return account.session.accessToken;
    if (!account.session.canRefresh) {
      await _expire('Your session has ended. Please sign in again.');
      return null;
    }
    final refreshed = await _refresh(account);
    return refreshed?.accessToken;
  }

  /// Forces a renewal — what the HTTP layer calls after a 401, where the
  /// server has rejected a token the client still thought was good.
  Future<bool> refreshActive() async {
    await restore();
    final account = active;
    if (account == null) return false;
    if (!account.session.canRefresh) {
      await _expire('Your session has ended. Please sign in again.');
      return false;
    }
    return await _refresh(account) != null;
  }

  /// One refresh at a time per account, per the rotation rule in the class doc.
  Future<AuthSession?> _refresh(StoredAccount account) {
    final existing = _inFlightRefresh;
    if (existing != null && _refreshingEmail == account.email) return existing;

    final attempt = _performRefresh(account).whenComplete(() {
      _inFlightRefresh = null;
      _refreshingEmail = null;
    });
    _inFlightRefresh = attempt;
    _refreshingEmail = account.email;
    return attempt;
  }

  Future<AuthSession?> _performRefresh(StoredAccount account) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConst.refreshTokenUrl),
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({'refreshToken': account.session.refreshToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final session = AuthSession.tryParse(response.body);
        if (session == null) return null;
        // Read the account back rather than reusing the captured copy: a
        // switch may have landed while this was in flight.
        final current = _accounts[account.email];
        if (current == null) return null;
        _accounts[account.email] = current.copyWith(session: session);
        await _persist();
        if (account.email == _activeEmail) {
          _events.add(
              SessionEvent(SessionChange.refreshed, email: account.email));
        }
        return session;
      }

      // 401 means the refresh token itself is spent, revoked or replayed —
      // no amount of retrying fixes that, so end the session cleanly instead
      // of letting every subsequent call fail on its own.
      if (response.statusCode == 401) {
        log('refresh rejected: ${response.body}');
        await _expire(_expiryMessage(response.body), email: account.email);
        return null;
      }

      // A server or network fault is temporary. Keep the tokens; the next
      // call tries again.
      log('refresh failed with ${response.statusCode}');
      return null;
    } catch (e) {
      log('refresh error: $e');
      return null;
    }
  }

  String _expiryMessage(String body) {
    final decoded = _tryDecodeMap(body);
    if (decoded?['code'] == 'REFRESH_TOKEN_REUSED') {
      return 'You were signed out for security. Please sign in again.';
    }
    return 'Your session has ended. Please sign in again.';
  }

  /// Drops a dead session. The account is removed rather than left in the
  /// switcher pretending to be signed in.
  Future<void> _expire(String message, {String? email}) async {
    final target = email ?? _activeEmail;
    if (target == null) return;
    _accounts.remove(target);
    if (_activeEmail == target) {
      _activeEmail = accounts.isEmpty ? null : accounts.first.email;
    }
    await _persist();
    _events.add(SessionEvent(SessionChange.expired,
        email: target, message: message));
  }

  /// Attaches the active bearer token to [headers], refreshing if needed.
  Future<Map<String, String>> authorize(Map<String, String> headers) async {
    final token = await accessToken();
    if (token == null || token.isEmpty) return headers;
    return {...headers, 'Authorization': 'Bearer $token'};
  }

  // ── JWT helpers ───────────────────────────────────────────────────────

  Map<String, dynamic>? _tryDecodeMap(String body) {
    try {
      final decoded = jsonDecode(body.trim());
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  /// Reads the payload of a JWT without verifying it. Only used to label an
  /// account in the UI — never to decide what it may do.
  Map<String, dynamic>? _jwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = jsonDecode(decoded);
      return map is Map ? Map<String, dynamic>.from(map) : null;
    } catch (_) {
      return null;
    }
  }

  String? _emailFromJwt(String token) => _jwtPayload(token)?['sub'] as String?;

  Roles? _roleFromJwt(String token) =>
      rolesFromWire(_jwtPayload(token)?['role'] as String?);
}
