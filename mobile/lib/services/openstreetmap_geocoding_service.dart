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

    final response = await http.get(uri, headers: const {
      'Accept': 'application/json',
      'User-Agent': 'SkynetSmartTrip/1.0',
    });

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
}
