import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

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
