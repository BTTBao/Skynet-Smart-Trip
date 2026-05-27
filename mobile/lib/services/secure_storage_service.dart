import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const List<String> _authKeys = ['access_token', 'refresh_token'];

  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      await _recoverWebStorage();
      return null;
    }
  }

  static Future<void> write({
    required String key,
    required String value,
  }) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      await _recoverWebStorage();
      if (!kIsWeb) {
        rethrow;
      }

      try {
        await _storage.write(key: key, value: value);
      } catch (_) {
        // On web, a blocked/corrupted storage should not crash the app shell.
      }
    }
  }

  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      await _recoverWebStorage();
    }
  }

  static Future<void> deleteAuthTokens() async {
    await Future.wait(_authKeys.map(delete));
  }

  static Future<void> _recoverWebStorage() async {
    if (!kIsWeb) {
      return;
    }

    for (final key in _authKeys) {
      try {
        await _storage.delete(key: key);
      } catch (_) {}
    }
  }
}
