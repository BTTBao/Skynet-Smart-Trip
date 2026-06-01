import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/openstreetmap_geocoding_service.dart';

class ResortLocationMap extends StatefulWidget {
  final String location;
  
  const ResortLocationMap({Key? key, required this.location}) : super(key: key);

  @override
  State<ResortLocationMap> createState() => _ResortLocationMapState();
}

class _ResortLocationMapState extends State<ResortLocationMap> {
  final OpenStreetMapGeocodingService _geocodingService = const OpenStreetMapGeocodingService();
  LatLng? _coordinates;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _geocodeLocation();
  }

  Future<void> _geocodeLocation() async {
    try {
      final latLng = await _geocodingService.geocodeAddress(widget.location);
      if (mounted) {
        setState(() {
          _coordinates = latLng;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openMap() async {
    final query = Uri.encodeComponent(widget.location);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vị trí',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _openMap,
                child: Text(
                  'Mở trong Maps',
                  style: TextStyle(color: Colors.green[500], fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.location,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D6B42)),
                      ),
                    )
                  : _coordinates == null
                      ? GestureDetector(
                          onTap: _openMap,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.network(
                                'https://images.unsplash.com/photo-1524661135-423995f22d0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              Container(color: Colors.black.withOpacity(0.4)),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.map_outlined, color: Colors.white, size: 36),
                                  SizedBox(height: 8),
                                  Text(
                                    'Bấm để xem vị trí trên Google Maps',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : FlutterMap(
                          options: MapOptions(
                            initialCenter: _coordinates!,
                            initialZoom: 14,
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
                                  point: _coordinates!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Colors.red,
                                    size: 38,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
            ),
          )
        ],
      ),
    );
  }
}
