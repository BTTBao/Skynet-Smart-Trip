import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../services/auth_service_shared.dart';
import '../services/fcm_service.dart';
import '../services/secure_storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: kIsWeb ? null : _googleWebClientId,
    clientId: kIsWeb ? _googleWebClientId : null,
  );

  static String? get _googleWebClientId {
    final value =
        dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
        dotenv.env['GoogleAuthSettings__GoogleClientIds__Web'];

    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Exposed getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Internal helpers ────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(dynamic e) {
    // Strip default "Exception: " prefix Dart adds
    final raw = e.toString().replaceFirst('Exception: ', '');

    if (raw.contains('network_error') && raw.contains('Api7')) {
      _errorMessage =
          'Google Sign-In chua ket noi duoc. Kiem tra emulator co Google Play Services, da dang nhap tai khoan Google, va OAuth Android client dung package com.skynet.mobile voi SHA-1 debug 9B:D1:34:7F:B5:85:0D:0A:94:34:AA:34:76:4F:79:B3:94:BB:B1:ED.';
      return;
    }

    if (raw.contains('sign_in_failed') ||
        raw.contains('DEVELOPER_ERROR') ||
        raw.contains('Api10')) {
      _errorMessage =
          'Loi cau hinh Google Sign-In. Firebase/Google Cloud can co Android OAuth client cho package com.skynet.mobile voi SHA-1 debug 9B:D1:34:7F:B5:85:0D:0A:94:34:AA:34:76:4F:79:B3:94:BB:B1:ED, va Web client ID phai trung voi GoogleAuthSettings__GoogleClientIds__Web.';
      return;
    }

    if (raw.contains('network_error') && raw.contains('Api7')) {
      _errorMessage =
          'Google Sign-In chưa kết nối được. Hãy kiểm tra máy ảo có Google Play Services, đã đăng nhập tài khoản Google, và OAuth Android client khớp package com.skynet.mobile với SHA-1 debug.';
    } else if (raw.contains('sign_in_failed') ||
        raw.contains('DEVELOPER_ERROR') ||
        raw.contains('Api10')) {
      _errorMessage =
          'Lỗi cấu hình Cụm Google Sign-In. Vui lòng kiểm tra lại cấu hình SHA-1, Client ID hoặc file google-services.json.';
    } else {
      _errorMessage = raw.isNotEmpty ? raw : 'Đã xảy ra lỗi không xác định.';
    }
  }

  void _clearError() => _errorMessage = null;

  /// Lưu cặp access + refresh token vào SecureStorage.
  Future<void> _saveTokens(Map<String, dynamic> response) async {
    final accessToken = response['accessToken'] as String?;
    final refreshToken = response['refreshToken'] as String?;

    if (accessToken == null) throw Exception('Phản hồi thiếu access token.');

    await Future.wait([
      SecureStorageService.write(key: 'access_token', value: accessToken),
      if (refreshToken != null)
        SecureStorageService.write(key: 'refresh_token', value: refreshToken),
    ]);
  }

  // ─── Public methods ───────────────────────────────────────────────────────

  /// Kiểm tra trạng thái đăng nhập khi khởi động app.
  Future<void> checkAuthStatus() async {
    final token = await SecureStorageService.read('access_token');
    if (token == null || token.isEmpty) {
      _isAuthenticated = false;
      notifyListeners();
      return;
    }

    if (!_isJwtExpired(token)) {
      final isSessionValid = await _authService.validateSession();
      if (isSessionValid) {
        _isAuthenticated = true;
        await FcmService.instance.registerCurrentToken();
        notifyListeners();
        return;
      }

      await _clearLocalSession();
      return;
    }

    final refreshed = await refreshToken();
    if (!refreshed) {
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  /// Đăng nhập bằng email hoặc username + password.
  Future<bool> login(String identifier, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(identifier, password);
      await _saveTokens(response);
      _isAuthenticated = true;
      await FcmService.instance.registerCurrentToken();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Đăng nhập bằng Google — lấy idToken từ Google Sign-In rồi gửi lên backend.
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      // Best-effort cleanup; do not fail login if Google Play Services cannot
      // complete a cached sign-out call.
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Người dùng huỷ Google Sign-In
        _setLoading(false);
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception('Không lấy được idToken từ Google.');
      }

      final response = await _authService.loginWithGoogle(idToken);
      await _saveTokens(response);
      _isAuthenticated = true;
      await FcmService.instance.registerCurrentToken();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Đăng ký tài khoản mới.
  Future<bool> register(
    String fullName,
    String username,
    String email,
    String password,
    String phone,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.register(fullName, username, email, password, phone);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Xác thực OTP đăng ký.
  Future<bool> verifyOtp(String email, String otp) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.verifyEmail(email, otp);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Gửi email khôi phục mật khẩu.
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.forgotPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Làm mới access token bằng refresh token đang lưu.
  Future<bool> refreshToken() async {
    try {
      final storedRefresh = await SecureStorageService.read('refresh_token');
      if (storedRefresh == null) return false;

      final response = await _authService.refreshToken(storedRefresh);
      await _saveTokens(response);
      _isAuthenticated = true;
      await FcmService.instance.registerCurrentToken();
      notifyListeners();
      return true;
    } catch (e) {
      // Refresh thất bại → buộc logout
      await logout();
      return false;
    }
  }

  /// Đăng xuất — xóa token local và revoke trên server.
  Future<void> logout() async {
    try {
      final storedRefresh = await SecureStorageService.read('refresh_token');
      await FcmService.instance.unregisterCurrentToken();
      if (storedRefresh != null) {
        await _authService.logout(storedRefresh);
      }
    } catch (_) {
      // Server-side logout thất bại → vẫn xóa local token
    } finally {
      await SecureStorageService.deleteAuthTokens();
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  Future<void> _clearLocalSession() async {
    await SecureStorageService.deleteAuthTokens();
    _isAuthenticated = false;
    notifyListeners();
  }

  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return true;
      }

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload) as Map<String, dynamic>;
      final exp = claims['exp'];
      if (exp is! num) {
        return true;
      }

      final expiry = DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );

      return DateTime.now().toUtc().isAfter(
        expiry.subtract(const Duration(seconds: 30)),
      );
    } catch (_) {
      return true;
    }
  }
}
