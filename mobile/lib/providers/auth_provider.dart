import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/auth_service_shared.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  static const _storage = FlutterSecureStorage();

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: dotenv.env['GoogleAuthSettings__GoogleClientIds__Web'],
    scopes: ['email', 'profile'],
  );

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
    _errorMessage = raw.isNotEmpty ? raw : 'Đã xảy ra lỗi không xác định.';
  }

  void _clearError() => _errorMessage = null;

  /// Lưu cặp access + refresh token vào SecureStorage.
  Future<void> _saveTokens(Map<String, dynamic> response) async {
    final accessToken = response['accessToken'] as String?;
    final refreshToken = response['refreshToken'] as String?;

    if (accessToken == null) throw Exception('Phản hồi thiếu access token.');

    await Future.wait([
      _storage.write(key: 'access_token', value: accessToken),
      if (refreshToken != null)
        _storage.write(key: 'refresh_token', value: refreshToken),
    ]);
  }

  // ─── Public methods ───────────────────────────────────────────────────────

  /// Kiểm tra trạng thái đăng nhập khi khởi động app.
  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null || token.isEmpty) {
      _isAuthenticated = false;
      notifyListeners();
      return;
    }

    if (!_isJwtExpired(token)) {
      _isAuthenticated = true;
      notifyListeners();
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
      // Đảm bảo sign out trước để tránh cache account cũ
      await _googleSignIn.signOut();

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
      final storedRefresh = await _storage.read(key: 'refresh_token');
      if (storedRefresh == null) return false;

      final response = await _authService.refreshToken(storedRefresh);
      await _saveTokens(response);
      _isAuthenticated = true;
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
      final storedRefresh = await _storage.read(key: 'refresh_token');
      if (storedRefresh != null) {
        await _authService.logout(storedRefresh);
      }
      // Sign out Google nếu đang đăng nhập bằng Google
      await _googleSignIn.signOut();
    } catch (_) {
      // Server-side logout thất bại → vẫn xóa local token
    } finally {
      await Future.wait([
        _storage.delete(key: 'access_token'),
        _storage.delete(key: 'refresh_token'),
      ]);
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return true;
      }

      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
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
