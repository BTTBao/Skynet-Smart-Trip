import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class AuthService extends ApiService {
  /// Đăng nhập — trả về accessToken + refreshToken + expiresIn
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
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
    final url = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
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
    final url = Uri.parse('$baseUrl/auth/forgot-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return handleResponse(response) as Map<String, dynamic>;
  }

  /// Xác thực email bằng OTP 6 số
  Future<Map<String, dynamic>> verifyEmail(String email, String otp) async {
    final url = Uri.parse('$baseUrl/auth/verify-email');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return handleResponse(response) as Map<String, dynamic>;
  }

  /// Làm mới access token bằng refresh token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final url = Uri.parse('$baseUrl/auth/refresh-token');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    return handleResponse(response) as Map<String, dynamic>;
  }

  /// Đăng xuất — thu hồi refresh token trên server
  Future<void> logout(String refreshToken) async {
    final url = Uri.parse('$baseUrl/auth/logout');
    final headers = await getHeaders(requireAuth: true);
    await http.post(
      url,
      headers: headers,
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    // Bỏ qua lỗi Network khi logout — local token sẽ bị xóa dù sao
  }
}
