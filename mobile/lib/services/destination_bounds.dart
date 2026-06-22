import 'openstreetmap_geocoding_service.dart';

/// Known bounding boxes for tourism destinations stored in the app database.
/// Used to scope itinerary place search to the trip's selected destination.
class DestinationBoundsLookup {
  const DestinationBoundsLookup._();

  static BoundingBox? resolve(String destinationName) {
    final normalized = _normalize(destinationName);
    if (normalized.isEmpty) return null;

    final direct = _bounds[normalized];
    if (direct != null) return direct;

    for (final entry in _aliases.entries) {
      if (entry.value.contains(normalized)) {
        return _bounds[entry.key];
      }
    }

    return null;
  }

  static String _normalize(String value) {
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

    return text
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const Map<String, BoundingBox> _bounds = {
    'da lat': BoundingBox(
      minLat: 11.78,
      maxLat: 11.98,
      minLon: 108.35,
      maxLon: 108.55,
    ),
    'phu quoc': BoundingBox(
      minLat: 9.95,
      maxLat: 10.45,
      minLon: 103.85,
      maxLon: 104.05,
    ),
    'da nang': BoundingBox(
      minLat: 15.95,
      maxLat: 16.20,
      minLon: 107.95,
      maxLon: 108.35,
    ),
    'nha trang': BoundingBox(
      minLat: 12.15,
      maxLat: 12.35,
      minLon: 109.10,
      maxLon: 109.28,
    ),
    'ha long': BoundingBox(
      minLat: 20.85,
      maxLat: 21.05,
      minLon: 106.95,
      maxLon: 107.15,
    ),
    'ha noi': BoundingBox(
      minLat: 20.95,
      maxLat: 21.15,
      minLon: 105.75,
      maxLon: 106.05,
    ),
    'tp ho chi minh': BoundingBox(
      minLat: 10.70,
      maxLat: 10.90,
      minLon: 106.55,
      maxLon: 106.85,
    ),
    'phu quy': BoundingBox(
      minLat: 10.48,
      maxLat: 10.62,
      minLon: 109.08,
      maxLon: 109.22,
    ),
    'hoi an': BoundingBox(
      minLat: 15.85,
      maxLat: 15.93,
      minLon: 108.30,
      maxLon: 108.38,
    ),
    'hue': BoundingBox(
      minLat: 16.40,
      maxLat: 16.52,
      minLon: 107.50,
      maxLon: 107.65,
    ),
  };

  static const Map<String, Set<String>> _aliases = {
    'tp ho chi minh': {
      'tp ho chi minh',
      'ho chi minh',
      'thanh pho ho chi minh',
      'sai gon',
      'saigon',
    },
    'ha noi': {'ha noi', 'hanoi', 'thu do ha noi'},
    'ha long': {'ha long', 'tp ha long', 'thanh pho ha long', 'quang ninh'},
    'da nang': {'da nang', 'danang'},
    'da lat': {'da lat', 'dalat'},
    'phu quoc': {'phu quoc', 'phu quoc island'},
    'hoi an': {'hoi an', 'hoian'},
    'hue': {'hue', 'co do hue'},
    'nha trang': {'nha trang', 'khanh hoa'},
    'phu quy': {'phu quy', 'dao phu quy'},
  };
}
