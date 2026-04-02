import 'dart:convert';
import 'package:http/http.dart' as http;

abstract class ApiService {
  // Thay url này bằng URL thực tế của Backend .NET của bạn
  final String baseUrl = "https://api.skynet-smart-trip.com/api";

  Future<Map<String, String>> getHeaders() async {
    // Trong tương lai sẽ lấy token từ SecureStorage ở đây
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // 'Authorization': 'Bearer $token',
    };
  }

  // Helper để xử lý response chung
  dynamic handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
    }
  }
}
