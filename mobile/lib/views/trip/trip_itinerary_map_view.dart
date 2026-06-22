import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../models/trip_timeline_entry.dart';
import '../../providers/trip_provider.dart';
import '../../services/openstreetmap_geocoding_service.dart';
import 'trip_ui_constants.dart';

class TripItineraryMapView extends StatefulWidget {
  const TripItineraryMapView({
    super.key,
    required this.tripId,
    required this.tripTitle,
    required this.entries,
  });

  final int tripId;
  final String tripTitle;
  final List<TripTimelineEntry> entries;

  @override
  State<TripItineraryMapView> createState() => _TripItineraryMapViewState();
}

class _TripItineraryMapViewState extends State<TripItineraryMapView> {
  static const LatLng _fallbackCenter = LatLng(10.7769, 106.7009);

  final MapController _mapController = MapController();
  final OpenStreetMapGeocodingService _geocodingService =
      const OpenStreetMapGeocodingService();

  late final List<TripTimelineEntry> _sortedEntries;
  final Map<int, _MappedPoint> _pointsByItineraryId = <int, _MappedPoint>{};

  bool _isLoadingPoints = true;
  String? _mapError;
  _MappedPoint? _focusedPoint;

  List<LatLng> _osrmRouteCoordinates = <LatLng>[];

  Set<int> get _excludedFromRouteIds {
    return context.read<TripProvider>().mapRouteExcludedItineraryIds(
      widget.tripId,
    );
  }

  @override
  void initState() {
    super.initState();
    _sortedEntries = List<TripTimelineEntry>.from(widget.entries)
      ..sort(_compareEntries);

    _loadMapPoints();
  }

