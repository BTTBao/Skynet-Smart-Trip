import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'destination_bounds.dart';

class GeocodingResult {
  final LatLng latLng;
  final String displayName;
  final String shortName;
  final BoundingBox? boundingBox;

  const GeocodingResult({
    required this.latLng,
    required this.displayName,
    required this.shortName,
    this.boundingBox,
  });
}

/// Response from a place-name search, including whether more matches exist.
class PlaceSearchResponse {
  final List<GeocodingResult> results;

  /// True when additional matching places were found but omitted due to [limit].
  final bool hasMoreMatches;

  const PlaceSearchResponse({
    required this.results,
    this.hasMoreMatches = false,
  });
}

/// An axis-aligned bounding box returned by Nominatim.
class BoundingBox {
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  const BoundingBox({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  /// Returns the center of this bounding box.
  LatLng get center =>
      LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);

  /// Returns true if [point] lies within (or on the boundary of) this box.
  bool contains(LatLng point) {
    return point.latitude >= minLat &&
        point.latitude <= maxLat &&
        point.longitude >= minLon &&
        point.longitude <= maxLon;
  }

  /// Slightly expanded bounding box (by [padding] degrees) to give a generous
  /// tolerance when checking whether a result is "inside" the destination.
  BoundingBox expanded(double padding) {
    return BoundingBox(
      minLat: minLat - padding,
      maxLat: maxLat + padding,
      minLon: minLon - padding,
      maxLon: maxLon + padding,
    );
  }

  /// Nominatim viewbox format: "minLon,minLat,maxLon,maxLat"
  String toViewbox() =>
      '$minLon,$minLat,$maxLon,$maxLat';
}

class OpenStreetMapGeocodingService {
  const OpenStreetMapGeocodingService();

  Future<LatLng?> geocodeAddress(String address) async {
    final response = await searchPlaces(address, limit: 1);
    if (response.results.isEmpty) return null;
    return response.results.first.latLng;
  }

  /// Geocode a destination city/area name and return its bounding box.
  /// Returns null if the destination could not be found.
  Future<BoundingBox?> geocodeDestinationBounds(String destinationName) async {
    final trimmed = destinationName.trim();
    if (trimmed.isEmpty) return null;

    final knownBounds = DestinationBoundsLookup.resolve(trimmed);
    if (knownBounds != null) return knownBounds;

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'q': '$trimmed, Việt Nam',
      'limit': '1',
      'addressdetails': '0',
      'countrycodes': 'vn',
    });

    try {
      final response = await http.get(uri, headers: const {
        'Accept': 'application/json',
        'User-Agent': 'SkynetSmartTrip/1.0',
      });
      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) return null;

      final item = decoded.first;
      if (item is! Map<String, dynamic>) return null;

      final bb = item['boundingbox'];
      if (bb is! List || bb.length < 4) return null;

      final minLat = double.tryParse(bb[0].toString());
      final maxLat = double.tryParse(bb[1].toString());
      final minLon = double.tryParse(bb[2].toString());
      final maxLon = double.tryParse(bb[3].toString());

      if (minLat == null || maxLat == null || minLon == null || maxLon == null) {
        return null;
      }

