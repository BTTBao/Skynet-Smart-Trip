import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'web_storage_stub.dart'
    if (dart.library.html) 'web_storage_web.dart'
    if (dart.library.io) 'web_storage_mobile.dart';

class AppStorage {
  static const _secureStorage = FlutterSecureStorage();

  static Future<void> write({required String key, required String value}) async {
    if (kIsWeb) {
      WebStorageHelper.write(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  static Future<String?> read({required String key}) async {
    if (kIsWeb) {
      return WebStorageHelper.read(key);
    } else {
      try {
        return await _secureStorage.read(key: key);
      } catch (_) {
        return null;
      }
    }
  }

  static Future<void> delete({required String key}) async {
    if (kIsWeb) {
      WebStorageHelper.delete(key);
    } else {
      try {
        await _secureStorage.delete(key: key);
      } catch (_) {}
    }
  }

  static Future<void> deleteAll() async {
    if (kIsWeb) {
      WebStorageHelper.delete('access_token');
      WebStorageHelper.delete('refresh_token');
      WebStorageHelper.delete('theme_mode');
      WebStorageHelper.delete('language');
      WebStorageHelper.delete('currency');
    } else {
      try {
        await _secureStorage.deleteAll();
      } catch (_) {}
    }
  }
}
