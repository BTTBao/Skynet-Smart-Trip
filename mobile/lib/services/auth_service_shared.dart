import 'dart:convert';

import 'api_service_base.dart';

class AuthService extends ApiService {
  /// Đăng nhập bằng email hoặc username
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final response = await postWithFallback(
      '/auth/login',
      body: jsonEncode({'identifier': identifier, 'password': password}),
    );

    return handleResponse(response) as Map<String, dynamic>;
  }

  /// Đăng ký tài khoản mới
  Future<Map<String, dynamic>> register(
    String fullName,
    String username,
    String email,
    String password,
    String phone,
  ) async {
    final response = await postWithFallback(
      '/auth/register',
      body: jsonEncode({
        'fullName': fullName,
        'userName': username,
        'email': email,
        'password': password,
        'phone': phone,
      }),
    );

    return handleResponse(response) as Map<String, dynamic>;
  }

  /// Đăng nhập bằng Google — nhận idToken từ Google Sign-In
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final response = await postWithFallback(
      '/auth/login-google',
      body: jsonEncode({'idToken': idToken}),
    );

    return handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await postWithFallback(
      '/auth/forgot-password',
      body: jsonEncode({'email': email}),
    );

    return handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyEmail(String email, String otp) async {
    final response = await postWithFallback(
      '/auth/verify-email',
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    return handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await postWithFallback(
      '/auth/refresh-token',
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    return handleResponse(response) as Map<String, dynamic>;
  }

  Future<void> logout(String refreshToken) async {
    await postWithFallback(
      '/auth/logout',
      requireAuth: true,
      body: jsonEncode({'refreshToken': refreshToken}),
    );
  }
}
