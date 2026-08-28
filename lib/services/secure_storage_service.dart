import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles all sensitive data storage using device Keystore (Android)
/// and Keychain (iOS). Replaces plaintext SharedPreferences for credentials.
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Storage keys
  static const String _keyToken = 'auth_token';
  static const String _keyIsLoggedIn = 'is_logged_in';

  // ── Write ──────────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<void> setLoggedIn(bool value) async {
    await _storage.write(key: _keyIsLoggedIn, value: value.toString());
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<bool> isLoggedIn() async {
    final value = await _storage.read(key: _keyIsLoggedIn);
    return value == 'true';
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  /// Call this on logout to wipe all secure credentials.
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
