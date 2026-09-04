/// The single place that turns a failed sign-in into a sentence a person can
/// act on.
///
/// Every login endpoint answers a failure with `res.status(400).json(<string>)`,
/// so the raw body is a JSON-quoted phrase written for a server log —
/// `"Email Not Registered"`, quotes included. Three screens used to put that
/// straight on screen, which is what made a mistyped password look like a
/// crash. Nothing below the UI should ever hand a response body to a widget
/// again; it goes through here first.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../constants/bottom_navbar_items.dart';

/// Copy for a login that the server rejected.
///
/// [role] only changes the wording where the cause is role-specific — a shop
/// signing in on a customer account needs different advice than an admin does.
String authErrorMessage({
  required int statusCode,
  required String body,
  required Roles role,
}) {
  final reason = _unwrap(body).toLowerCase();

  // Ordered most specific first: "email not verified" also contains "email".
  if (reason.contains('not verified') || reason.contains('unverified')) {
    return 'This email has not been verified yet. Open the link we emailed '
        'you, then sign in again.';
  }
  if (reason.contains('not registered') ||
      reason.contains('no user') ||
      reason.contains('not found')) {
    return switch (role) {
      Roles.ROLE_CUSTOMER =>
        'No Nearzy account uses that email. Check the spelling, or create an '
            'account below.',
      Roles.ROLE_SHOP =>
        'No shop is registered with that email. Check the spelling, or '
            'register your shop below.',
      Roles.ROLE_ADMIN => 'No Nearzy account uses that email.',
    };
  }
  if (reason.contains('not a shop') || reason.contains('admin credentials')) {
    return switch (role) {
      Roles.ROLE_SHOP =>
        'That account is not a shop account. Sign in as a customer instead, '
            'or register your shop below.',
      Roles.ROLE_ADMIN => 'That account does not have admin access.',
      Roles.ROLE_CUSTOMER => 'That account cannot be used to sign in here.',
    };
  }
  if (reason.contains('invalid credentials') ||
      reason.contains('wrong password') ||
      reason.contains('not valid credentials')) {
    return 'That email and password do not match. Check both and try again.';
  }
  if (reason.contains('password is required')) {
    return 'Please fill in both your email and your password.';
  }

  // Fall back on the status code, which is reliable even when the body is not.
  if (statusCode == 401 || statusCode == 403) {
    return 'That email and password do not match. Check both and try again.';
  }
  if (statusCode == 429) {
    return 'Too many attempts. Wait a minute, then try again.';
  }
  if (statusCode >= 500) {
    return 'Nearzy could not be reached just now. Please try again in a '
        'moment.';
  }
  return 'We could not sign you in. Please check your details and try again.';
}

/// Copy for a sign-in that never reached an answer — no network, DNS failure,
/// a timeout, or an unreadable response.
///
/// Only raw platform errors are turned into copy here — anything already
/// carrying a message written for a person passes its own message in as
/// [fallbackMessage]. `SocketException: Connection refused (OS Error...)` is
/// not something a customer can act on.
String authErrorFromException(Object error, {String? fallbackMessage}) {
  if (error is SocketException ||
      error is HttpException ||
      error is TimeoutException) {
    return 'No connection to Nearzy. Check your internet and try again.';
  }
  if (error is FormatException) {
    return 'Nearzy sent back something unexpected. Please try again.';
  }
  return fallbackMessage ??
      'Something went wrong signing you in. Please try again.';
}

/// Peels the server's phrasing out of a response body.
///
/// Handles all three shapes the backend produces: a bare JSON string, an
/// error envelope (`{"message": ...}` / `{"error": ...}`), and unparsable
/// text — an HTML error page from a proxy, say.
String _unwrap(String body) {
  final trimmed = body.trim();
  if (trimmed.isEmpty) return '';

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is String) return decoded;
    if (decoded is Map) {
      for (final key in const ['message', 'error', 'detail']) {
        final value = decoded[key];
        if (value is String && value.isNotEmpty) return value;
      }
    }
  } on FormatException {
    // Not JSON. An HTML page tells the user nothing, so keep it out of the
    // matcher by only trusting short, plain-text bodies.
    if (trimmed.startsWith('<') || trimmed.length > 160) return '';
  }
  return trimmed;
}

/// Copy for a registration the server rejected.
///
/// Split from [authErrorMessage] because the causes barely overlap: nobody
/// mistypes a password into "email already exists", and the advice differs.
String signUpErrorMessage({
  required int statusCode,
  required String body,
  required Roles role,
}) {
  final reason = _unwrap(body).toLowerCase();

  if (reason.contains('email already')) {
    return 'That email is already registered. Sign in instead, or use '
        'another address.';
  }
  if (reason.contains('username already')) {
    return switch (role) {
      Roles.ROLE_SHOP => 'A shop already uses that name. Try another.',
      _ => 'That name is already taken. Try another.',
    };
  }
  if (reason.contains('password is required')) {
    return 'Please choose a password of at least 6 characters.';
  }
  if (statusCode >= 500) {
    return 'Nearzy could not be reached just now. Please try again in a '
        'moment.';
  }
  return switch (role) {
    Roles.ROLE_SHOP =>
      'We could not register your shop. Check the details above and try '
          'again.',
    _ => 'We could not create your account. Check your details and try again.',
  };
}
