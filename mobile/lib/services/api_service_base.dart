import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  static const String _defaultDevTunnelBaseUrl =
      'https://5qqxj86m-5110.asse.devtunnels.ms/api';
  static const int _defaultLocalApiPort = 5110;

  static const String _configuredBaseUrlFromDefine = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _configuredBaseUrlsFromDefine = String.fromEnvironment(
    'API_BASE_URLS',
    defaultValue: '',
  );
  static const String _configuredTunnelBaseUrlFromDefine =
      String.fromEnvironment('API_TUNNEL_BASE_URL', defaultValue: '');
  static const String _configuredApiPortFromDefine = String.fromEnvironment(
    'API_PORT',
    defaultValue: '',
  );

  String get configuredBaseUrl => configuredBaseUrls.first;

  List<String> get configuredBaseUrls {
    final explicitList = _readConfigValue('API_BASE_URLS');
    if (explicitList != null && explicitList.trim().isNotEmpty) {
      return _dedupe(
        _splitBaseUrls(
          explicitList,
        ).map(_normalizeBaseUrl).where((value) => value.isNotEmpty),
      );
    }

    final explicitSingle = _readConfigValue('API_BASE_URL');
    if (explicitSingle != null && explicitSingle.trim().isNotEmpty) {
      return _dedupe([
        _normalizeBaseUrl(explicitSingle),
        ..._buildDefaultBaseUrls(),
      ]);
    }

    return _dedupe(_buildDefaultBaseUrls());
  }

  /// Standard headers. Adds Bearer token automatically when available.
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
        'Phien dang nhap da het han. Vui long dang nhap lai.',
      );
    }

    return headers;
  }

  Uri buildUri(
    String baseUrl,
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final uri = Uri.parse('$baseUrl$path');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: queryParameters);
  }

  Future<http.Response> getWithFallback(
    String path, {
    bool requireAuth = false,
    Map<String, String>? extraHeaders,
    Map<String, String>? queryParameters,
  }) async {
    final requestHeaders = await getHeaders(
      requireAuth: requireAuth,
      extraHeaders: extraHeaders,
    );

    return _sendWithFallback((baseUrl) {
      return http
          .get(
            buildUri(baseUrl, path, queryParameters: queryParameters),
            headers: requestHeaders,
          )
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
    final candidates = configuredBaseUrls;
    Object? lastError;

    for (var i = 0; i < candidates.length; i++) {
      final baseUrl = candidates[i];
      try {
        return await send(baseUrl);
      } on TimeoutException catch (e) {
        lastError = e;
        if (i < candidates.length - 1) {
          continue;
        }
      } on SocketException catch (e) {
        lastError = e;
        if (i < candidates.length - 1) {
          continue;
        }
      } on HttpException catch (e) {
        lastError = e;
        if (i < candidates.length - 1) {
          continue;
        }
      } on http.ClientException catch (e) {
        lastError = e;
        if (i < candidates.length - 1) {
          continue;
        }
      } on HandshakeException catch (e) {
        lastError = e;
        if (i < candidates.length - 1) {
          continue;
        }
      }
    }

    final tried = candidates.join(' -> ');
    throw Exception(
      'Khong the ket noi backend qua cac endpoint: $tried. $lastError',
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

  String? _readConfigValue(String key) {
    switch (key) {
      case 'API_BASE_URL':
        if (_configuredBaseUrlFromDefine.trim().isNotEmpty) {
          return _configuredBaseUrlFromDefine.trim();
        }
        break;
      case 'API_BASE_URLS':
        if (_configuredBaseUrlsFromDefine.trim().isNotEmpty) {
          return _configuredBaseUrlsFromDefine.trim();
        }
        break;
      case 'API_TUNNEL_BASE_URL':
        if (_configuredTunnelBaseUrlFromDefine.trim().isNotEmpty) {
          return _configuredTunnelBaseUrlFromDefine.trim();
        }
        break;
      case 'API_PORT':
        if (_configuredApiPortFromDefine.trim().isNotEmpty) {
          return _configuredApiPortFromDefine.trim();
        }
        break;
    }

    final value = dotenv.env[key];
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value.trim();
  }

  List<String> _buildDefaultBaseUrls() {
    final port = _readApiPort();
    final localCandidates = <String>[
      if (kIsWeb) ...[
        'http://localhost:$port/api',
        'http://127.0.0.1:$port/api',
      ] else
        ..._localBaseUrlsForPlatform(port),
    ];

    final tunnelBaseUrl =
        _readConfigValue('API_TUNNEL_BASE_URL') ?? _defaultDevTunnelBaseUrl;
    final tunnel = _normalizeBaseUrl(tunnelBaseUrl);
    if (tunnel.isNotEmpty) {
      localCandidates.add(tunnel);
    }

    return localCandidates;
  }

  List<String> _localBaseUrlsForPlatform(int port) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return [
          'http://10.0.2.2:$port/api',
          'http://localhost:$port/api',
          'http://127.0.0.1:$port/api',
        ];
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return ['http://localhost:$port/api', 'http://127.0.0.1:$port/api'];
    }
  }

  int _readApiPort() {
    final raw = _readConfigValue('API_PORT');
    if (raw == null) {
      return _defaultLocalApiPort;
    }

    return int.tryParse(raw) ?? _defaultLocalApiPort;
  }

  String _normalizeBaseUrl(String value) {
    var normalized = value.trim();
    if (normalized.isEmpty) {
      return normalized;
    }

    normalized = normalized.replaceFirst(RegExp(r'/+$'), '');
    if (!normalized.endsWith('/api')) {
      normalized = '$normalized/api';
    }

    return normalized;
  }

  List<String> _splitBaseUrls(String raw) {
    return raw
        .split(RegExp(r'[\n,;|]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  List<String> _dedupe(Iterable<String> values) {
    final result = <String>[];
    final seen = <String>{};

    for (final value in values) {
      final normalized = _normalizeBaseUrl(value);
      if (normalized.isEmpty || seen.contains(normalized)) {
        continue;
      }

      seen.add(normalized);
      result.add(normalized);
    }

    return result;
  }

  String _extractErrorMessage(http.Response response) {
    if (response.body.isEmpty) {
      return 'Loi API: ${response.statusCode}';
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

    return 'Loi API: ${response.statusCode} - ${response.body}';
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
