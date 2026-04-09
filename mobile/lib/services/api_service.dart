import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

abstract class ApiService {
  static const _storage = FlutterSecureStorage();

  // URL Backend .NET — đổi thành IP/domain thực khi deploy
  // Android emulator dùng 10.0.2.2 để trỏ tới localhost của máy host
  // iOS simulator dùng localhost hoặc 127.0.0.1
  final String baseUrl = "http://10.0.2.2:5110/api";

  /// Trả về headers chuẩn. Tự động đính kèm Bearer token nếu đã đăng nhập.
  Future<Map<String, String>> getHeaders({bool requireAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    } else if (requireAuth) {
      throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    }

    return headers;
  }

  /// Parse response: trả về body nếu 2xx, throw Exception với message rõ ràng nếu lỗi.
  dynamic handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return <String, dynamic>{};
      return jsonDecode(response.body);
    }

    // Cố gắng extract message từ JSON body trả về của backend
    String errorMessage = 'Lỗi ${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        errorMessage = body['message'] as String? ??
            body['error'] as String? ??
            errorMessage;
      }
    } catch (_) {
      // Body không phải JSON — dùng fallback message
    }

    throw Exception(errorMessage);
  }
}