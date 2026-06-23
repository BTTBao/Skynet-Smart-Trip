import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/resort_model.dart';
import '../../services/openstreetmap_geocoding_service.dart';
import '../../widgets/app_network_image.dart';
import '../resort_detail/resort_detail_screen.dart';

class ResortMapScreen extends StatefulWidget {
  const ResortMapScreen({
    super.key,
    required this.hotels,
    required this.locationTitle,
    this.onFilter,
  });

  final List<ResortModel> hotels;
  final String locationTitle;
  final Future<List<ResortModel>?> Function()? onFilter;

  @override
  State<ResortMapScreen> createState() => _ResortMapScreenState();
}

class _ResortMapScreenState extends State<ResortMapScreen> {
  final MapController _mapController = MapController();
  final OpenStreetMapGeocodingService _geocoding =
      const OpenStreetMapGeocodingService();
  final Map<int, LatLng> _positions = {};
  late List<ResortModel> _hotels;
  int? _selectedHotelId;
  bool _loading = true;

  ResortModel? get _selectedHotel {
    if (_hotels.isEmpty) return null;
    return _hotels.firstWhere(
      (hotel) => hotel.id == _selectedHotelId,
      orElse: () => _hotels.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _hotels = List.of(widget.hotels);
    _selectedHotelId = _hotels.isEmpty ? null : _hotels.first.id;
    _loadPositions();
  }

  Future<void> _loadPositions() async {
    for (final hotel in _hotels) {
      try {
        final position = await _geocoding.geocodeAddress(hotel.address);
        if (position != null) _positions[hotel.id] = position;
      } catch (_) {
        // A missing geocode should not block the remaining hotels.
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitMarkers());
  }

  Future<void> _openFilters() async {
    final onFilter = widget.onFilter;
    if (onFilter == null) return;
    final hotels = await onFilter();
    if (!mounted || hotels == null) return;
    setState(() {
      _hotels = hotels;
      _selectedHotelId = hotels.isEmpty ? null : hotels.first.id;
      _loading = true;
      final ids = hotels.map((hotel) => hotel.id).toSet();
      _positions.removeWhere((id, _) => !ids.contains(id));
    });
    await _loadPositions();
  }

  void _fitMarkers() {
    if (_positions.isEmpty) return;
    if (_positions.length == 1) {
      _mapController.move(_positions.values.first, 14);
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(_positions.values.toList()),
        padding: const EdgeInsets.fromLTRB(50, 130, 50, 230),
      ),
    );
  }

  void _selectHotel(ResortModel hotel) {
    setState(() => _selectedHotelId = hotel.id);
    final position = _positions[hotel.id];
    if (position != null) _mapController.move(position, 15);
  }

  @override
  Widget build(BuildContext context) {
    final selectedHotel = _selectedHotel;
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _fallbackCenter(widget.locationTitle),
              initialZoom: 11,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.skynet.smarttrip',
              ),
              MarkerLayer(
                markers: _hotels
                    .where((hotel) => _positions.containsKey(hotel.id))
                    .map(
                      (hotel) => Marker(
                        point: _positions[hotel.id]!,
                        width: 90,
                        height: 48,
                        child: GestureDetector(
                          onTap: () => _selectHotel(hotel),
                          child: _priceMarker(
                            hotel.minPricePerNight,
                            hotel.id == _selectedHotelId,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55FFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                color: Colors.white,
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ket qua tai',
                            style: TextStyle(fontSize: 11),
                          ),
                          Text(
                            widget.locationTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Bo loc',
                      icon: const Icon(Icons.tune),
                      onPressed: _openFilters,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: selectedHotel == null ? 24 : 160,
            child: Center(
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.list),
                label: Text('Xem danh sach (${_hotels.length})'),
              ),
            ),
          ),
          if (selectedHotel != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _hotelPreview(context, selectedHotel),
            ),
        ],
      ),
    );
  }

  Widget _priceMarker(double price, bool selected) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF61E294) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0D8A55), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
      ),
      child: Text(
        _shortPrice(price),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _hotelPreview(BuildContext context, ResortModel hotel) {
    return Material(
      color: Colors.white,
      elevation: 5,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResortDetailScreen(hotelId: hotel.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: hotel.coverImageUrl.isEmpty
                    ? Container(
                        width: 88,
                        height: 88,
                        color: Colors.grey[200],
                        child: const Icon(Icons.hotel),
                      )
                    : AppNetworkImage(
                        imageUrl: hotel.coverImageUrl,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 88,
                          height: 88,
                          color: Colors.grey[200],
                          child: const Icon(Icons.hotel),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${hotel.avgRating.toStringAsFixed(1)} sao - ${hotel.reviewCount} danh gia',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hotel.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '${_fullPrice(hotel.minPricePerNight)}/dem',
                      style: const TextStyle(
                        color: Color(0xFF0D8A55),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LatLng _fallbackCenter(String location) {
    final normalized = location.toLowerCase();
    if (normalized.contains('da lat') || normalized.contains('đà lạt')) {
      return const LatLng(11.9404, 108.4583);
    }
    if (normalized.contains('da nang') || normalized.contains('đà nẵng')) {
      return const LatLng(16.0544, 108.2022);
    }
    if (normalized.contains('nha trang'))
      return const LatLng(12.2388, 109.1967);
    if (normalized.contains('phu quoc')) return const LatLng(10.2899, 103.9840);
    return const LatLng(16.0471, 108.2068);
  }

  String _shortPrice(double price) => price >= 1000000
      ? '${(price / 1000000).toStringAsFixed(1)}tr'
      : '${(price / 1000).round()}k';

  String _fullPrice(double price) =>
      '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}d';
}
