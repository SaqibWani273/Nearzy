// Unit tests for the pieces the refresh flow turns on: reading a session out
// of whatever the server sent, and knowing when it has gone stale.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mca_project/constants/bottom_navbar_items.dart';
import 'package:mca_project/data/models/auth_session.dart';

void main() {
  group('AuthSession.tryParse', () {
    test('reads the current login shape', () {
      final session = AuthSession.tryParse(jsonEncode({
        'token': 'access-jwt',
        'accessToken': 'access-jwt',
        'refreshToken': 'refresh-opaque',
        'expiresIn': 3600,
        'role': 'ROLE_CUSTOMER',
      }))!;

      expect(session.accessToken, 'access-jwt');
      expect(session.refreshToken, 'refresh-opaque');
      expect(session.canRefresh, isTrue);
      expect(session.isExpired, isFalse);
      expect(
        session.expiresAt.difference(DateTime.now()).inMinutes,
        closeTo(60, 1),
      );
    });

    test('falls back to expiresAt when expiresIn is absent', () {
      final at = DateTime.now().add(const Duration(hours: 5));
      final session = AuthSession.tryParse(jsonEncode({
        'accessToken': 'a',
        'refreshToken': 'r',
        'expiresAt': at.toIso8601String(),
      }))!;
      expect(session.expiresAt.difference(at).inSeconds.abs(), lessThan(2));
    });

    // The old endpoint answered `res.json(token)`, so the body arrived as a
    // quoted JSON string. An app updated in place must still read it rather
    // than signing everyone out on first launch.
    test('reads a legacy quoted-string body', () {
      final session = AuthSession.tryParse('"just-a-jwt"')!;
      expect(session.accessToken, 'just-a-jwt');
      expect(session.canRefresh, isFalse);
    });

    test('reads a bare token body', () {
      final session = AuthSession.tryParse('  bare.jwt.value  ')!;
      expect(session.accessToken, 'bare.jwt.value');
      expect(session.canRefresh, isFalse);
    });

    test('rejects a body with no token', () {
      expect(AuthSession.tryParse(''), isNull);
      expect(AuthSession.tryParse('{}'), isNull);
      expect(AuthSession.tryParse('{"message":"Invalid credentials"}'), isNull);
    });
  });

  group('expiry', () {
    test('a token inside the safety margin counts as expired', () {
      final session = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        // Inside the 30s skew: renew now rather than let it lapse in flight.
        expiresAt: DateTime.now().add(const Duration(seconds: 10)),
      );
      expect(session.isExpired, isTrue);
    });

    test('a comfortably live token does not', () {
      final session = AuthSession(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );
      expect(session.isExpired, isFalse);
    });
  });

  group('rolesFromWire', () {
    test('collapses both shop spellings onto one role', () {
      // Shops registered in-app are SHOP_OWNER, seeded ones are SHOP. Before
      // this, an app-registered shop failed the role check on /user/me and was
      // dropped back to the login form.
      expect(rolesFromWire('ROLE_SHOP'), Roles.ROLE_SHOP);
      expect(rolesFromWire('ROLE_SHOP_OWNER'), Roles.ROLE_SHOP);
      expect(rolesFromWire('SHOP_OWNER'), Roles.ROLE_SHOP);
    });

    test('maps customers and admins', () {
      expect(rolesFromWire('ROLE_CUSTOMER'), Roles.ROLE_CUSTOMER);
      expect(rolesFromWire('ROLE_ADMIN'), Roles.ROLE_ADMIN);
    });

    test('returns null for anything unrecognised', () {
      expect(rolesFromWire(null), isNull);
      expect(rolesFromWire('ROLE_WHATEVER'), isNull);
    });
  });

  group('StoredAccount', () {
    StoredAccount account({required AuthSession session}) => StoredAccount(
          email: 'kashmir.shawls@nearzy.com',
          displayName: 'Kashmir Shawl House',
          role: Roles.ROLE_SHOP,
          session: session,
          lastUsedAt: DateTime.now(),
        );

    test('needs re-auth only when it is both expired and unrenewable', () {
      final dead = account(
        session: AuthSession(
          accessToken: 'a',
          refreshToken: '',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );
      final renewable = account(
        session: AuthSession(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );
      expect(dead.needsReauth, isTrue);
      expect(renewable.needsReauth, isFalse);
    });

    test('survives a storage round trip', () {
      final original = account(
        session: AuthSession(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );
      final restored =
          StoredAccount.tryFromJson(jsonDecode(jsonEncode(original.toJson())))!;

      expect(restored.email, original.email);
      expect(restored.displayName, original.displayName);
      expect(restored.role, Roles.ROLE_SHOP);
      expect(restored.session.refreshToken, 'r');
    });

    test('builds initials for the fallback avatar', () {
      expect(account(session: AuthSession(
        accessToken: 'a', refreshToken: 'r', expiresAt: DateTime.now(),
      )).initials, 'KS');
    });
  });
}
