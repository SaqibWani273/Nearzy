// End-to-end checks for the refresh mechanism, run against a live backend.
//
// These are the tests that would have caught a broken refresh: they drive the
// real SessionManager and NearzyHttp against a real server, rather than a
// stub that always says yes. They skip themselves when nothing is listening on
// the configured base URL, so the suite still passes on a machine with no
// backend running.
//
//   cd backend && npm run dev
//   cd frontend && fvm flutter test test/session_refresh_test.dart

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:nearzy/constants/bottom_navbar_items.dart';
import 'package:nearzy/constants/rest_api_const.dart';
import 'package:nearzy/data/models/auth_session.dart';
import 'package:nearzy/services/api_client.dart';
import 'package:nearzy/services/session_manager.dart';
import 'package:nearzy/utils/secure_storage.dart';

/// Seeded demo accounts — see backend/src/seed.js.
const _customerEmail = 'aarav@nearzy.com';
const _shopEmail = 'kashmir.shawls@nearzy.com';
const _password = 'Test@1234';

Future<bool> _backendIsUp() async {
  try {
    final response = await http
        .get(Uri.parse('${ApiConst.baseApiUrl}/health'))
        .timeout(const Duration(seconds: 3));
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

Future<String> _login(String url, String email) async {
  final response = await http.post(
    Uri.parse(url),
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': _password}),
  );
  expect(
    response.statusCode,
    200,
    reason: 'login for $email failed: ${response.body}',
  );
  return response.body;
}

/// Empties the singleton between tests. The manager is deliberately a
/// singleton in the app, so a test has to reset it through its own API.
Future<void> _clearSessions() async {
  FlutterSecureStorage.setMockInitialValues({});
  await SessionManager.instance.reloadForTesting();
}

// `main` is async because every `skip:` below is evaluated while the tests are
// being *registered*, which happens before any `setUpAll` callback runs. Probing
// the backend in `setUpAll` therefore read the flag before it was assigned and
// the whole file failed to load with a LateInitializationError — so the suite
// that was written to skip itself politely instead took the run down with it.
Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final live = await _backendIsUp();
  if (!live) {
    // ignore: avoid_print
    print('Backend not reachable at ${ApiConst.baseApiUrl} — skipping.');
  }

  setUp(() async {
    if (live) await _clearSessions();
  });

  test(
    'login issues an access token and a refresh token',
    () async {
      final body = await _login(ApiConst.customerLoginUrl, _customerEmail);
      final session = AuthSession.tryParse(body)!;

      expect(session.accessToken, isNotEmpty);
      expect(session.refreshToken, isNotEmpty);
      expect(session.canRefresh, isTrue);
      expect(session.isExpired, isFalse);
    },
    skip: !live ? 'backend not running' : null,
  );

  test(
    'an authenticated call succeeds through NearzyHttp',
    () async {
      await SessionManager.instance.signIn(
        responseBody: await _login(ApiConst.customerLoginUrl, _customerEmail),
        fallbackRole: Roles.ROLE_CUSTOMER,
        email: _customerEmail,
      );

      final response = await NearzyHttp.postJson(
        Uri.parse(ApiConst.userProfileUrl),
        auth: true,
        json: const {},
      );
      expect(response.statusCode, 200, reason: response.body);
      expect(jsonDecode(response.body)['role'], 'ROLE_CUSTOMER');
    },
    skip: !live ? 'backend not running' : null,
  );

  test(
    'a rejected access token is refreshed and the call replayed',
    () async {
      final manager = SessionManager.instance;
      await manager.signIn(
        responseBody: await _login(ApiConst.customerLoginUrl, _customerEmail),
        fallbackRole: Roles.ROLE_CUSTOMER,
        email: _customerEmail,
      );
      final original = manager.active!.session.accessToken;

      // Corrupt the stored access token so the server rejects it, while leaving
      // the expiry in the future — the client believes it is good, so the only
      // way this call can succeed is the 401 retry path.
      await _replaceStoredAccessToken('not.a.valid.jwt');
      expect(manager.active!.session.accessToken, 'not.a.valid.jwt');

      final response = await NearzyHttp.postJson(
        Uri.parse(ApiConst.userProfileUrl),
        auth: true,
        json: const {},
      );

      expect(
        response.statusCode,
        200,
        reason:
            'the 401 should have been refreshed and retried: '
            '${response.body}',
      );
      expect(manager.active!.session.accessToken, isNot('not.a.valid.jwt'));
      expect(manager.active!.session.accessToken, isNot(original));
    },
    skip: !live ? 'backend not running' : null,
  );

  test(
    'an expired access token is renewed before the call goes out',
    () async {
      final manager = SessionManager.instance;
      await manager.signIn(
        responseBody: await _login(ApiConst.customerLoginUrl, _customerEmail),
        fallbackRole: Roles.ROLE_CUSTOMER,
        email: _customerEmail,
      );
      final original = manager.active!.session.accessToken;

      await _expireStoredSession();
      expect(manager.active!.session.isExpired, isTrue);

      final token = await manager.accessToken();
      expect(token, isNotNull);
      expect(token, isNot(original));
      expect(manager.active!.session.isExpired, isFalse);
    },
    skip: !live ? 'backend not running' : null,
  );

  test(
    'refresh tokens rotate, and a replay ends the session',
    () async {
      final manager = SessionManager.instance;
      await manager.signIn(
        responseBody: await _login(ApiConst.customerLoginUrl, _customerEmail),
        fallbackRole: Roles.ROLE_CUSTOMER,
        email: _customerEmail,
      );
      final spent = manager.active!.session.refreshToken;

      expect(await manager.refreshActive(), isTrue);
      expect(manager.active!.session.refreshToken, isNot(spent));

      // Replaying the spent token is what a stolen copy looks like. The server
      // burns the whole chain, and the client must end the session rather than
      // sit on tokens that will never work again.
      await _replaceStoredRefreshToken(spent);
      expect(await manager.refreshActive(), isFalse);
      expect(
        manager.isSignedIn,
        isFalse,
        reason: 'a reused refresh token must sign the account out',
      );
    },
    skip: !live ? 'backend not running' : null,
  );

  test(
    'concurrent calls on an expired token trigger exactly one refresh',
    () async {
      final manager = SessionManager.instance;
      await manager.signIn(
        responseBody: await _login(ApiConst.customerLoginUrl, _customerEmail),
        fallbackRole: Roles.ROLE_CUSTOMER,
        email: _customerEmail,
      );
      await _expireStoredSession();

      // Rotation makes a refresh race self-destructive: each winner invalidates
      // the others' tokens, so without single-flighting this signs the user out.
      final tokens = await Future.wait(
        List.generate(8, (_) => manager.accessToken()),
      );

      expect(tokens.every((t) => t != null), isTrue);
      expect(
        tokens.toSet().length,
        1,
        reason: 'all callers should share one refreshed token',
      );
      expect(manager.isSignedIn, isTrue);
    },
    skip: !live ? 'backend not running' : null,
  );

  test(
    'two accounts stay signed in and switching needs no password',
    () async {
      final manager = SessionManager.instance;

      await manager.signIn(
        responseBody: await _login(ApiConst.customerLoginUrl, _customerEmail),
        fallbackRole: Roles.ROLE_CUSTOMER,
        email: _customerEmail,
      );
      await manager.signIn(
        responseBody: await _login(ApiConst.shopLoginUrl, _shopEmail),
        fallbackRole: Roles.ROLE_SHOP,
        email: _shopEmail,
      );

      expect(manager.accounts.length, 2);
      expect(manager.active!.email, _shopEmail);
      expect(manager.active!.role, Roles.ROLE_SHOP);

      // Back to the customer, with no credentials involved.
      expect(await manager.switchTo(_customerEmail), isTrue);
      expect(manager.active!.email, _customerEmail);
      expect(manager.active!.role, Roles.ROLE_CUSTOMER);

      final profile = await NearzyHttp.postJson(
        Uri.parse(ApiConst.userProfileUrl),
        auth: true,
        json: const {},
      );
      expect(jsonDecode(profile.body)['role'], 'ROLE_CUSTOMER');

      // And the shop is still there, still signed in.
      expect(await manager.switchTo(_shopEmail), isTrue);
      final shopProfile = await NearzyHttp.postJson(
        Uri.parse(ApiConst.userProfileUrl),
        auth: true,
        json: const {},
      );
      expect(jsonDecode(shopProfile.body)['role'], 'ROLE_SHOP');
    },
    skip: !live ? 'backend not running' : null,
  );

  test(
    'signing out drops only that account and activates the other',
    () async {
      final manager = SessionManager.instance;
      await manager.signIn(
        responseBody: await _login(ApiConst.customerLoginUrl, _customerEmail),
        fallbackRole: Roles.ROLE_CUSTOMER,
        email: _customerEmail,
      );
      await manager.signIn(
        responseBody: await _login(ApiConst.shopLoginUrl, _shopEmail),
        fallbackRole: Roles.ROLE_SHOP,
        email: _shopEmail,
      );

      await manager.signOutActive();

      expect(manager.accounts.length, 1);
      expect(manager.active!.email, _customerEmail);
      expect(await manager.accessToken(), isNotNull);
    },
    skip: !live ? 'backend not running' : null,
  );

  test(
    'sign-out revokes the refresh token server-side',
    () async {
      final manager = SessionManager.instance;
      await manager.signIn(
        responseBody: await _login(ApiConst.customerLoginUrl, _customerEmail),
        fallbackRole: Roles.ROLE_CUSTOMER,
        email: _customerEmail,
      );
      final refreshToken = manager.active!.session.refreshToken;

      await manager.signOutActive();

      final replay = await http.post(
        Uri.parse(ApiConst.refreshTokenUrl),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      expect(replay.statusCode, 401, reason: replay.body);
    },
    skip: !live ? 'backend not running' : null,
  );

  test(
    'a session restored from a pre-refresh build survives a restart',
    () async {
      // Older builds stored a bare JWT under `jwt_token`. Launching the updated
      // app must adopt it rather than dump the user at a login screen.
      final legacyBody = await _login(
        ApiConst.customerLoginUrl,
        _customerEmail,
      );
      final legacyToken = AuthSession.tryParse(legacyBody)!.accessToken;

      FlutterSecureStorage.setMockInitialValues({'jwt_token': legacyToken});
      final manager = await _freshManagerState();

      expect(manager.isSignedIn, isTrue);
      expect(manager.active!.email, _customerEmail);
      expect(manager.active!.role, Roles.ROLE_CUSTOMER);
      // Nothing to renew it with, so it lasts only until the token lapses.
      expect(manager.active!.session.canRefresh, isFalse);

      final response = await NearzyHttp.postJson(
        Uri.parse(ApiConst.userProfileUrl),
        auth: true,
        json: const {},
      );
      expect(response.statusCode, 200, reason: response.body);
    },
    skip: !live ? 'backend not running' : null,
  );
}

// ── Storage surgery ───────────────────────────────────────────────────────
//
// SessionManager deliberately exposes no setter for a token: the whole point
// is that only it writes them. These helpers reach past that through storage
// and reload, which is also exactly how a real restart sees the data.

Future<Map<String, dynamic>> _storedState() async {
  final raw = await SecureStorage.getData(key: 'nearzy_accounts');
  return Map<String, dynamic>.from(jsonDecode(raw!));
}

Future<SessionManager> _freshManagerState() async {
  final manager = SessionManager.instance;
  // Force a reload from storage by driving it through the public API.
  await manager.reloadForTesting();
  return manager;
}

Future<void> _mutateActiveSession(
  Map<String, dynamic> Function(Map<String, dynamic>) change,
) async {
  final state = await _storedState();
  final accounts = (state['accounts'] as List).cast<Map<String, dynamic>>();
  final active = accounts.firstWhere((a) => a['email'] == state['active']);
  active['session'] = change(Map<String, dynamic>.from(active['session']));
  await SecureStorage.storeData(
    key: 'nearzy_accounts',
    value: jsonEncode(state),
  );
  await SessionManager.instance.reloadForTesting();
}

Future<void> _replaceStoredAccessToken(String token) =>
    _mutateActiveSession((session) => {...session, 'accessToken': token});

Future<void> _replaceStoredRefreshToken(String token) =>
    _mutateActiveSession((session) => {...session, 'refreshToken': token});

Future<void> _expireStoredSession() => _mutateActiveSession(
  (session) => {
    ...session,
    'expiresAt': DateTime.now()
        .subtract(const Duration(minutes: 1))
        .toIso8601String(),
  },
);
