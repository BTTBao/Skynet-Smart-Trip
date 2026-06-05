import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OpenStreetMapGeocodingService {
  const OpenStreetMapGeocodingService();

  Future<LatLng?> geocodeAddress(String address) async {
    final query = address.trim();
    if (query.isEmpty) {
      return null;
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'q': query,
      'limit': '1',
      'addressdetails': '0',
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
    if (decoded is! List || decoded.isEmpty) {
      return null;
    }

    final first = decoded.first;
    if (first is! Map<String, dynamic>) {
      return null;
    }

    final lat = double.tryParse((first['lat'] ?? '').toString());
    final lon = double.tryParse((first['lon'] ?? '').toString());
    if (lat == null || lon == null) {
      return null;
    }

    return LatLng(lat, lon);
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
