import 'dart:html' as html;

class WebStorageHelper {
  static void write(String key, String value) {
    try {
      html.window.localStorage[key] = value;
    } catch (_) {}
  }

  static String? read(String key) {
    try {
      return html.window.localStorage[key];
    } catch (_) {
      return null;
    }
  }

  static void delete(String key) {
    try {
      html.window.localStorage.remove(key);
    } catch (_) {}
  }
}
