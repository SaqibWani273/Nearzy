// The login endpoints answer a failure with `res.status(400).json(<string>)`,
// so the bodies asserted here are verbatim what the backend sends — quotes
// included. Three screens used to render them as-is.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearzy/constants/bottom_navbar_items.dart';
import 'package:nearzy/utils/auth_error.dart';

String forCustomer(int code, String body) =>
    authErrorMessage(statusCode: code, body: body, role: Roles.ROLE_CUSTOMER);

void main() {
  group('authErrorMessage', () {
    test('never leaks the raw JSON-quoted body', () {
      for (final body in const [
        '"Email Not Registered"',
        '"Email not verified"',
        '"Invalid credentials"',
        '"Not a shop user"',
        '"Invalid Admin credentials"',
      ]) {
        for (final role in Roles.values) {
          final message =
              authErrorMessage(statusCode: 400, body: body, role: role);
          expect(message, isNot(contains('"')));
          expect(message, isNot(contains('Status Code')));
          expect(message.endsWith('.'), isTrue, reason: message);
        }
      }
    });

    test('an unregistered email is named as such, per role', () {
      const body = '"Email Not Registered"';
      expect(forCustomer(400, body), contains('create an account'));
      expect(
        authErrorMessage(statusCode: 400, body: body, role: Roles.ROLE_SHOP),
        contains('register your shop'),
      );
    });

    test('an unverified email points at the emailed link', () {
      expect(forCustomer(400, '"Email not verified"'),
          contains('Open the link we emailed you'));
    });

    test('a wrong password says so without saying which half', () {
      final message = forCustomer(400, '"Invalid credentials"');
      expect(message, contains('do not match'));
      // Naming which of the two was wrong is an account-enumeration hint.
      expect(message.toLowerCase(), isNot(contains('password is wrong')));
    });

    test('a shop signing in on a customer account is told where to go', () {
      expect(
        authErrorMessage(
            statusCode: 400, body: '"Not a shop user"', role: Roles.ROLE_SHOP),
        contains('Sign in as a customer'),
      );
    });

    test('a non-admin account is told it lacks access', () {
      expect(
        authErrorMessage(
          statusCode: 400,
          body: '"Invalid Admin credentials"',
          role: Roles.ROLE_ADMIN,
        ),
        contains('does not have admin access'),
      );
    });

    test('reads an error envelope as well as a bare string', () {
      expect(forCustomer(400, '{"message":"Invalid credentials"}'),
          contains('do not match'));
      expect(forCustomer(400, '{"error":"Email not verified"}'),
          contains('Open the link'));
    });

    test('falls back on the status code when the body is unusable', () {
      // ngrok's interstitial and any proxy error page arrive as HTML.
      expect(forCustomer(503, '<html><body>Bad gateway</body></html>'),
          contains('could not be reached'));
      expect(forCustomer(401, ''), contains('do not match'));
      expect(forCustomer(429, ''), contains('Too many attempts'));
    });

    test('an unrecognised 400 still reads as advice', () {
      final message = forCustomer(400, '"something nobody has mapped"');
      expect(message, 'We could not sign you in. Please check your details '
          'and try again.');
    });
  });

  group('authErrorFromException', () {
    test('a dropped connection is reported as one', () {
      for (final error in <Object>[
        const SocketException('Connection refused'),
        const HttpException('broken'),
        TimeoutException('slow'),
      ]) {
        expect(authErrorFromException(error), contains('No connection'));
      }
    });

    test('keeps a message already written for a person', () {
      expect(
        authErrorFromException(StateError('x'),
            fallbackMessage: 'Your session has ended.'),
        'Your session has ended.',
      );
    });

    test('a bare error object never reaches the screen', () {
      final message = authErrorFromException(
        StateError('Bad state: no element'),
      );
      expect(message, isNot(contains('Bad state')));
      expect(message, isNot(contains('!!!')));
    });
  });

  group('signUpErrorMessage', () {
    test('a taken email offers signing in instead', () {
      expect(
        signUpErrorMessage(
          statusCode: 400,
          body: '"Email already exists"',
          role: Roles.ROLE_CUSTOMER,
        ),
        contains('Sign in instead'),
      );
    });

    test('a taken name is worded for whoever is registering', () {
      expect(
        signUpErrorMessage(
          statusCode: 400,
          body: '"Username already exists"',
          role: Roles.ROLE_SHOP,
        ),
        contains('A shop already uses that name'),
      );
    });
  });
}
