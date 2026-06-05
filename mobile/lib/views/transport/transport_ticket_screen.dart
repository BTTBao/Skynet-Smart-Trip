import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../models/bus_schedule_model.dart';
import '../../models/my_trip_summary.dart';
import '../../models/create_trip_request.dart';
import '../../models/update_trip_itinerary_request.dart';
import '../../providers/trip_provider.dart';
import '../../utils/file_saver.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF0D6B42);
const _kBg = Color(0xFFF4F7F5);

// ─── Screen ───────────────────────────────────────────────────────────────────

class TransportTicketScreen extends StatefulWidget {
  final int bookingId;
  final BusScheduleModel schedule;
  final List<String> seats;
  final int? itineraryId;
  final int? destinationId;
  final String? destinationName;

  const TransportTicketScreen({
    super.key,
    required this.bookingId,
    required this.schedule,
    required this.seats,
    this.itineraryId,
    this.destinationId,
    this.destinationName,
  });

  @override
  State<TransportTicketScreen> createState() => _TransportTicketScreenState();
}

String _getDefaultOriginForCity(String cityName) {
  final name = cityName.toLowerCase();
  if (name.contains('đà lạt') || name.contains('da lat')) {
    return 'Chợ Đà Lạt, Đà Lạt';
  } else if (name.contains('nha trang')) {
    return 'Tháp Trầm Hương, Nha Trang';
  } else if (name.contains('đà nẵng') || name.contains('da nang')) {
    return 'Cầu Rồng, Đà Nẵng';
  } else if (name.contains('hồ chí minh') ||
      name.contains('saigon') ||
      name.contains('hcm')) {
    return 'Chợ Bến Thành, Quận 1, Hồ Chí Minh';
  } else if (name.contains('hà nội') || name.contains('ha noi')) {
    return 'Hồ Hoàn Kiếm, Hà Nội';
  } else if (name.contains('vũng tàu') || name.contains('vung tau')) {
    return 'Bãi Sau, Vũng Tàu';
  } else if (name.contains('cần thơ') || name.contains('can tho')) {
    return 'Bến Ninh Kiều, Cần Thơ';
  } else if (name.contains('phú quốc') || name.contains('phu quoc')) {
    return 'Chợ đêm Phú Quốc, Kiên Giang';
  }
  return 'My Location';
}

