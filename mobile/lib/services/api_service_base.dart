import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.statusCode, this.message, {this.rawBody});

  final int statusCode;
  final String message;
  final String? rawBody;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

abstract class ApiService {
  static const String _configuredBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  String get configuredBaseUrl {
    if (_configuredBaseUrlFromEnv.isNotEmpty) {
      return _configuredBaseUrlFromEnv;
    }

    if (kIsWeb) {
      return 'http://localhost:5110/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5110/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:5110/api';
    }
  }

  Map<String, String> get headers => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<Map<String, String>> getHeaders({
    bool requireAuth = false,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (extraHeaders != null) ...extraHeaders,
    };

    final token = await _storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else if (requireAuth) {
      throw Exception('Phien dang nhap da het han. Vui long dang nhap lai.');
    }

    return headers;
  }

  Uri buildUri(String baseUrl, String path) => Uri.parse('$baseUrl$path');

  Future<http.Response> getWithFallback(
    String path, {
    bool requireAuth = false,
    Map<String, String>? extraHeaders,
  }) async {
    final requestHeaders = await getHeaders(
      requireAuth: requireAuth,
      extraHeaders: extraHeaders,
    );

    return _sendWithFallback((baseUrl) {
      return http
          .get(buildUri(baseUrl, path), headers: requestHeaders)
          .timeout(const Duration(seconds: 10));
    });
  }

  Future<http.Response> postWithFallback(
    String path, {
    Object? body,
    bool requireAuth = false,
    Map<String, String>? extraHeaders,
  }) async {
    final requestHeaders = await getHeaders(
      requireAuth: requireAuth,
      extraHeaders: extraHeaders,
    );

    return _sendWithFallback((baseUrl) {
      return http
          .post(buildUri(baseUrl, path), headers: requestHeaders, body: body)
          .timeout(const Duration(seconds: 10));
    });
  }

  Future<http.Response> putWithFallback(
    String path, {
    Object? body,
    bool requireAuth = false,
    Map<String, String>? extraHeaders,
  }) async {
    final requestHeaders = await getHeaders(
      requireAuth: requireAuth,
      extraHeaders: extraHeaders,
    );

    return _sendWithFallback((baseUrl) {
      return http
          .put(buildUri(baseUrl, path), headers: requestHeaders, body: body)
          .timeout(const Duration(seconds: 10));
    });
  }

  Future<http.Response> deleteWithFallback(
    String path, {
    bool requireAuth = false,
    Map<String, String>? extraHeaders,
  }) async {
    final requestHeaders = await getHeaders(
      requireAuth: requireAuth,
      extraHeaders: extraHeaders,
    );

    return _sendWithFallback((baseUrl) {
      return http
          .delete(buildUri(baseUrl, path), headers: requestHeaders)
          .timeout(const Duration(seconds: 10));
    });
  }

  Future<http.Response> multipartPostWithFallback(
    String path, {
    required String fileField,
    required String filePath,
    bool requireAuth = false,
    Map<String, String>? extraHeaders,
  }) async {
    final requestHeaders = await getHeaders(
      requireAuth: requireAuth,
      extraHeaders: extraHeaders,
    );

    return _sendWithFallback((baseUrl) async {
      final request = http.MultipartRequest('POST', buildUri(baseUrl, path));
      request.headers.addAll(requestHeaders);
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
    final baseUrl = configuredBaseUrl;

    try {
      return await send(baseUrl);
    } on TimeoutException catch (e) {
      throw Exception(
        'Ket noi toi backend bi timeout sau 10 giay ($baseUrl). '
        'Android emulator dung 10.0.2.2, iOS simulator/Desktop dung localhost, '
        'thiet bi that can cau hinh --dart-define=API_BASE_URL=http://<LAN-IP>:5110/api. $e',
      );
    } on SocketException catch (e) {
      throw Exception(
        'Khong the ket noi toi backend o $baseUrl. '
        'Android emulator dung 10.0.2.2, iOS simulator/Desktop dung localhost, '
        'thiet bi that can cau hinh --dart-define=API_BASE_URL=http://<LAN-IP>:5110/api. $e',
      );
    } on HttpException catch (e) {
      throw Exception('Backend tra ve loi ket noi o $baseUrl: $e');
    } on http.ClientException catch (e) {
      throw Exception('Loi client khi goi backend o $baseUrl: $e');
    } on HandshakeException catch (e) {
      throw Exception('Loi SSL/handshake khi goi backend o $baseUrl: $e');
    }
  }

  dynamic handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }

      return jsonDecode(response.body);
    }

    throw ApiException(
      response.statusCode,
      _extractErrorMessage(response),
      rawBody: response.body,
    );
  }

  String _extractErrorMessage(http.Response response) {
    if (response.body.isEmpty) {
      return 'Loi API: ${response.statusCode}';
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['error'] ?? decoded['title'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {}

    return 'Loi API: ${response.statusCode} - ${response.body}';
  }
}
