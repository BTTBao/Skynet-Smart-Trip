import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../models/explore_post.dart';
import '../../services/openstreetmap_geocoding_service.dart';
import '../../utils/app_text.dart';
import 'explore_ui_constants.dart';

class ExploreMapSheet extends StatefulWidget {
  const ExploreMapSheet({super.key, required this.post});

  final ExplorePost post;

  @override
  State<ExploreMapSheet> createState() => _ExploreMapSheetState();
}

class _ExploreMapSheetState extends State<ExploreMapSheet> {
  static const _fallbackCenter = LatLng(16.0471, 108.2068);
  static const _geocoding = OpenStreetMapGeocodingService();

  LatLng? _postPosition;
  LatLng? _currentPosition;
  bool _isLoadingPost = true;
  bool _isLoadingCurrent = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _resolvePostPosition();
    _loadCurrentLocation();
  }

  Future<void> _resolvePostPosition() async {
    final lat = widget.post.latitude;
    final lng = widget.post.longitude;
    if (lat != null && lng != null) {
      setState(() {
        _postPosition = LatLng(lat, lng);
        _isLoadingPost = false;
      });
      return;
    }

    final resolved = await _geocoding.geocodeAddress(widget.post.location);
    if (!mounted) {
      return;
    }

    setState(() {
      _postPosition = resolved;
      _isLoadingPost = false;
      if (resolved == null) {
        _message = context.tr(
          vi: 'Chưa tìm được tọa độ chính xác cho địa điểm này.',
          en: 'Could not find exact coordinates for this location.',
        );
      }
    });
  }

  Future<void> _loadCurrentLocation() async {
    setState(() => _isLoadingCurrent = true);

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) {
          setState(() {
            _isLoadingCurrent = false;
            _message = context.tr(
              vi: 'GPS đang tắt. Bạn vẫn có thể xem vị trí bài viết.',
              en: 'GPS is off. You can still view the post location.',
            );
          });
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLoadingCurrent = false);
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingCurrent = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingCurrent = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postPosition = _postPosition ?? _fallbackCenter;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.location,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: ExploreColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr(
                                vi: 'Bản đồ OpenStreetMap',
                                en: 'OpenStreetMap',
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: ExploreColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: postPosition,
                          initialZoom: _postPosition == null ? 5.5 : 13,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.skynet.mobile',
                          ),
                          MarkerLayer(
                            markers: [
                              if (_postPosition != null)
                                Marker(
                                  point: _postPosition!,
                                  width: 54,
                                  height: 54,
                                  child: const _MapPin(
                                    icon: Icons.place_rounded,
                                    color: ExploreColors.primary,
                                  ),
                                ),
                              if (_currentPosition != null)
                                Marker(
                                  point: _currentPosition!,
                                  width: 44,
                                  height: 44,
                                  child: const _MapPin(
                                    icon: Icons.my_location_rounded,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (_isLoadingPost)
                        const Center(
                          child: CircularProgressIndicator(
                            color: ExploreColors.primary,
                          ),
                        ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: _MapLegend(
                          message: _message,
                          isLoadingCurrent: _isLoadingCurrent,
                          onLocate: _loadCurrentLocation,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({
    required this.message,
    required this.isLoadingCurrent,
    required this.onLocate,
  });

  final String? message;
  final bool isLoadingCurrent;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.place_rounded, color: ExploreColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message ??
                  context.tr(
                    vi: 'Marker xanh là vị trí bài viết.',
                    en: 'Green marker is the post location.',
                  ),
              style: const TextStyle(
                fontSize: 12,
                color: ExploreColors.textSecondary,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: isLoadingCurrent ? null : onLocate,
            icon: isLoadingCurrent
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded, size: 16),
            label: Text(context.tr(vi: 'Tôi', en: 'Me')),
          ),
        ],
      ),
    );
  }
}