class _TransportTicketScreenState extends State<TransportTicketScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isDownloading = false;
  bool _hasPrompted = false;
  bool _isAssociating = false;

  @override
  void initState() {
    super.initState();
    if (widget.itineraryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndPromptTripCreation();
      });
    }
  }

  Future<void> _checkAndPromptTripCreation() async {
    if (_hasPrompted) return;
    _hasPrompted = true;

    final wantsTrip = await _askTripCreationPreference();
    if (wantsTrip == true) {
      final selectedTrip = await _selectOrCreateTripForBooking(
        destinationId: widget.destinationId,
        destinationName: (widget.destinationName != null && widget.destinationName!.isNotEmpty)
            ? widget.destinationName!
            : 'Hành trình',
      );

      if (selectedTrip != null) {
        setState(() => _isAssociating = true);
        try {
          final tripProvider = context.read<TripProvider>();
          final success = await tripProvider.updateItinerary(
            widget.itineraryId!,
            UpdateTripItineraryRequest(
              tripId: selectedTrip.tripId,
              dayNumber: selectedTrip.dayNumber,
            ),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success
                    ? 'Đã thêm lịch trình vé xe vào chuyến đi thành công!'
                    : 'Không thể di chuyển lịch trình vào chuyến đi.'),
                backgroundColor: success ? const Color(0xFF0D6B42) : Colors.red,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isAssociating = false);
          }
        }
      }
    }
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool _tripDestinationMatchesSchedule(
    MyTripSummary trip,
  ) {
    if (widget.destinationId != null && trip.destinationId != null) {
      return trip.destinationId == widget.destinationId;
    }
    final destName = widget.destinationName ?? widget.schedule.toDestName;
    return trip.destination.trim().toLowerCase() ==
        destName.trim().toLowerCase();
  }

  String? _bookingTripBlockReason(
    MyTripSummary trip,
  ) {
    final departureDate = _dateOnly(widget.schedule.departureTime);
    final tripStart = _dateOnly(trip.startDate);
    final tripEnd = _dateOnly(trip.endDate);

    if (!_tripDestinationMatchesSchedule(trip)) {
      return 'Khác điểm đến với tuyến xe.';
    }

    if (tripStart.isAfter(departureDate) || tripEnd.isBefore(departureDate)) {
      return 'Ngày đi của chuyến xe không nằm trong chuyến đi này.';
    }

    return null;
  }

  int _dayNumberForTrip(MyTripSummary trip) {
    return _dateOnly(widget.schedule.departureTime)
            .difference(_dateOnly(trip.startDate))
            .inDays +
        1;
  }

  Future<bool?> _askTripCreationPreference() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bạn có muốn tạo chuyến đi không?'),
        content: const Text(
          'Nếu tạo chuyến đi, vé xe này sẽ được thêm vào lịch trình để bạn dễ dàng quản lý cùng chuyến đi của mình.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Không tạo'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tạo/chọn chuyến đi'),
          ),
        ],
      ),
    );
  }

  Future<_SelectedCheckoutTrip?> _selectOrCreateTripForBooking({
    required int? destinationId,
    required String destinationName,
  }) async {
    final tripProvider = context.read<TripProvider>();
    await tripProvider.fetchTrips(silent: true);

    if (!mounted) {
      return null;
    }

    final trips = tripProvider.upcomingTrips
        .where(
          (trip) =>
              trip.status != 'CANCELLED' &&
              _bookingTripBlockReason(trip) == null,
        )
        .toList(growable: false)
      ..sort((left, right) => left.startDate.compareTo(right.startDate));

    return showModalBottomSheet<_SelectedCheckoutTrip>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var isCreating = false;
        var title = 'Chuyến đi $destinationName';
        var query = '';

        Future<void> createTrip(StateSetter setSheetState) async {
          final normalizedTitle = title.trim();
          if (normalizedTitle.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vui lòng nhập tên chuyến đi.')),
            );
            return;
          }

          setSheetState(() => isCreating = true);
          final tripProvider = context.read<TripProvider>();
          final createdTrip = await tripProvider.createTrip(
            CreateTripRequest(
              userId: 1, // Default user ID, will be resolved by backend
              destinationId: destinationId,
              destinationName: destinationName,
              title: normalizedTitle,
              startDate: widget.schedule.departureTime,
              endDate: widget.schedule.arrivalTime,
              status: 'PENDING',
            ),
          );

          if (!sheetContext.mounted) {
            return;
          }

          setSheetState(() => isCreating = false);
          if (createdTrip == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(tripProvider.error ?? 'Không thể tạo chuyến đi.'),
              ),
            );
            return;
          }

          Navigator.of(sheetContext).pop(
            _SelectedCheckoutTrip(tripId: createdTrip.tripId, dayNumber: 1),
          );
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final normalizedQuery = query.trim().toLowerCase();
            final visibleTrips = normalizedQuery.isEmpty
                ? trips
                : trips
                    .where(
                      (trip) =>
                          trip.title.toLowerCase().contains(
                            normalizedQuery,
                          ) ||
                          trip.destination.toLowerCase().contains(
                            normalizedQuery,
                          ) ||
                          trip.dateRange.toLowerCase().contains(
                            normalizedQuery,
                          ),
                    )
                    .toList(growable: false);

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.88,
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: [
                      Center(
                        child: Container(
                          width: 56,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Thêm vào chuyến đi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chọn chuyến đi phù hợp với tuyến ${widget.schedule.fromDestName} → ${widget.schedule.toDestName}, hoặc tạo chuyến đi mới.',
                        style: const TextStyle(color: Colors.grey, height: 1.45),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        enabled: !isCreating,
                        onChanged: (value) =>
                            setSheetState(() => query = value),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          labelText: 'Tìm chuyến đi',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (visibleTrips.isEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            'Không tìm thấy chuyến đi phù hợp. Hãy tạo chuyến đi mới để tiếp tục đặt vé.',
                            style: TextStyle(color: Colors.grey, height: 1.45),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      ...visibleTrips.map((trip) {
                        final blockedReason = _bookingTripBlockReason(trip);
                        final canSelect = blockedReason == null;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: isCreating || !canSelect
                                ? null
                                : () => Navigator.of(sheetContext).pop(
                                    _SelectedCheckoutTrip(
                                      tripId: trip.tripId,
                                      dayNumber: _dayNumberForTrip(trip),
                                    ),
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: canSelect
                                    ? Colors.white
                                    : const Color(0xFFF8FAFC),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.map_rounded,
                                    color: Color(0xFF0D6B42),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          trip.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${trip.destination} • ${trip.dateRange}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (blockedReason != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            blockedReason,
                                            style: const TextStyle(
                                              color: Color(0xFFB42318),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    canSelect
                                        ? Icons.chevron_right_rounded
                                        : Icons.lock_outline_rounded,
                                    color: canSelect
                                        ? Colors.black87
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      TextField(
                        enabled: !isCreating,
                        controller: TextEditingController(text: title)
                          ..selection = TextSelection.collapsed(
                            offset: title.length,
                          ),
                        onChanged: (value) => title = value,
                        decoration: InputDecoration(
                          labelText: 'Tên chuyến đi mới',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isCreating
                              ? null
                              : () => createTrip(setSheetState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: isCreating
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Tạo chuyến đi mới',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _date(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  Future<ui.Image> _boundaryToImage(RenderRepaintBoundary boundary) {
    return boundary.toImage(pixelRatio: 3.0);
  }

  Future<void> _downloadTicket() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Đang tải vé điện tử về máy...'),
            ],
          ),
          backgroundColor: _kPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("Không thể tìm thấy khung hình vé.");
      }

      final image = await _boundaryToImage(boundary);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception("Không thể trích xuất dữ liệu hình ảnh.");
      }

      final bytes = byteData.buffer.asUint8List();
      final filename =
          'SmartTrip_Ticket_SKN_${widget.bookingId.toString().padLeft(6, '0')}.png';

      final success = await FileSaver.saveImage(bytes, filename);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success
                      ? Icons.check_circle_outline_rounded
                      : Icons.error_outline_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  success
                      ? 'Đã tải vé thành công!'
                      : 'Tải vé thất bại. Vui lòng thử lại.',
                ),
              ],
            ),
            backgroundColor: success ? _kPrimary : Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('Lỗi: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = 'SKN-${widget.bookingId.toString().padLeft(6, '0')}';

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Gradient Success Header ────────────────────────────────────────
              SliverToBoxAdapter(
                child: _SuccessHeader(code: code, context: context),
              ),

              // ── Boarding Pass Ticket ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: RepaintBoundary(
                    key: _boundaryKey,
                    child: _BoardingPassTicket(
                      bookingId: widget.bookingId,
                      schedule: widget.schedule,
                      seats: widget.seats,
                      formatTime: _time,
                      formatDate: _date,
                    ),
                  ),
                ),
              ),

              // ── Action Buttons ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ActionButtons(
                    schedule: widget.schedule,
                    context: context,
                    onDownload: _downloadTicket,
                  ),
                ),
              ),

              // ── Hotline note ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.headset_mic_rounded,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          text: 'Hỗ trợ: ',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          children: [
                            TextSpan(
                              text: widget.schedule.companyHotline,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isAssociating)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Đang xử lý chuyến đi...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

