import 'package:flutter/foundation.dart';

import '../utils/app_storage.dart';

class SecureStorageService {
  static const List<String> _authKeys = ['access_token', 'refresh_token'];

  static Future<String?> read(String key) async {
    try {
      return await AppStorage.read(key: key);
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
      await AppStorage.write(key: key, value: value);
    } catch (_) {
      await _recoverWebStorage();
      if (!kIsWeb) {
        rethrow;
      }
    }
  }

  static Future<void> delete(String key) async {
    try {
      await AppStorage.delete(key: key);
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
        await AppStorage.delete(key: key);
      } catch (_) {}
    }
  }
}
