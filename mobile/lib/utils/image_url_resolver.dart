import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/api_service_base.dart';

class ImageUrlResolver {
  static const String _defaultApiBaseUrl =
      'https://lmz1ft37-5110.asse.devtunnels.ms/api';

  static String resolve(String? rawUrl, {String? apiBaseUrl}) {
    final value = rawUrl?.trim() ?? '';
    if (value.isEmpty) {
      return '';
    }

    if (_isAbsoluteHttpUrl(value) || value.startsWith('data:')) {
      if (value.contains('localhost') || value.contains('127.0.0.1')) {
        final uri = Uri.tryParse(value);
        if (uri != null) {
          final origin = _resolveOrigin(apiBaseUrl);
          final path = uri.path;
          final query = uri.hasQuery ? '?${uri.query}' : '';
          final fragment = uri.hasFragment ? '#${uri.fragment}' : '';
          return '$origin$path$query$fragment';
        }
      }
      return value;
    }

    if (value.startsWith('//')) {
      return 'https:$value';
    }

    final origin = _resolveOrigin(apiBaseUrl);
    final path = value.startsWith('/') ? value : '/$value';
    return '$origin$path';
  }

  static List<String> resolveMany(Iterable<String>? rawUrls, {String? apiBaseUrl}) {
    return (rawUrls ?? const <String>[])
        .map((value) => resolve(value, apiBaseUrl: apiBaseUrl))
        .where((value) => value.isNotEmpty)
        .toList();
  }

  static String _resolveOrigin(String? apiBaseUrl) {
    final healthyUrl = ApiService.cachedHealthyBaseUrl;
    final configuredBaseUrl = (healthyUrl != null && healthyUrl.isNotEmpty)
        ? healthyUrl
        : _firstConfiguredApiBaseUrl();
    final source = (apiBaseUrl != null && apiBaseUrl.trim().isNotEmpty)
        ? apiBaseUrl.trim()
        : configuredBaseUrl;

    final parsed = Uri.tryParse(source);
    if (parsed != null && parsed.scheme.isNotEmpty && parsed.host.isNotEmpty) {
      final port = parsed.hasPort ? ':${parsed.port}' : '';
      return '${parsed.scheme}://${parsed.host}$port';
    }

    final cleaned = source.replaceFirst(RegExp(r'/api/?$'), '').replaceFirst(RegExp(r'/+$'), '');
    if (_isAbsoluteHttpUrl(cleaned)) {
      return cleaned;
    }

    return _fallbackOrigin();
  }

  static String _firstConfiguredApiBaseUrl() {
    final explicitList = dotenv.env['API_BASE_URLS']?.trim();
    if (explicitList != null && explicitList.isNotEmpty) {
      final first = explicitList
          .split(RegExp(r'[\n,;|]'))
          .map((value) => value.trim())
          .firstWhere((value) => value.isNotEmpty, orElse: () => '');
      if (first.isNotEmpty) {
        return first;
      }
    }

    final explicitSingle = dotenv.env['API_BASE_URL']?.trim();
    if (explicitSingle != null && explicitSingle.isNotEmpty) {
      return explicitSingle;
    }

    final explicitTunnel = dotenv.env['API_TUNNEL_BASE_URL']?.trim();
    if (explicitTunnel != null && explicitTunnel.isNotEmpty) {
      return explicitTunnel;
    }

    return _defaultApiBaseUrl;
  }

  static String _fallbackOrigin() {
    return _defaultApiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
  }

  static bool _isAbsoluteHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}