  Future<void> _fetchRoadRoute() async {
    final routePoints = _routePoints;
    if (routePoints.length < 2) {
      setState(() {
        _osrmRouteCoordinates = <LatLng>[];
      });
      return;
    }

    try {
      final coordsString = routePoints
          .map((point) => '${point.latLng.longitude},${point.latLng.latitude}')
          .join(';');

      final uri = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/$coordsString?overview=full&geometries=geojson');

      final response = await http.get(uri);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final routes = data['routes'];
        if (routes is List && routes.isNotEmpty) {
          final geometry = routes[0]['geometry'];
          final coordinates = geometry['coordinates'];
          if (coordinates is List) {
            final List<LatLng> roadCoords = [];
            for (final coord in coordinates) {
              if (coord is List && coord.length >= 2) {
                final double lon = double.parse(coord[0].toString());
                final double lat = double.parse(coord[1].toString());
                roadCoords.add(LatLng(lat, lon));
              }
            }
            setState(() {
              _osrmRouteCoordinates = roadCoords;
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('OSRM routing error: $e');
    }

    // Fallback
    setState(() {
      _osrmRouteCoordinates = routePoints.map((e) => e.latLng).toList();
    });
  }

  Future<void> _loadMapPoints() async {
    setState(() {
      _isLoadingPoints = true;
      _mapError = null;
    });

    final points = <int, _MappedPoint>{};
    int order = 1;

    for (final entry in _sortedEntries) {
      final id = entry.itineraryId;
      final address = (entry.serviceAddress ?? '').trim();
      if (id == null || address.isEmpty) {
        continue;
      }

      final cleanAddress = address.split('\n').first.trim();
      if (cleanAddress.isEmpty) {
        continue;
      }

      final latLng = await _geocodingService.geocodeAddress(cleanAddress);
      if (latLng == null) {
        continue;
      }

      points[id] = _MappedPoint(entry: entry, latLng: latLng, order: order++);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _pointsByItineraryId
        ..clear()
        ..addAll(points);
      _isLoadingPoints = false;
      if (points.isEmpty) {
        _mapError =
            'Chưa tìm thấy tọa độ nào. Vui lòng bổ sung địa chỉ đầy đủ cho các dịch vụ.';
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        _fitCameraToVisiblePoints();
        await _fetchRoadRoute();
      }
    });
  }

  void _fitCameraToVisiblePoints() {
    final points = _mappedPointsInTime;
    if (points.isEmpty) {
      return;
    }

    if (points.length == 1) {
      _mapController.move(points.first.latLng, 14);
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points.map((e) => e.latLng).toList()),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  List<_MappedPoint> get _mappedPointsInTime {
    final points = _sortedEntries
        .map((entry) {
          final id = entry.itineraryId;
          if (id == null) {
            return null;
          }
          return _pointsByItineraryId[id];
        })
        .whereType<_MappedPoint>()
        .toList();

    return points;
  }

  List<_MappedPoint> get _routePoints {
    return _mappedPointsInTime.where((point) {
      final id = point.entry.itineraryId;
      return id != null && !_excludedFromRouteIds.contains(id);
    }).toList();
  }

  void _toggleRouteExclusion(TripTimelineEntry entry, bool isExcluded) {
    final id = entry.itineraryId;
    if (id == null) {
      return;
    }

    context.read<TripProvider>().setMapRouteItineraryExcluded(
      widget.tripId,
      id,
      isExcluded,
    );

    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        _fitCameraToVisiblePoints();
        await _fetchRoadRoute();
      }
    });
  }

  int _compareEntries(TripTimelineEntry a, TripTimelineEntry b) {
    final dateCompare = _resolveDate(a).compareTo(_resolveDate(b));
    if (dateCompare != 0) {
      return dateCompare;
    }

    final timeCompare = _resolveMinutesOfDay(
      a.departureTime,
    ).compareTo(_resolveMinutesOfDay(b.departureTime));
    if (timeCompare != 0) {
      return timeCompare;
    }

    return (a.itineraryId ?? 0).compareTo(b.itineraryId ?? 0);
  }

  DateTime _resolveDate(TripTimelineEntry entry) {
    if (entry.serviceDate != null) {
      final date = entry.serviceDate!;
      return DateTime(date.year, date.month, date.day);
    }

    return DateTime(2100, 1, (entry.dayNumber ?? 1).clamp(1, 28));
  }

  int _resolveMinutesOfDay(String? rawTime) {
    final time = (rawTime ?? '').trim();
    if (time.isEmpty) {
      return 24 * 60;
    }

    final parts = time.split(':');
    if (parts.length < 2) {
      return 24 * 60;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return 24 * 60;
    }

    return (hour * 60) + minute;
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Chưa chọn ngày';
    }

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatShortTime(String? rawTime) {
    if (rawTime == null || rawTime.trim().isEmpty) return '';
    final parts = rawTime.trim().split(':');
    if (parts.length < 2) return rawTime.trim();
    return '${parts[0]}:${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final visiblePoints = _mappedPointsInTime;

    return Scaffold(
      backgroundColor: TripUiColors.background,
      body: Column(
        children: [
          // Premium AppBar
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D7A3E), Color(0xFF18A558)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lộ trình trên bản đồ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            widget.tripTitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!_isLoadingPoints)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${visiblePoints.length} điểm',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Map area
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: const MapOptions(
                        initialCenter: _fallbackCenter,
                        initialZoom: 12,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.skynet.smarttrip.mobile',
                        ),
                        if (_osrmRouteCoordinates.length > 1)
                          PolylineLayer(
                            polylines: [
                                Polyline(
                                  points: _osrmRouteCoordinates,
                                  strokeWidth: 4.5,
                                  color: const Color(0xFF18A558),
                                ),
                            ],
                          ),
                        // Markers with order number + time
                        MarkerLayer(
                          markers: visiblePoints.asMap().entries.map((entry) {
                            final index = entry.key;
                            final point = entry.value;
                            final orderNum = index + 1;
                            final timeStr = _formatShortTime(
                              point.entry.departureTime,
                            );
                            final isFocused =
                                _focusedPoint?.entry.itineraryId ==
                                point.entry.itineraryId;
                            final isExcluded =
                                point.entry.itineraryId != null &&
                                _excludedFromRouteIds
                                    .contains(point.entry.itineraryId);

                            return Marker(
                              point: point.latLng,
                              width: 72,
                              height: 68,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _focusedPoint = isFocused ? null : point;
                                  });
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Bubble label with time
                                    if (timeStr.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isExcluded
                                              ? Colors.grey.shade400
                                              : isFocused
                                              ? const Color(0xFF0D7A3E)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.15),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          timeStr,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: isExcluded
                                                ? Colors.white
                                                : isFocused
                                                ? Colors.white
                                                : TripUiColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    if (timeStr.isNotEmpty)
                                      const SizedBox(height: 2),
                                    // Circle marker with order number
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isExcluded
                                            ? Colors.grey.shade400
                                            : isFocused
                                            ? const Color(0xFF0D7A3E)
                                            : const Color(0xFF18A558),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$orderNum',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    if (_isLoadingPoints)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.8),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  color: TripUiColors.primaryGreen,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Đang tải tọa độ...',
                                  style: TextStyle(
                                    color: TripUiColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (!_isLoadingPoints && _mapError != null)
                      Positioned(
                        left: 12,
                        right: 12,
                        top: 12,
                        child: _MapNotice(text: _mapError!),
                      ),
                    if (_focusedPoint != null)
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: _MapInfoCard(
                          point: _focusedPoint!,
                          dateText:
                              _formatDate(_focusedPoint!.entry.serviceDate),
                          onClose: () => setState(() => _focusedPoint = null),
                        ),
                      ),
                    // Fit camera button
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Column(
                        children: [
                          _MapActionButton(
                            icon: Icons.fit_screen_rounded,
                            tooltip: 'Hiển thị tất cả',
                            onTap: _fitCameraToVisiblePoints,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Itinerary list
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8FFF0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.format_list_bulleted_rounded,
                            size: 17,
                            color: TripUiColors.timelineGreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.tripTitle,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: TripUiColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${_sortedEntries.length} điểm',
                          style: const TextStyle(
                            fontSize: 12,
                            color: TripUiColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _sortedEntries.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, indent: 54),
                      itemBuilder: (context, index) {
                        final entry = _sortedEntries[index];
                        final id = entry.itineraryId;
                        final isExcluded =
                            id != null && _excludedFromRouteIds.contains(id);
                        final hasAddress =
                            (entry.serviceAddress ?? '').trim().isNotEmpty;
                        final resolvedOnMap =
                            id != null &&
                            _pointsByItineraryId.containsKey(id);
                        final point =
                            id != null ? _pointsByItineraryId[id] : null;
                        final orderNum = point?.order;
                        final isFocused =
                            _focusedPoint?.entry.itineraryId == id;

                        return InkWell(
                          onTap: () {
                            if (point == null) return;
                            setState(() {
                              _focusedPoint = isFocused ? null : point;
                            });
                            if (!isFocused) {
                              _mapController.move(point.latLng, 15);
                            }
                          },
                          child: Container(
                            color: isFocused
                                ? const Color(0xFFE8FFF0)
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                // Order badge
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: resolvedOnMap && !isExcluded
                                        ? const Color(0xFF18A558)
                                        : isExcluded
                                        ? Colors.grey.shade300
                                        : const Color(0xFFE8FFF0),
                                  ),
                                  alignment: Alignment.center,
                                  child: orderNum != null
                                      ? Text(
                                          '$orderNum',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            color: resolvedOnMap && !isExcluded
                                                ? Colors.white
                                                : TripUiColors.textMuted,
                                          ),
                                        )
                                      : Icon(
                                          Icons.remove_circle_outline,
                                          size: 14,
                                          color: TripUiColors.textMuted,
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.caption,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isExcluded
                                              ? TripUiColors.textMuted
                                              : TripUiColors.textPrimary,
                                          decoration: isExcluded
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        [
                                          _formatDate(entry.serviceDate),
                                          if ((entry.departureTime ?? '')
                                              .isNotEmpty)
                                            _formatShortTime(
                                              entry.departureTime,
                                            ),
                                          if (hasAddress)
                                            entry.serviceAddress!.replaceAll('\n', ' - ')
                                          else
                                            'Chưa nhập địa chỉ',
                                        ].join(' • '),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: TripUiColors.textSecondary,
                                          height: 1.3,
                                        ),
                                      ),
                                      if (hasAddress && !resolvedOnMap && !_isLoadingPoints)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            'Không tìm được tọa độ',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Exclude from route toggle
                                if (id != null)
                                  GestureDetector(
                                    onTap: () => _toggleRouteExclusion(
                                      entry,
                                      !isExcluded,
                                    ),
                                    child: Tooltip(
                                      message: isExcluded
                                          ? 'Thêm vào tuyến'
                                          : 'Bỏ khỏi tuyến',
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isExcluded
                                              ? const Color(0xFFF1F4F6)
                                              : const Color(0xFFE8FFF0),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          isExcluded
                                              ? Icons.add_road_rounded
                                              : Icons.route_rounded,
                                          size: 16,
                                          color: isExcluded
                                              ? TripUiColors.textMuted
                                              : TripUiColors.timelineGreen,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MappedPoint {
  const _MappedPoint({
    required this.entry,
    required this.latLng,
    required this.order,
  });

  final TripTimelineEntry entry;
  final LatLng latLng;
  final int order;
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.onTap,
    this.tooltip = '',
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: TripUiColors.textSecondary),
        ),
      ),
    );
  }
}

class _MapNotice extends StatelessWidget {
  const _MapNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5D47B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Color(0xFF7B5E14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7B5E14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapInfoCard extends StatelessWidget {
  const _MapInfoCard({
    required this.point,
    required this.dateText,
    required this.onClose,
  });

  final _MappedPoint point;
  final String dateText;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final entry = point.entry;
    final timeStr =
        (entry.departureTime ?? '').trim().isEmpty
            ? 'Chưa chọn giờ'
            : _formatShortTime(entry.departureTime);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF18A558),
            ),
            alignment: Alignment.center,
            child: Text(
              '${point.order}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.caption,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: TripUiColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: TripUiColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TripUiColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: TripUiColors.timelineGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: TripUiColors.timelineGreen,
                      ),
                    ),
                  ],
                ),
                if ((entry.serviceAddress ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.serviceAddress!.replaceAll('\n', ' - '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TripUiColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: TripUiColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatShortTime(String? rawTime) {
    if (rawTime == null || rawTime.trim().isEmpty) return '';
    final parts = rawTime.trim().split(':');
    if (parts.length < 2) return rawTime.trim();
    return '${parts[0]}:${parts[1]}';
  }
}
