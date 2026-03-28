import 'dart:convert';

import 'package:http/http.dart' as http;

abstract class ApiService {
  final String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5110/api',
  );

  Future<Map<String, String>> getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  dynamic handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }

      return jsonDecode(response.body);
    }

    throw Exception('Loi API: ${response.statusCode} - ${response.body}');
  }
}
