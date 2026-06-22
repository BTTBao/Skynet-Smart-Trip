import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../services/destination_bounds.dart';
import '../../services/openstreetmap_geocoding_service.dart';
import '../../views/trip/trip_ui_constants.dart';

/// A text field widget that lets the user search for a place by name using
/// OpenStreetMap Nominatim. If multiple results are found, a bottom-sheet map
/// picker is shown so the user can choose the correct one visually.
///
/// If [destinationName] is provided (the trip destination selected at creation),
/// search results are restricted to that tourism area only.
///
/// The [onAddressConfirmed] callback is invoked with the display name of the
/// place selected / confirmed by the user.
class PlaceSearchField extends StatefulWidget {
  const PlaceSearchField({
    super.key,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.destinationName,
    required this.onAddressConfirmed,
  });

  final String? initialValue;
  final String? labelText;
  final String? hintText;

  /// The trip destination chosen at creation (e.g. "Đà Nẵng" from the DB list).
  /// Place search is restricted to this area.
  final String? destinationName;

  final ValueChanged<String> onAddressConfirmed;

  @override
  State<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<PlaceSearchField> {
  final OpenStreetMapGeocodingService _geocodingService =
      const OpenStreetMapGeocodingService();

  late final TextEditingController _controller;
  bool _isSearching = false;
  String? _confirmedAddress;

  /// Cached bounding box of the trip destination (loaded lazily).
  BoundingBox? _destinationBounds;
  bool _boundsLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _confirmedAddress = widget.initialValue;

    final name = widget.destinationName?.trim();
    if (name != null && name.isNotEmpty) {
      _destinationBounds = DestinationBoundsLookup.resolve(name);
      if (_destinationBounds != null) {
        _boundsLoaded = true;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Lazily fetch & cache the destination bounding box.
  Future<BoundingBox?> _getDestinationBounds() async {
    if (_boundsLoaded) return _destinationBounds;
    _boundsLoaded = true;

    final name = widget.destinationName;
    if (name == null || name.trim().isEmpty) return null;

    _destinationBounds =
        await _geocodingService.geocodeDestinationBounds(name);
    return _destinationBounds;
  }

  Future<void> _searchPlace() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    // Load destination bounds — search is scoped to the trip's selected destination.
    final bounds = await _getDestinationBounds();
    final destinationName = widget.destinationName?.trim();

    if (destinationName != null &&
        destinationName.isNotEmpty &&
        bounds == null) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không xác định được khu vực $destinationName. Vui lòng thử lại sau.',
          ),
        ),
      );
      return;
    }

    final searchResponse = await _geocodingService.searchPlaces(
      query,
      limit: 5,
      viewbox: bounds,
      destinationName: widget.destinationName,
    );
    final results = searchResponse.results;
    final hasMoreMatches = searchResponse.hasMoreMatches;

    if (!mounted) return;
    setState(() => _isSearching = false);

    if (results.isEmpty) {
      final destinationHint = widget.destinationName?.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            destinationHint != null && destinationHint.isNotEmpty
                ? 'Không tìm thấy địa điểm có "$query" trong khu vực $destinationHint. Hãy thử nhập tên cụ thể hơn.'
                : 'Không tìm thấy địa điểm. Hãy thử nhập tên khác.',
          ),
        ),
      );
      return;
    }

    GeocodingResult picked;

    if (results.length == 1) {
      picked = results.first;
    } else {
      // Multiple results → show map picker
      final selected = await showModalBottomSheet<GeocodingResult>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _PlaceMapPickerSheet(
          results: results,
          destinationBounds: bounds,
          hasMoreMatches: hasMoreMatches,
          destinationName: widget.destinationName,
        ),
      );
      if (selected == null || !mounted) return;
      picked = selected;
    }

    // Safety check — results should already be inside the destination bounds.
    if (bounds != null && !bounds.contains(picked.latLng)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Địa điểm đã chọn nằm ngoài khu vực du lịch. Vui lòng chọn lại.',
          ),
        ),
      );
      return;
    }

    _confirmAddress(picked.shortName);
  }

  void _confirmAddress(String address) {
    setState(() {
      _confirmedAddress = address;
      _controller.text = address;
    });
    widget.onAddressConfirmed(address);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TripUiColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _confirmedAddress != null && _confirmedAddress!.isNotEmpty
                  ? const Color(0xFF20B15A).withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (val) {
                    // Clear confirmed state when user types manually
                    if (_confirmedAddress != null) {
                      setState(() => _confirmedAddress = null);
                    }
                    widget.onAddressConfirmed(val);
                  },
                  onSubmitted: (_) => _searchPlace(),
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Nhập tên địa điểm...',
                    hintStyle: const TextStyle(
                      color: TripUiColors.textMuted,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.place_outlined,
                      color: TripUiColors.timelineGreen,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              // Search button
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isSearching
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 36,
                          height: 36,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: TripUiColors.timelineGreen,
                            ),
                          ),
                        )
                      : GestureDetector(
                          key: const ValueKey('search'),
                          onTap: _searchPlace,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: TripUiColors.timelineGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.search_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        if (_confirmedAddress != null && _confirmedAddress!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: TripUiColors.timelineGreen,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Đã xác nhận: $_confirmedAddress',
                    style: const TextStyle(
                      fontSize: 11,
                      color: TripUiColors.timelineGreen,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Map-based picker sheet
// ---------------------------------------------------------------------------

class _PlaceMapPickerSheet extends StatefulWidget {
  const _PlaceMapPickerSheet({
    required this.results,
    this.destinationBounds,
    this.hasMoreMatches = false,
    this.destinationName,
  });

  final List<GeocodingResult> results;
  final BoundingBox? destinationBounds;
  final bool hasMoreMatches;
  final String? destinationName;

  @override
  State<_PlaceMapPickerSheet> createState() => _PlaceMapPickerSheetState();
}

class _PlaceMapPickerSheetState extends State<_PlaceMapPickerSheet> {
  int? _hoveredIndex;

  LatLng get _mapCenter {
    if (widget.results.isEmpty) return const LatLng(16.047, 108.206);
    double lat = 0, lon = 0;
    for (final r in widget.results) {
      lat += r.latLng.latitude;
      lon += r.latLng.longitude;
    }
    return LatLng(lat / widget.results.length, lon / widget.results.length);
  }

  double _calcZoom() {
    if (widget.results.length == 1) return 14;
    double minLat = double.infinity,
        maxLat = -double.infinity,
        minLon = double.infinity,
        maxLon = -double.infinity;
    for (final r in widget.results) {
      if (r.latLng.latitude < minLat) minLat = r.latLng.latitude;
      if (r.latLng.latitude > maxLat) maxLat = r.latLng.latitude;
      if (r.latLng.longitude < minLon) minLon = r.latLng.longitude;
      if (r.latLng.longitude > maxLon) maxLon = r.latLng.longitude;
    }
    final latDiff = maxLat - minLat;
    final lonDiff = maxLon - minLon;
    final maxDiff = latDiff > lonDiff ? latDiff : lonDiff;
    if (maxDiff < 0.01) return 14;
    if (maxDiff < 0.05) return 12;
    if (maxDiff < 0.2) return 10;
    if (maxDiff < 1.0) return 8;
    return 6;
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7DDE3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8FFF0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.map_outlined,
                      color: TripUiColors.timelineGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chọn địa điểm phù hợp',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: TripUiColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.hasMoreMatches
                              ? 'Hiển thị ${widget.results.length} địa điểm đầu tiên trong khu vực ${widget.destinationName ?? 'du lịch'} — nhập tên cụ thể hơn để thu hẹp kết quả'
                              : 'Tìm thấy ${widget.results.length} kết quả trong khu vực ${widget.destinationName ?? 'du lịch'} — chạm vào điểm trên bản đồ hoặc chọn từ danh sách',
                          style: const TextStyle(
                            fontSize: 11,
                            color: TripUiColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (widget.hasMoreMatches) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: Color(0xFFF57C00),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Còn nhiều địa điểm phù hợp. Hãy nhập tên rõ hơn (ví dụ: thêm tên phố hoặc chi nhánh) để tìm nhanh hơn.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: Color(0xFF6D4C00),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const Divider(height: 1),

            // Map
            Expanded(
              flex: 5,
              child: ClipRRect(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _mapCenter,
                    initialZoom: _calcZoom(),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.skynet.smarttrip',
                    ),
                    MarkerLayer(
                      markers: widget.results.asMap().entries.map((entry) {
                        final index = entry.key;
                        final result = entry.value;
                        final isHovered = _hoveredIndex == index;

                        return Marker(
                          point: result.latLng,
                          width: 40,
                          height: 48,
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.of(context).pop(result),
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 150),
                                  width: isHovered ? 36 : 30,
                                  height: isHovered ? 36 : 30,
                                  decoration: BoxDecoration(
                                    color: isHovered
                                        ? TripUiColors.timelineGreen
                                        : Colors.white,
                                    border: Border.all(
                                      color: TripUiColors.timelineGreen,
                                      width: 2.5,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.18),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: isHovered
                                            ? Colors.white
                                            : TripUiColors.timelineGreen,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 2,
                                  height: 10,
                                  color: TripUiColors.timelineGreen,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Result list
            Expanded(
              flex: 4,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: widget.results.length,
                separatorBuilder: (_, idx) =>
                    const Divider(height: 1, indent: 56),
                itemBuilder: (context, index) {
                  final result = widget.results[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(result),
                    onHover: (hovering) {
                      setState(
                        () => _hoveredIndex = hovering ? index : null,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8FFF0),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: TripUiColors.timelineGreen,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.shortName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: TripUiColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  result.displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: TripUiColors.textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: TripUiColors.textMuted,
                            size: 20,
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
    );
  }
}
