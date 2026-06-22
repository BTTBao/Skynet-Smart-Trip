import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import 'secure_storage_service.dart';

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
  static const String _configuredBaseUrlsFromEnv = String.fromEnvironment(
    'API_BASE_URLS',
    defaultValue: '',
  );

  String get configuredBaseUrl {
    final urls = configuredBaseUrls;
    return urls.isEmpty ? 'http://localhost:5110/api' : urls.first;
  }

  List<String> get configuredBaseUrls {
    if (_configuredBaseUrlsFromEnv.isNotEmpty) {
      final urls = _configuredBaseUrlsFromEnv
          .split(',')
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList(growable: false);
      if (urls.isNotEmpty) {
        return urls;
      }
    }

    if (_configuredBaseUrlFromEnv.isNotEmpty) {
      return [_configuredBaseUrlFromEnv];
    }

    if (kIsWeb) {
      return const [
        'http://localhost:5110/api',
        'http://127.0.0.1:5110/api',
      ];
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const [
          'http://10.0.2.2:5110/api',
          'http://localhost:5110/api',
        ];
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return const [
          'http://localhost:5110/api',
          'http://127.0.0.1:5110/api',
        ];
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

    final token = await SecureStorageService.read('access_token');
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else if (requireAuth) {
      throw ApiException(
        401,
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      );
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
          .timeout(const Duration(seconds: 30));
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
          .timeout(const Duration(seconds: 30));
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
          .timeout(const Duration(seconds: 30));
    });
  }

  Future<http.Response> deleteWithFallback(
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
          .delete(buildUri(baseUrl, path), headers: requestHeaders, body: body)
          .timeout(const Duration(seconds: 30));
    });
  }

  Future<http.Response> multipartPostWithFallback(
    String path, {
    required String fileField,
    required XFile file,
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
      request.headers.remove('content-type');
      request.headers.remove('Content-Type');
      final resolvedContentType = _resolveImageContentType(file);

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            fileField,
            await file.readAsBytes(),
            filename: file.name,
            contentType: resolvedContentType,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            fileField,
            file.path,
            contentType: resolvedContentType,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 40),
      );

      return http.Response.fromStream(streamedResponse);
    });
  }

  Future<http.Response> _sendWithFallback(
    Future<http.Response> Function(String baseUrl) send,
  ) async {
    final baseUrls = configuredBaseUrls;
    Object? lastError;

    for (final baseUrl in baseUrls) {
      try {
        return await send(baseUrl);
      } on TimeoutException catch (e) {
        lastError = e;
      } on SocketException catch (e) {
        lastError = e;
      } on HttpException catch (e) {
        lastError = e;
      } on http.ClientException catch (e) {
        lastError = e;
      } on HandshakeException catch (e) {
        lastError = e;
      }
    }

    throw Exception(
      'Không thể kết nối tới backend. Đã thử: ${baseUrls.join(', ')}. '
      'Hãy đảm bảo API đang chạy ở port 5110 hoặc chạy Flutter với '
      '--dart-define=API_BASE_URL=http://<host>:5110/api. $lastError',
    );
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
      return 'Lỗi API: ${response.statusCode}';
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message =
            decoded['message'] ?? decoded['error'] ?? decoded['title'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {}

    return 'Lỗi API: ${response.statusCode} - ${response.body}';
  }

  MediaType? _resolveImageContentType(XFile file) {
    if (file.mimeType != null && file.mimeType!.trim().isNotEmpty) {
      try {
        return MediaType.parse(file.mimeType!);
      } catch (_) {}
    }

    final nameLower = file.name.toLowerCase();
    if (nameLower.endsWith('.png')) {
      return MediaType('image', 'png');
    }

    if (nameLower.endsWith('.jpg') || nameLower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }

    if (nameLower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }

    return null;
  }
}



