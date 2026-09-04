import 'dart:convert';

import '../../constants/bottom_navbar_items.dart';

/// Normalises whatever the server calls a role into the app's [Roles] enum.
///
/// Shops registered through the app are stored as `SHOP_OWNER` while the
/// seeded ones are `SHOP`, and both reach the client as a `ROLE_` claim. They
/// are the same thing to every screen here, so they collapse to one value —
/// previously an app-registered shop failed the `== 'ROLE_SHOP'` comparison
/// and was dropped straight back to the login form.
Roles? rolesFromWire(String? wire) {
  switch (wire) {
    case 'ROLE_CUSTOMER':
    case 'CUSTOMER':
      return Roles.ROLE_CUSTOMER;
    case 'ROLE_SHOP':
    case 'ROLE_SHOP_OWNER':
    case 'SHOP':
    case 'SHOP_OWNER':
      return Roles.ROLE_SHOP;
    case 'ROLE_ADMIN':
    case 'ADMIN':
      return Roles.ROLE_ADMIN;
    default:
      return null;
  }
}

/// One account's live credentials.
///
/// The access token is short-lived and the refresh token is single-use: the
/// server rotates it on every refresh, so whatever comes back must replace
/// what was sent or the next refresh is rejected as a replay.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;

  /// Empty for sessions restored from a build that predates refresh tokens.
  /// Those cannot be renewed, so they end at [expiresAt] with a sign-in prompt.
  final String refreshToken;

  final DateTime expiresAt;

  bool get canRefresh => refreshToken.isNotEmpty;

  /// Treated as expired a little early, so a token cannot lapse in flight
  /// between the check and the server receiving the request.
  bool get isExpired => DateTime.now().isAfter(
        expiresAt.subtract(const Duration(seconds: 30)),
      );

  /// Builds a session from a `/login` or `/user/refresh` body.
  ///
  /// Tolerates the pre-refresh shape — a bare JWT string, or `{"token": ...}`
  /// with no expiry — so an app updated in place doesn't strand a signed-in
  /// user on a response it can't read.
  static AuthSession? tryParse(String responseBody) {
    dynamic decoded;
    try {
      decoded = jsonDecode(responseBody.trim());
    } on FormatException {
      // A bare JWT is not valid JSON but is a perfectly good access token.
      final bare = responseBody.trim();
      return bare.isEmpty ? null : AuthSession._legacy(bare);
    }

    if (decoded is String) {
      final bare = decoded.trim();
      return bare.isEmpty ? null : AuthSession._legacy(bare);
    }

    if (decoded is! Map) return null;
    final access = (decoded['accessToken'] ?? decoded['token']) as String?;
    if (access == null || access.isEmpty) return null;

    final expiresIn = decoded['expiresIn'];
    return AuthSession(
      accessToken: access,
      refreshToken: (decoded['refreshToken'] as String?) ?? '',
      expiresAt: expiresIn is num
          ? DateTime.now().add(Duration(seconds: expiresIn.toInt()))
          : DateTime.tryParse('${decoded['expiresAt']}') ??
              DateTime.now().add(const Duration(hours: 1)),
    );
  }

  /// A token with no refresh half and no stated lifetime. The optimistic hour
  /// only decides when to *try* renewing; a 401 settles it either way.
  factory AuthSession._legacy(String accessToken) => AuthSession(
        accessToken: accessToken,
        refreshToken: '',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        expiresAt: DateTime.tryParse('${json['expiresAt']}') ?? DateTime.now(),
      );
}

/// An account the device has signed into, kept so it can be switched back to
/// without retyping a password.
class StoredAccount {
  const StoredAccount({
    required this.email,
    required this.displayName,
    required this.role,
    required this.session,
    required this.lastUsedAt,
    this.avatarUrl,
  });

  final String email;
  final String displayName;
  final Roles role;
  final AuthSession session;
  final DateTime lastUsedAt;
  final String? avatarUrl;

  /// True once the tokens can no longer be renewed silently. The switcher
  /// still lists the account — it just asks for the password on the way in.
  bool get needsReauth => session.isExpired && !session.canRefresh;

  String get roleLabel => switch (role) {
        Roles.ROLE_CUSTOMER => 'Customer',
        Roles.ROLE_SHOP => 'Shop',
        Roles.ROLE_ADMIN => 'Admin',
      };

  /// Two letters for the fallback avatar, from the display name or the email.
  String get initials {
    final source = displayName.trim().isNotEmpty ? displayName.trim() : email;
    final words = source
        .replaceAll(RegExp(r'[._@-]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      return words.first.substring(0, words.first.length >= 2 ? 2 : 1);
    }
    return '${words[0][0]}${words[1][0]}';
  }

  StoredAccount copyWith({
    String? displayName,
    Roles? role,
    AuthSession? session,
    DateTime? lastUsedAt,
    String? avatarUrl,
  }) =>
      StoredAccount(
        email: email,
        displayName: displayName ?? this.displayName,
        role: role ?? this.role,
        session: session ?? this.session,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );

  Map<String, dynamic> toJson() => {
        'email': email,
        'displayName': displayName,
        'role': role.name,
        'session': session.toJson(),
        'lastUsedAt': lastUsedAt.toIso8601String(),
        'avatarUrl': avatarUrl,
      };

  static StoredAccount? tryFromJson(Map<String, dynamic> json) {
    final email = json['email'] as String?;
    final role = rolesFromWire(json['role'] as String?);
    final rawSession = json['session'];
    if (email == null || role == null || rawSession is! Map) return null;
    return StoredAccount(
      email: email,
      displayName: json['displayName'] as String? ?? email,
      role: role,
      session: AuthSession.fromJson(Map<String, dynamic>.from(rawSession)),
      lastUsedAt:
          DateTime.tryParse('${json['lastUsedAt']}') ?? DateTime.now(),
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