      return BoundingBox(
        minLat: minLat,
        maxLat: maxLat,
        minLon: minLon,
        maxLon: maxLon,
      );
    } catch (_) {
      return null;
    }
  }

  /// Search for places by name within an optional destination area.
  ///
  /// When [viewbox] is provided, only places inside that bounding box are
  /// returned. Results are also filtered so the place name contains [query]
  /// (supports generic terms like "lẩu"). At most [limit] results are returned;
  /// [PlaceSearchResponse.hasMoreMatches] is set when additional matches exist.
  Future<PlaceSearchResponse> searchPlaces(
    String query, {
    int limit = 5,
    BoundingBox? viewbox,
    String? destinationName,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const PlaceSearchResponse(results: []);
    }

    final destination = destinationName?.trim();
    final restrictToViewbox = viewbox != null;

    // When a trip destination is known, only search inside that area.
    if (destination != null && destination.isNotEmpty && !restrictToViewbox) {
      return const PlaceSearchResponse(results: []);
    }

    final fetchLimit = restrictToViewbox ? (limit * 4).clamp(limit, 20) : limit;
    final searchQuery = _buildSearchQuery(trimmed, destination);

    final params = <String, String>{
      'format': 'jsonv2',
      'q': searchQuery,
      'limit': '$fetchLimit',
      'addressdetails': '1',
    };

    if (viewbox != null) {
      params['viewbox'] = viewbox.toViewbox();
      params['bounded'] = '1';
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);

    try {
      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'SkynetSmartTrip/1.0',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const PlaceSearchResponse(results: []);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) {
        return const PlaceSearchResponse(results: []);
      }

      final rawResults = <GeocodingResult>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        final lat = double.tryParse((item['lat'] ?? '').toString());
        final lon = double.tryParse((item['lon'] ?? '').toString());
        if (lat == null || lon == null) continue;

        final latLng = LatLng(lat, lon);
        if (viewbox != null && !viewbox.contains(latLng)) continue;

        final displayName = item['display_name']?.toString() ?? trimmed;
        final shortName = _extractShortName(item, displayName);

        BoundingBox? resultBb;
        final bb = item['boundingbox'];
        if (bb is List && bb.length >= 4) {
          final bMinLat = double.tryParse(bb[0].toString());
          final bMaxLat = double.tryParse(bb[1].toString());
          final bMinLon = double.tryParse(bb[2].toString());
          final bMaxLon = double.tryParse(bb[3].toString());
          if (bMinLat != null &&
              bMaxLat != null &&
              bMinLon != null &&
              bMaxLon != null) {
            resultBb = BoundingBox(
              minLat: bMinLat,
              maxLat: bMaxLat,
              minLon: bMinLon,
              maxLon: bMaxLon,
            );
          }
        }

        rawResults.add(
          GeocodingResult(
            latLng: latLng,
            displayName: displayName,
            shortName: shortName,
            boundingBox: resultBb,
          ),
        );
      }

      if (!restrictToViewbox) {
        return PlaceSearchResponse(results: rawResults.take(limit).toList());
      }

      final matched = rawResults
          .where(
            (result) =>
                _nameMatchesQuery(result, trimmed) &&
                (destination == null ||
                    destination.isEmpty ||
                    _resultMatchesDestination(result, destination)),
          )
          .toList();

      final hasMoreMatches = matched.length > limit ||
          (matched.length == limit && rawResults.length >= fetchLimit);

      return PlaceSearchResponse(
        results: matched.take(limit).toList(),
        hasMoreMatches: hasMoreMatches,
      );
    } catch (_) {
      return const PlaceSearchResponse(results: []);
    }
  }

  String _buildSearchQuery(String query, String? destinationName) {
    final destination = destinationName?.trim();
    if (destination == null || destination.isEmpty) return query;
    if (_normalizeSearchText(query).contains(_normalizeSearchText(destination))) {
      return query;
    }
    return '$query, $destination';
  }

  bool _resultMatchesDestination(GeocodingResult result, String destinationName) {
    final searchableText = _normalizeSearchText(
      '${result.shortName}, ${result.displayName}',
    );

    for (final token in _destinationSearchTokens(destinationName)) {
      if (searchableText.contains(token)) {
        return true;
      }
    }

    return false;
  }

  List<String> _destinationSearchTokens(String destinationName) {
    final normalizedDestination = _normalizeSearchText(destinationName);
    if (normalizedDestination.isEmpty) return const [];

    const aliasesByDestination = <String, List<String>>{
      'da lat': ['da lat'],
      'phu quoc': ['phu quoc'],
      'da nang': ['da nang'],
      'nha trang': ['nha trang', 'khanh hoa'],
      'ha long': ['ha long', 'quang ninh'],
      'ha noi': ['ha noi', 'hanoi'],
      'tp ho chi minh': ['tp ho chi minh', 'ho chi minh', 'sai gon'],
      'phu quy': ['phu quy', 'binh thuan'],
      'hoi an': ['hoi an', 'quang nam'],
      'hue': ['hue', 'thua thien hue'],
    };

    for (final entry in aliasesByDestination.entries) {
      if (normalizedDestination.contains(entry.key) ||
          entry.key.contains(normalizedDestination)) {
        return entry.value;
      }
    }

    return [normalizedDestination];
  }

  bool _nameMatchesQuery(GeocodingResult result, String query) {
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.isEmpty) return true;

    final normalizedShortName = _normalizeSearchText(result.shortName);
    final normalizedDisplayName = _normalizeSearchText(result.displayName);
    final normalizedRawName = _normalizeSearchText(
      result.displayName.split(',').first,
    );

    return normalizedShortName.contains(normalizedQuery) ||
        normalizedDisplayName.contains(normalizedQuery) ||
        normalizedRawName.contains(normalizedQuery);
  }

  String _normalizeSearchText(String value) {
    var text = value.toLowerCase().trim();
    const replacements = <String, String>{
      'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
      'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
      'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
      'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
      'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
      'đ': 'd',
    };

    for (final entry in replacements.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    return text.replaceAll(RegExp(r'\s+'), ' ');
  }

  String _extractShortName(
    Map<String, dynamic> item,
    String fallbackDisplayName,
  ) {
    final name = item['name']?.toString();
    if (name != null && name.isNotEmpty) {
      // Try to append city/town for disambiguation
      final address = item['address'];
      if (address is Map<String, dynamic>) {
        final city = address['city'] ??
            address['town'] ??
            address['village'] ??
            address['county'] ??
            address['state'];
        if (city != null && city.toString().trim().isNotEmpty) {
          return '$name, ${city.toString().trim()}';
        }
      }
      return name;
    }

    // Fallback: first two parts of display_name
    final parts = fallbackDisplayName.split(',');
    if (parts.length >= 2) {
      return '${parts[0].trim()}, ${parts[1].trim()}';
    }
    return fallbackDisplayName.split(',').first.trim();
  }

  Future<String?> reverseGeocode(LatLng position) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': position.latitude.toString(),
      'lon': position.longitude.toString(),
      'zoom': '12',
      'addressdetails': '1',
    });

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'SkynetSmartTrip/1.0',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final address = decoded['address'];
    if (address is Map<String, dynamic>) {
      final city =
          address['city'] ??
          address['town'] ??
          address['village'] ??
          address['county'] ??
          address['state'];
      if (city != null && city.toString().trim().isNotEmpty) {
        return city.toString().trim();
      }
    }

    final displayName = decoded['display_name']?.toString();
    if (displayName == null || displayName.trim().isEmpty) {
      return null;
    }

    return displayName.split(',').first.trim();
  }
}
