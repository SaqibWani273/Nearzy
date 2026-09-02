import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

class SecureStorage {
  static Future<String?> getToken() async {
    final stored = await storage.read(key: 'jwt_token');
    // Older builds persisted the raw response body, so a quoted token may
    // already be sitting in storage from a previous session.
    return stored == null ? null : normalizeToken(stored);
  }

  static Future<void> storeToken(String token) async {
    await storage.write(key: 'jwt_token', value: normalizeToken(token));
  }

  /// Unwraps a JWT from whatever shape the login endpoint returned it in.
  ///
  /// The backend answers `/login` with `res.json(token)`, so the body arrives
  /// as a *JSON string* — `"eyJhbGci..."`, surrounding quotes included. Stored
  /// verbatim that becomes `Authorization: Bearer "eyJ..."`, which no JWT
  /// parser accepts, so every authenticated call afterwards comes back 401.
  /// Normalising here — the choke point for customer, shop and admin login —
  /// also tolerates a bare token or a `{"token": ...}` body, so a change in
  /// the response shape can't silently break sign-in again.
  static String normalizeToken(String rawToken) {
    final trimmed = rawToken.trim();
    if (trimmed.isEmpty) return trimmed;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is String) return decoded.trim();
      if (decoded is Map && decoded['token'] is String) {
        return (decoded['token'] as String).trim();
      }
    } on FormatException {
      // A bare JWT isn't valid JSON — it's already in the right shape.
    }
    return trimmed;
  }

  static Future<void> deleteToken() async {
    await storage.delete(key: 'jwt_token');
  }

  static Future<String?> getData({required String key}) async {
    return await storage.read(key: key);
  }

  static Future<void> storeData(
      {required String key, required String value}) async {
    await storage.write(key: key, value: value);
  }

  static Future<void> deleteData({required String key}) async {
    await storage.delete(key: key);
  }
}
