import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = const FlutterSecureStorage();

class SecureStorage {
  static Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  static Future<void> storeToken(String token) async {
    await storage.write(key: 'jwt_token', value: token);
  }

  static Future<void> deleteToken() async {
    await storage.delete(key: 'jwt_token');
  }
}
