import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_settings.dart';
import '../utils/app_currency_formatter.dart';

class AppSettingsProvider with ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _themeKey = 'app_theme_mode';
  static const _languageKey = 'app_language';
  static const _currencyKey = 'app_currency';

  ThemeMode _themeMode = ThemeMode.light;
  String _languageCode = 'vi';
  String _currencyCode = 'VND';
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;
  String get currencyCode => _currencyCode;
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isEnglish => _languageCode == 'en';
  Locale get locale => Locale(_languageCode);

  Future<void> initialize() async {
    final storedTheme = await _storage.read(key: _themeKey);
    final storedLanguage = await _storage.read(key: _languageKey);
    final storedCurrency = await _storage.read(key: _currencyKey);

    if (storedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }

    if (storedLanguage == 'en' || storedLanguage == 'vi') {
      _languageCode = storedLanguage!;
    }

    if (storedCurrency == 'USD' || storedCurrency == 'VND') {
      _currencyCode = storedCurrency!;
    }

    AppCurrencyFormatter.setCurrency(_currencyCode);
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> applyUserSettings(
    UserSettings settings, {
    bool persist = true,
  }) async {
    _themeMode = settings.darkModeEnabled ? ThemeMode.dark : ThemeMode.light;
    _languageCode = settings.language.toLowerCase() == 'en' ? 'en' : 'vi';
    _currencyCode = settings.currency.toUpperCase() == 'USD' ? 'USD' : 'VND';
    AppCurrencyFormatter.setCurrency(_currencyCode);

    if (persist) {
      await _persist();
    }

    notifyListeners();
  }

  Future<void> setThemeMode(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    await _persist();
    notifyListeners();
  }

  Future<void> setLanguageCode(String languageCode) async {
    _languageCode = languageCode.toLowerCase() == 'en' ? 'en' : 'vi';
    await _persist();
    notifyListeners();
  }

  Future<void> setCurrencyCode(String currencyCode) async {
    _currencyCode = currencyCode.toUpperCase() == 'USD' ? 'USD' : 'VND';
    AppCurrencyFormatter.setCurrency(_currencyCode);
    await _persist();
    notifyListeners();
  }

  String text({
    required String vi,
    required String en,
  }) {
    return isEnglish ? en : vi;
  }

  String formatCurrency(num amount) {
    return AppCurrencyFormatter.format(amount, currencyCode: _currencyCode);
  }

  Future<void> _persist() async {
    await Future.wait([
      _storage.write(
        key: _themeKey,
        value: _themeMode == ThemeMode.dark ? 'dark' : 'light',
      ),
      _storage.write(key: _languageKey, value: _languageCode),
      _storage.write(key: _currencyKey, value: _currencyCode),
    ]);
  }
}
