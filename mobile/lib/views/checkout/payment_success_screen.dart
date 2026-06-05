import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/checkout/resort_summary_card.dart';
import '../main_shell.dart'; // To go back to home
import '../../providers/trip_provider.dart';
import '../../models/my_trip_summary.dart';
import '../../models/create_trip_request.dart';
import '../../models/update_trip_itinerary_request.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final int bookingId;
  final int? itineraryId;
  final int? destinationId;
  final String destinationName;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String hotelName;
  final String dateRange;
  final String roomInfo;
  final String imageUrl;
  final double totalPrice;
  final String paymentMethod;
  final DateTime paymentTime;

  const PaymentSuccessScreen({
    super.key,
    required this.bookingId,
    this.itineraryId,
    this.destinationId,
    this.destinationName = '',
    this.checkIn,
    this.checkOut,
    required this.hotelName,
    required this.dateRange,
    required this.roomInfo,
    required this.imageUrl,
    required this.totalPrice,
    required this.paymentMethod,
    required this.paymentTime,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
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
        destinationName: widget.destinationName.isNotEmpty ? widget.destinationName : 'Hành trình',
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
                    ? 'Đã thêm lịch trình đặt phòng vào chuyến đi thành công!'
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

  DateTime _lastUsedHotelDate(DateTime checkIn, DateTime checkOut) {
    final lastNight = checkOut.subtract(const Duration(days: 1));
    return lastNight.isBefore(checkIn) ? checkIn : lastNight;
  }

  bool _hotelDestinationMatchesTrip(
    MyTripSummary trip, {
    required int? destinationId,
    required String destinationName,
  }) {
    if (destinationId != null && trip.destinationId != null) {
      return trip.destinationId == destinationId;
    }
    return trip.destination.trim().toLowerCase() ==
        destinationName.trim().toLowerCase();
  }

  String? _bookingTripBlockReason(
    MyTripSummary trip, {
    int? destinationId,
    required String destinationName,
  }) {
    if (widget.checkIn == null || widget.checkOut == null) {
      return null;
    }
    final tripStart = _dateOnly(trip.startDate);
    final tripEnd = _dateOnly(trip.endDate);
    final bookingStart = _dateOnly(widget.checkIn!);
    final bookingEnd = _lastUsedHotelDate(widget.checkIn!, widget.checkOut!);

    if (!_hotelDestinationMatchesTrip(
      trip,
      destinationId: destinationId,
      destinationName: destinationName,
    )) {
      return 'Khác điểm đến với khách sạn.';
    }

    if (tripStart.isAfter(bookingStart) || tripEnd.isBefore(bookingEnd)) {
      return 'Ngày đi phải bao trọn ngày nhận/trả phòng.';
    }

    return null;
  }

  int _dayNumberForTrip(MyTripSummary trip) {
    if (widget.checkIn == null) return 1;
    return _dateOnly(widget.checkIn!)
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
          'Nếu tạo chuyến đi, booking này sẽ được thêm vào lịch trình để bạn dễ dàng quản lý cùng chuyến đi của mình.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Không tạo'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6DE899),
              foregroundColor: Colors.black,
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
              _bookingTripBlockReason(
                    trip,
                    destinationId: destinationId,
                    destinationName: destinationName,
                  ) ==
                  null,
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
              startDate: widget.checkIn ?? DateTime.now(),
              endDate: widget.checkOut ?? DateTime.now().add(const Duration(days: 1)),
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
                      const Text(
                        'Chọn chuyến đi có ngày bao trọn ngày nhận/trả phòng, hoặc tạo chuyến đi mới.',
                        style: TextStyle(color: Colors.grey, height: 1.4),
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
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            'Không có chuyến đi phù hợp với điểm đến khách sạn. Hãy tạo chuyến đi mới để tiếp tục đặt phòng.',
                            style: TextStyle(color: Colors.grey, height: 1.45),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      ...visibleTrips.map((trip) {
                        final blockedReason = _bookingTripBlockReason(trip, destinationId: destinationId, destinationName: destinationName);
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
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: canSelect
                                    ? Colors.white
                                    : const Color(0xFFF8FAFC),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                                borderRadius: BorderRadius.circular(14),
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
                                        : Icons.lock_outline,
                                    color: Colors.grey,
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
                        child: FilledButton(
                          onPressed: isCreating
                              ? null
                              : () => createTrip(setSheetState),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6DE899),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: isCreating
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Tạo chuyến đi mới',
                                  style: TextStyle(fontWeight: FontWeight.bold),
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

  String get _bookingCode => 'SKN-${widget.bookingId.toString().padLeft(6, '0')}';

  String _formatPrice(double price) {
    final formatted = price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formattedđ';
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute, ${dt.day} Thg ${dt.month} ${dt.year}';
  }

  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'Momo':
        return 'Ví điện tử MoMo';
      case 'Zalopay':
        return 'Ví điện tử ZaloPay';
      case 'BankTransfer':
      case 'Chuyen khoan ngan hang':
        return 'Chuyển khoản ngân hàng';
      case 'Promotion':
      case 'Khuyến mãi (0đ)':
      case 'Khuyen mai (0d)':
        return 'Khuyến mãi (0đ)';
      case 'PayOS':
        return 'PayOS';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainShell()),
            (route) => false,
          ),
        ),
        title: const Text(
          'Thanh toán',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Success Icon with glowing effect
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green[400],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 60),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Đặt chỗ thành công!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Mã đặt chỗ: ',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      Text(
                        _bookingCode,
                        style: TextStyle(
                          color: Colors.green[500],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Ticket details card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        ResortSummaryCard(
                          resortName: widget.hotelName,
                          dateRange: widget.dateRange,
                          roomInfo: widget.roomInfo,
                          imageUrl: widget.imageUrl.isNotEmpty
                              ? widget.imageUrl
                              : 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=200&q=80',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tổng số tiền thanh toán',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _formatPrice(widget.totalPrice),
                              style: TextStyle(
                                color: Colors.green[400],
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow(
                    'Hình thức thanh toán',
                    widget.paymentMethod == 'Momo'
                        ? 'Ví điện tử MoMo'
                        : widget.paymentMethod == 'Zalopay'
                        ? 'Ví điện tử ZaloPay'
                        : widget.paymentMethod == 'BankTransfer'
                        ? 'Chuyển khoản ngân hàng'
                        : 'Thẻ quốc tế',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Thời gian', _formatDateTime(widget.paymentTime)),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainShell(initialIndex: 3),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.luggage, color: Colors.black),
                      label: const Text(
                        'Xem chuyến đi',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigate back to home
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainShell()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.home, color: Color(0xFF1E293B)),
                      label: const Text(
                        'Về trang chủ',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          if (_isAssociating)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
