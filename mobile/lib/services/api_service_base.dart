import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

abstract class ApiService {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5110/api',
  );

  Map<String, String> get headers => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Uri buildUri(String baseUrl, String path) => Uri.parse('$baseUrl$path');

  Future<http.Response> getWithFallback(String path) {
    return _sendWithFallback((baseUrl) {
      return http
          .get(buildUri(baseUrl, path), headers: headers)
          .timeout(const Duration(seconds: 10));
    });
  }

  Future<http.Response> postWithFallback(String path, {Object? body}) {
    return _sendWithFallback((baseUrl) {
      return http
          .post(buildUri(baseUrl, path), headers: headers, body: body)
          .timeout(const Duration(seconds: 10));
    });
  }

  Future<http.Response> putWithFallback(String path, {Object? body}) {
    return _sendWithFallback((baseUrl) {
      return http
          .put(buildUri(baseUrl, path), headers: headers, body: body)
          .timeout(const Duration(seconds: 10));
    });
  }

  Future<http.Response> multipartPostWithFallback(
    String path, {
    required String fileField,
    required String filePath,
  }) {
    return _sendWithFallback((baseUrl) async {
      final request = http.MultipartRequest('POST', buildUri(baseUrl, path));
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 20),
      );

      return http.Response.fromStream(streamedResponse);
    });
  }

  Future<http.Response> _sendWithFallback(
    Future<http.Response> Function(String baseUrl) send,
  ) async {
    try {
      return await send(_configuredBaseUrl);
    } on SocketException catch (e) {
      throw Exception('Khong the ket noi toi backend local o $_configuredBaseUrl. $e');
    } on HttpException catch (e) {
      throw Exception('Backend local tra ve loi ket noi: $e');
    } on http.ClientException catch (e) {
      throw Exception('Loi client khi goi backend local: $e');
    } on HandshakeException catch (e) {
      throw Exception('Loi SSL/handshake khi goi backend local: $e');
    }
  }

  dynamic handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    throw Exception('Loi API: ${response.statusCode} - ${response.body}');
  }
}
