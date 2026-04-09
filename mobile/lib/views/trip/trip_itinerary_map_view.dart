import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/trip_timeline_entry.dart';
import '../../services/openstreetmap_geocoding_service.dart';
import 'trip_ui_constants.dart';

class TripItineraryMapView extends StatefulWidget {
  const TripItineraryMapView({
    super.key,
    required this.tripTitle,
    required this.entries,
  });

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
  final Set<int> _selectedItineraryIds = <int>{};

  bool _isLoadingPoints = true;
  String? _mapError;
  TripTimelineEntry? _focusedEntry;

  @override
  void initState() {
    super.initState();
    _sortedEntries = List<TripTimelineEntry>.from(widget.entries)
      ..sort(_compareEntries);

    for (final entry in _sortedEntries) {
      final id = entry.itineraryId;
      if (id != null) {
        _selectedItineraryIds.add(id);
      }
    }

    _loadMapPoints();
  }

  Future<void> _loadMapPoints() async {
    setState(() {
      _isLoadingPoints = true;
      _mapError = null;
    });

    final points = <int, _MappedPoint>{};

    for (final entry in _sortedEntries) {
      final id = entry.itineraryId;
      final address = (entry.serviceAddress ?? '').trim();
      if (id == null || address.isEmpty) {
        continue;
      }

      final latLng = await _geocodingService.geocodeAddress(address);
      if (latLng == null) {
        continue;
      }

      points[id] = _MappedPoint(entry: entry, latLng: latLng);
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
            'Chua tim thay toa do nao. Vui long bo sung dia chi day du cho cac dich vu.';
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fitCameraToVisiblePoints();
      }
    });
  }

  void _fitCameraToVisiblePoints() {
    final points = _visiblePoints;
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
        padding: const EdgeInsets.all(36),
      ),
    );
  }

  List<_MappedPoint> get _visiblePoints {
    final points = _sortedEntries
        .where((entry) {
          final id = entry.itineraryId;
          return id != null && _selectedItineraryIds.contains(id);
        })
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

  void _toggleEntrySelection(TripTimelineEntry entry, bool isSelected) {
    final id = entry.itineraryId;
    if (id == null) {
      return;
    }

    setState(() {
      if (isSelected) {
        _selectedItineraryIds.add(id);
      } else {
        _selectedItineraryIds.remove(id);
        if (_focusedEntry?.itineraryId == id) {
          _focusedEntry = null;
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fitCameraToVisiblePoints();
      }
    });
  }

  int _compareEntries(TripTimelineEntry a, TripTimelineEntry b) {
    final dateCompare = _resolveDate(a).compareTo(_resolveDate(b));
    if (dateCompare != 0) {
      return dateCompare;
    }

    final timeCompare = _resolveMinutesOfDay(a.departureTime)
        .compareTo(_resolveMinutesOfDay(b.departureTime));
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
      return 'Chua chon ngay';
    }

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final visiblePoints = _visiblePoints;

    return Scaffold(
      backgroundColor: TripUiColors.background,
      appBar: AppBar(
        title: const Text('Lo trinh tren map'),
        backgroundColor: Colors.white,
        foregroundColor: TripUiColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
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
                          if (visiblePoints.length > 1)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points:
                                      visiblePoints.map((e) => e.latLng).toList(),
                                  strokeWidth: 5,
                                  color: const Color(0xFF0A9E4E),
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: visiblePoints.map((point) {
                              return Marker(
                                point: point.latLng,
                                width: 42,
                                height: 42,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _focusedEntry = point.entry;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF0A9E4E),
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x22000000),
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.place_rounded,
                                      color: Color(0xFF0A9E4E),
                                      size: 24,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      if (_isLoadingPoints)
                        const Positioned.fill(
                          child: ColoredBox(
                            color: Color(0x99FFFFFF),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      if (!_isLoadingPoints && _mapError != null)
                        Positioned(
                          left: 12,
                          right: 12,
                          top: 12,
                          child: _MapNotice(text: _mapError!),
                        ),
                      if (_focusedEntry != null)
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: _MapInfoCard(
                            entry: _focusedEntry!,
                            dateText: _formatDate(_focusedEntry!.serviceDate),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                      child: Text(
                        '${widget.tripTitle} - Danh sach dich vu',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: TripUiColors.textPrimary,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _sortedEntries.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = _sortedEntries[index];
                          final id = entry.itineraryId;
                          final isChecked =
                              id != null && _selectedItineraryIds.contains(id);
                          final hasAddress =
                              (entry.serviceAddress ?? '').trim().isNotEmpty;
                          final resolvedOnMap =
                              id != null && _pointsByItineraryId.containsKey(id);

                          return CheckboxListTile(
                            value: isChecked,
                            onChanged: id == null
                                ? null
                                : (value) => _toggleEntrySelection(
                                      entry,
                                      value ?? false,
                                    ),
                            activeColor: const Color(0xFF0A9E4E),
                            title: Text(
                              entry.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: TripUiColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '${_formatDate(entry.serviceDate)} - ${entry.departureTime ?? 'Chua chon gio'}\n${hasAddress ? (entry.serviceAddress ?? '') : 'Chua nhap dia chi'}${hasAddress && !resolvedOnMap ? ' (khong tim thay toa do)' : ''}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
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
      ),
    );
  }
}

class _MappedPoint {
  const _MappedPoint({
    required this.entry,
    required this.latLng,
  });

  final TripTimelineEntry entry;
  final LatLng latLng;
}

class _MapNotice extends StatelessWidget {
  const _MapNotice({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5D47B)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF7B5E14),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MapInfoCard extends StatelessWidget {
  const _MapInfoCard({
    required this.entry,
    required this.dateText,
  });

  final TripTimelineEntry entry;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
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
          const SizedBox(height: 6),
          Text(
            'Ngay: $dateText',
            style: const TextStyle(fontSize: 12, color: TripUiColors.textSecondary),
          ),
          Text(
            'Gio: ${entry.departureTime ?? 'Chua chon gio'}',
            style: const TextStyle(fontSize: 12, color: TripUiColors.textSecondary),
          ),
          Text(
            'Dia chi: ${entry.serviceAddress ?? 'Chua nhap'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: TripUiColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
