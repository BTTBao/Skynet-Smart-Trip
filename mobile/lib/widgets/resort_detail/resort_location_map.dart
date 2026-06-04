import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/openstreetmap_geocoding_service.dart';

class ResortLocationMap extends StatefulWidget {
  const ResortLocationMap({
    super.key,
    required this.location,
    this.placeName = '',
    this.destinationName = '',
  });

  final String location;
  final String placeName;
  final String destinationName;

  @override
  State<ResortLocationMap> createState() => _ResortLocationMapState();
}

class _ResortLocationMapState extends State<ResortLocationMap> {
  final MapController _mapController = MapController();
  final OpenStreetMapGeocodingService _geocodingService =
      const OpenStreetMapGeocodingService();

  LatLng? _coordinates;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _geocodeLocation();
  }

  Future<void> _geocodeLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final queries = <String>{
      [
        widget.placeName,
        widget.location,
        widget.destinationName,
        'Vietnam',
      ].where((value) => value.trim().isNotEmpty).join(', '),
      [
        widget.location,
        widget.destinationName,
        'Vietnam',
      ].where((value) => value.trim().isNotEmpty).join(', '),
      [
        widget.placeName,
        widget.destinationName,
        'Vietnam',
      ].where((value) => value.trim().isNotEmpty).join(', '),
      widget.location,
    }.where((value) => value.trim().isNotEmpty);

    LatLng? coordinates;
    for (final query in queries) {
      try {
        coordinates = await _geocodingService.geocodeAddress(query);
        if (coordinates != null) break;
      } catch (_) {
        // Try the next, less-specific query.
      }
    }

    if (!mounted) return;
    setState(() {
      _coordinates = coordinates;
      _isLoading = false;
      _error = coordinates == null
          ? 'Không tìm thấy tọa độ từ địa chỉ này.'
          : null;
    });
  }

  Future<void> _openMap() async {
    final coordinates = _coordinates;
    final query = coordinates == null
        ? Uri.encodeComponent(
            [
              widget.placeName,
              widget.location,
            ].where((value) => value.trim().isNotEmpty).join(', '),
          )
        : '${coordinates.latitude},${coordinates.longitude}';
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _centerMap() {
    final coordinates = _coordinates;
    if (coordinates != null) _mapController.move(coordinates, 15);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Vị trí',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: _openMap,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Mở trong Maps'),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.location,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: _mapContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapContent() {
    if (_isLoading) {
      return const ColoredBox(
        color: Color(0xFFF1F5F3),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final coordinates = _coordinates;
    if (coordinates == null) {
      return ColoredBox(
        color: const Color(0xFFF1F5F3),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off_outlined, size: 36),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Không thể tải bản đồ.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _geocodeLocation,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                    FilledButton.icon(
                      onPressed: _openMap,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Mở Maps'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: coordinates,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.skynet.smarttrip.mobile',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: coordinates,
                  width: 160,
                  height: 70,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: _openMap,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            widget.placeName.isEmpty
                                ? 'Khách sạn'
                                : widget.placeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF0D8A55),
                          size: 34,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 10,
          bottom: 10,
          child: FloatingActionButton.small(
            heroTag: null,
            tooltip: 'Căn giữa bản đồ',
            onPressed: _centerMap,
            child: const Icon(Icons.center_focus_strong),
          ),
        ),
      ],
    );
  }
}
