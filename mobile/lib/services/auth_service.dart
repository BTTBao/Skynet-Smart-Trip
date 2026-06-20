import 'dart:convert';

import 'api_service_base.dart';

class AuthService extends ApiService {
  /// Đăng nhập — trả về accessToken + refreshToken + expiresIn
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await postWithFallback(
      '/auth/login',
      body: jsonEncode({'email': email, 'password': password}),
    );
    return handleResponse(response) as Map<String, dynamic>;
  }

  /// Đăng ký tài khoản mới
  Future<Map<String, dynamic>> register(
    String fullName,
    String email,
    String password,
    String phone,
  ) async {
    final response = await postWithFallback(
      '/auth/register',
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'phone': phone,
      }),
    );
    return handleResponse(response) as Map<String, dynamic>;
  }

  /// Gửi email khôi phục mật khẩu (luôn trả 200 từ backend để chống email enumeration)
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await postWithFallback(
      '/auth/forgot-password',
      body: jsonEncode({'email': email}),
    );
    return handleResponse(response) as Map<String, dynamic>;
  }

  /// Xác thực email bằng OTP 6 số
  Future<Map<String, dynamic>> verifyEmail(String email, String otp) async {
    final response = await postWithFallback(
      '/auth/verify-email',
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return handleResponse(response) as Map<String, dynamic>;
  }

  /// Làm mới access token bằng refresh token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await postWithFallback(
      '/auth/refresh-token',
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    return handleResponse(response) as Map<String, dynamic>;
  }

  /// Đăng xuất — thu hồi refresh token trên server
  Future<void> logout(String refreshToken) async {
    await postWithFallback(
      '/auth/logout',
      requireAuth: true,
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    // Bỏ qua lỗi Network khi logout — local token sẽ bị xóa dù sao
  }
}