// ─── Success Header ───────────────────────────────────────────────────────────

class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader({required this.code, required this.context});

  final String code;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 36,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF064428), Color(0xFF0D6B42), Color(0xFF169655)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Back + "Vé của tôi" row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Vé của tôi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Success icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: _kPrimary,
              size: 44,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Đặt vé thành công!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mã đặt chỗ: $code',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Xuất trình mã QR bên dưới khi lên xe',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Boarding Pass Ticket ─────────────────────────────────────────────────────

class _BoardingPassTicket extends StatelessWidget {
  const _BoardingPassTicket({
    required this.bookingId,
    required this.schedule,
    required this.seats,
    required this.formatTime,
    required this.formatDate,
  });

  final int bookingId;
  final BusScheduleModel schedule;
  final List<String> seats;
  final String Function(DateTime) formatTime;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final code = 'SKN-${bookingId.toString().padLeft(6, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── QR Section ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              children: [
                // Label row
                Row(
                  children: [
                    const Icon(
                      Icons.directions_bus_rounded,
                      color: _kPrimary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'LIMOUSINE TICKET',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _kPrimary,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'SKN-${bookingId.toString().padLeft(6, '0')}',
                        style: const TextStyle(
                          color: _kPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // QR Code area
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D6B42), Color(0xFF0A4F30)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: code,
                          version: QrVersions.auto,
                          size: 110.0,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black87,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          code,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.8,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Quét mã QR khi lên xe',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),

          // ── Notch ────────────────────────────────────────────────────────
          _TicketNotch(),

          // ── Route section ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              children: [
                // Route row
                Row(
                  children: [
                    // From
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.fromDestName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${formatTime(schedule.departureTime)} • ${formatDate(schedule.departureTime)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bus icon
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: _kPrimary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 40,
                                height: 1.5,
                                color: Colors.grey[200],
                              ),
                              const Icon(
                                Icons.directions_bus_rounded,
                                color: _kPrimary,
                                size: 18,
                              ),
                              Container(
                                width: 40,
                                height: 1.5,
                                color: Colors.grey[200],
                              ),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey[400]!,
                                    width: 1.5,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            schedule.duration,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // To
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            schedule.toDestName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${formatTime(schedule.arrivalTime)} • ${formatDate(schedule.arrivalTime)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: Colors.grey[100], height: 1),
                const SizedBox(height: 16),

                // Info grid
                Row(
                  children: [
                    _TicketInfoField(
                      label: 'HÃNG XE',
                      value: schedule.companyName,
                    ),
                    const SizedBox(width: 16),
                    _TicketInfoField(
                      label: 'SỐ GHẾ',
                      value: seats.join(', '),
                      valueColor: _kPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Pickup info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: _kPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Điểm đón',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bến xe trung tâm ${schedule.fromDestName}. Có mặt trước giờ chạy 15 phút tại quầy ${schedule.companyName}.',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ticket Notch ─────────────────────────────────────────────────────────────

class _TicketNotch extends StatelessWidget {
  const _TicketNotch();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Dashed line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: List.generate(
                30,
                (i) => Expanded(
                  child: Container(
                    height: 1.5,
                    color: i.isEven
                        ? const Color(0xFFDDDDDD)
                        : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
          // Left notch
          Positioned(
            left: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: _kBg,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Right notch
          Positioned(
            right: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: _kBg,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ticket Info Field ────────────────────────────────────────────────────────

class _TicketInfoField extends StatelessWidget {
  const _TicketInfoField({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.schedule,
    required this.context,
    required this.onDownload,
  });

  final BusScheduleModel schedule;
  final BuildContext context;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Download ticket
        GestureDetector(
          onTap: onDownload,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D6B42), Color(0xFF1A9058)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Tải vé về máy',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Map button
        GestureDetector(
          onTap: () async {
            final startPoint = _getDefaultOriginForCity(schedule.fromDestName);
            final origin = Uri.encodeComponent(startPoint);
            final destination = Uri.encodeComponent(
              'Bến xe trung tâm ${schedule.fromDestName}',
            );
            final url = Uri.parse(
              'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination',
            );
            try {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Không thể mở bản đồ.'),
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kPrimary, width: 1.5),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_rounded, color: _kPrimary, size: 20),
                SizedBox(width: 10),
                Text(
                  'Xem bản đồ điểm đón',
                  style: TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Back to home
        GestureDetector(
          onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_rounded, color: Colors.grey[600], size: 20),
                const SizedBox(width: 10),
                Text(
                  'Về trang chủ',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedCheckoutTrip {
  final int tripId;
  final int dayNumber;

  _SelectedCheckoutTrip({required this.tripId, required this.dayNumber});
}
