import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/resort_model.dart';
import '../../models/create_trip_request.dart';
import '../../models/create_trip_itinerary_request.dart';
import '../../models/my_trip_summary.dart';
import '../../providers/hotel_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/bus_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/checkout/checkout_stepper.dart';
import '../../widgets/checkout/resort_summary_card.dart';
import 'payment_success_screen.dart';
import 'payment_failed_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentConfirmScreen extends StatefulWidget {
  final ResortModel hotel;
  final RoomModel? selectedRoom;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adultCount;
  final int childCount;
  final int infantCount;
  final int roomQuantity;
  final double totalPrice;
  final String fullName;
  final String email;
  final String phone;
  final String specialRequest;
  final int? existingTripId;
  final int? existingTripDayNumber;
  final DateTime? existingTripStartDate;
  final DateTime? existingTripEndDate;

  const PaymentConfirmScreen({
    super.key,
    required this.hotel,
    this.selectedRoom,
    required this.checkIn,
    required this.checkOut,
    required this.adultCount,
    required this.childCount,
    required this.infantCount,
    required this.roomQuantity,
    required this.totalPrice,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.specialRequest,
    this.existingTripId,
    this.existingTripDayNumber,
    this.existingTripStartDate,
    this.existingTripEndDate,
  });

  @override
  State<PaymentConfirmScreen> createState() => _PaymentConfirmScreenState();
}

class _PaymentConfirmScreenState extends State<PaymentConfirmScreen> {
  int selectedPaymentMethod = 0; // 0: PayOS, 1: VNPAY
  bool _isProcessing = false;
  int? _pendingOrderCode;
  int? _pendingTripId;
  int? _pendingItineraryId;

  double _discountAmount = 0.0;
  String? _appliedPromoCode;
  final TextEditingController _promoController = TextEditingController();
  String? _promoError;
  String? _promoSuccessMessage;
  bool _proceededWithOverlap = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  bool _hasOverlap() {
    final tripProvider = context.read<TripProvider>();
    for (final trip in tripProvider.trips) {
      if (trip.status == 'CANCELLED') continue;

      final start1 = trip.startDate;
      final end1 = trip.endDate;
      final start2 = widget.checkIn;
      final end2 = widget.checkOut;

      // Overlap condition: start1 <= end2 && end1 >= start2
      final bool overlaps =
          (start1.isBefore(end2) || start1.isAtSameMomentAs(end2)) &&
          (end1.isAfter(start2) || end1.isAtSameMomentAs(start2));
      if (overlaps) {
        return true;
      }
    }
    return false;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _lastUsedHotelDate(DateTime checkIn, DateTime checkOut) {
    final start = _dateOnly(checkIn);
    final end = _dateOnly(checkOut);
    if (!end.isAfter(start)) {
      return start;
    }
    return end.subtract(const Duration(days: 1));
  }

  int _resolveExistingTripDayNumber() {
    final tripStart = widget.existingTripStartDate;
    if (tripStart == null) {
      final fallbackDay = widget.existingTripDayNumber ?? 1;
      return fallbackDay < 1 ? 1 : fallbackDay;
    }

    final dayNumber =
        _dateOnly(widget.checkIn).difference(_dateOnly(tripStart)).inDays + 1;
    return dayNumber < 1 ? 1 : dayNumber;
  }

  String? _existingTripDateBlockReason() {
    if (widget.existingTripId == null) {
      return null;
    }

    final tripStart = widget.existingTripStartDate;
    final tripEnd = widget.existingTripEndDate;
    final checkIn = _dateOnly(widget.checkIn);
    final lastUsedDate = _lastUsedHotelDate(widget.checkIn, widget.checkOut);

    if (tripStart != null && checkIn.isBefore(_dateOnly(tripStart))) {
      return 'Ngày nhận phòng phải nằm trong thời gian chuyến đi.';
    }
    if (tripEnd != null && lastUsedDate.isAfter(_dateOnly(tripEnd))) {
      return 'Ngày trả phòng phải nằm trong thời gian chuyến đi.';
    }
    return null;
  }

  void _applyPromoCode() {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _promoError = 'Vui lòng nhập mã giảm giá';
        _promoSuccessMessage = null;
      });
      return;
    }

    double discount = 0.0;
    if (code == 'SUMMER15') {
      discount = widget.totalPrice * 0.15;
      setState(() {
        _discountAmount = discount;
        _appliedPromoCode = code;
        _promoError = null;
        _promoSuccessMessage =
            'Áp dụng mã SUMMER15 thành công! Giảm 15% phòng khách sạn.';
      });
    } else if (code == 'LIMOSMART') {
      discount = widget.totalPrice > 30000 ? 30000.0 : widget.totalPrice;
      setState(() {
        _discountAmount = discount;
        _appliedPromoCode = code;
        _promoError = null;
        _promoSuccessMessage = 'Áp dụng mã LIMOSMART thành công! Giảm 30.000đ.';
      });
    } else {
      setState(() {
        _promoError = 'Mã giảm giá không hợp lệ hoặc đã hết hạn.';
        _promoSuccessMessage = null;
        _discountAmount = 0.0;
        _appliedPromoCode = null;
      });
    }
  }

  void _showVoucherSelectionSheet() {
    final vouchers = context.read<ProfileProvider>().myVouchers;
    final activeVouchers = vouchers.where((v) => v.quantity > 0).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.75,
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chọn mã khuyến mãi khả dụng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: activeVouchers.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 24.0,
                              ),
                              child: Text(
                                'Hiện không có mã khuyến mãi khả dụng.',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: activeVouchers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final voucher = activeVouchers[index];
                              return _buildVoucherCard(
                                code: voucher.code,
                                title: voucher.code == 'SUMMER15'
                                    ? 'Khuyến mãi hè rực rỡ (15% OFF)'
                                    : 'Trải nghiệm tiện nghi (-30k)',
                                description: voucher.description,
                                expiry: voucher.expiry,
                                quantity: voucher.quantity,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoucherCard({
    required String code,
    required String title,
    required String description,
    required String expiry,
    required int quantity,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green[100]!),
            ),
            child: Text(
              code,
              style: const TextStyle(
                color: Color(0xFF0D6B42),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'x$quantity',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  expiry,
                  style: TextStyle(color: Colors.grey[400], fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _promoController.text = code;
                _applyPromoCode();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6B42),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Dùng',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange() {
    final start = widget.checkIn;
    final end = widget.checkOut;
    return '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';
  }

  String _formatPriceFull(double price) {
    final formatted = price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formatted₫';
  }

  int _generateOrderCode(int tripId) {
    final timePart = DateTime.now().millisecondsSinceEpoch % 10000000000;
    return (timePart * 1000) + (tripId % 1000);
  }

  String _selectedPaymentLabel() {
    switch (selectedPaymentMethod) {
      case 1:
        return 'MoMo';
      case 2:
        return 'Chuyen khoan ngan hang';
      default:
        return 'PayOS';
    }
  }

  Future<void> _openPayOsCheckout(String checkoutUrl) async {
    final opened = await launchUrl(
      Uri.parse(checkoutUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      throw Exception('Khong the mo trang thanh toan PayOS.');
    }
  }

  Future<void> _openVnPayCheckout(String checkoutUrl) async {
    final opened = await launchUrl(
      Uri.parse(checkoutUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      throw Exception('Khong the mo trang thanh toan VNPAY.');
    }
  }

  Future<void> _checkPayOsStatus() async {
    final orderCode = _pendingOrderCode;
    final tripId = _pendingTripId;
    if (orderCode == null || tripId == null) return;

    setState(() => _isProcessing = true);
    try {
      final payment = await PaymentService().getPaymentByOrderCode(orderCode);
      if (!mounted) return;

      if (!payment.isPaid) {
        final status = payment.status.toUpperCase();
        if (status == 'FAILED' ||
            status == 'CANCELLED' ||
            status == 'EXPIRED') {
          final finalPayPrice = (widget.totalPrice - _discountAmount)
              .clamp(0, double.infinity)
              .toDouble();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentFailedScreen(
                totalPrice: finalPayPrice,
                status: status,
                message:
                    'PayOS da tra ve trang thai ${_paymentStatusLabel(status)}. Chua co khoan tien nao duoc ghi nhan.',
                onRetry: _handlePayment,
              ),
            ),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PayOS dang o trang thai ${_paymentStatusLabel(payment.status)}.',
            ),
          ),
        );
        return;
      }

      if (_appliedPromoCode != null) {
        context.read<ProfileProvider>().useVoucher(_appliedPromoCode!);
      }

      final double finalPayPrice = widget.totalPrice - _discountAmount;

      await _syncAfterConfirmedPayment();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            bookingId: tripId,
            itineraryId: widget.existingTripId == null
                ? _pendingItineraryId
                : null,
            destinationId: widget.hotel.destinationId,
            destinationName: _hotelDestinationName,
            checkIn: widget.checkIn,
            checkOut: widget.checkOut,
            hotelName: widget.hotel.name,
            dateRange: _formatDateRange(),
            roomInfo:
                '${widget.adultCount} Nguoi lon, ${widget.selectedRoom?.roomType ?? "Phong Standard"}',
            imageUrl: widget.hotel.coverImageUrl,
            totalPrice: finalPayPrice < 0 ? 0 : finalPayPrice,
            paymentMethod: 'PayOS',
            paymentTime: payment.paidAt ?? DateTime.now(),
          ),
        ),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showPayOsPendingDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hoan tat thanh toan PayOS'),
          content: const Text(
            'Trang PayOS da duoc mo. Sau khi thanh toan xong, quay lai app va bam kiem tra.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('De sau'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _checkPayOsStatus();
              },
              child: const Text('Kiem tra thanh toan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkVnPayStatus() async {
    final orderCode = _pendingOrderCode;
    final tripId = _pendingTripId;
    if (orderCode == null || tripId == null) return;

    setState(() => _isProcessing = true);
    try {
      final payment = await PaymentService().getPaymentByOrderCode(orderCode);
      if (!mounted) return;

      if (!payment.isPaid) {
        final status = payment.status.toUpperCase();
        if (payment.isFailed) {
          final finalPayPrice = (widget.totalPrice - _discountAmount)
              .clamp(0, double.infinity)
              .toDouble();
          final failureMessage = payment.message?.trim().isNotEmpty == true
              ? payment.message!
              : 'VNPAY da tra ve trang thai $status. Chua co khoan tien nao duoc ghi nhan.';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentFailedScreen(
                totalPrice: finalPayPrice,
                status: status,
                message: failureMessage,
                onRetry: _handlePayment,
              ),
            ),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              payment.message?.trim().isNotEmpty == true
                  ? payment.message!
                  : 'VNPAY dang o trang thai ${payment.status}.',
            ),
          ),
        );
        return;
      }

      if (_appliedPromoCode != null) {
        context.read<ProfileProvider>().useVoucher(_appliedPromoCode!);
      }

      final double finalPayPrice = widget.totalPrice - _discountAmount;

      await _syncAfterConfirmedPayment();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            bookingId: tripId,
            itineraryId: widget.existingTripId == null
                ? _pendingItineraryId
                : null,
            destinationId: widget.hotel.destinationId,
            destinationName: _hotelDestinationName,
            checkIn: widget.checkIn,
            checkOut: widget.checkOut,
            hotelName: widget.hotel.name,
            dateRange: _formatDateRange(),
            roomInfo:
                '${widget.adultCount} Nguoi lon, ${widget.selectedRoom?.roomType ?? "Phong Standard"}',
            imageUrl: widget.hotel.coverImageUrl,
            totalPrice: finalPayPrice < 0 ? 0 : finalPayPrice,
            paymentMethod: 'VNPAY',
            paymentTime: payment.paidAt ?? DateTime.now(),
          ),
        ),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showVnPayPendingDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hoan tat thanh toan VNPAY'),
          content: const Text(
            'Trang VNPAY da duoc mo. Sau khi thanh toan xong, quay lai app va bam kiem tra.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('De sau'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _checkVnPayStatus();
              },
              child: const Text('Kiem tra thanh toan'),
            ),
          ],
        );
      },
    );
  }

  String _paymentStatusLabel(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'PAID':
        return 'da thanh toan';
      case 'PENDING':
        return 'cho thanh toan';
      case 'FAILED':
        return 'that bai';
      case 'CANCELLED':
      case 'CANCELED':
        return 'da huy';
      case 'EXPIRED':
        return 'het han';
      default:
        return raw;
    }
  }

  Future<void> _refreshHotelAvailability() async {
    final hotelProvider = context.read<HotelProvider>();
    await hotelProvider.fetchHotelDetail(widget.hotel.id, forceRefresh: true);
    await hotelProvider.fetchCalendar(
      widget.hotel.id,
      year: widget.checkIn.year,
      month: widget.checkIn.month,
      roomId: widget.selectedRoom?.id,
      forceRefresh: true,
    );

    if (widget.checkOut.year != widget.checkIn.year ||
        widget.checkOut.month != widget.checkIn.month) {
      await hotelProvider.fetchCalendar(
        widget.hotel.id,
        year: widget.checkOut.year,
        month: widget.checkOut.month,
        roomId: widget.selectedRoom?.id,
        forceRefresh: true,
      );
    }
  }

  Future<void> _syncAfterConfirmedPayment() async {
    try {
      await _refreshHotelAvailability();
      if (!mounted) return;
      final tripProvider = context.read<TripProvider>();
      await tripProvider.fetchTrips(silent: true);
      if (widget.existingTripId != null) {
        await tripProvider.fetchTripDetail(widget.existingTripId!);
      }
    } catch (_) {
      // Payment is already confirmed. A refresh failure must not turn it into
      // a failed-payment experience; data will synchronize on the next load.
    }
  }

  int _dayNumberForTrip(MyTripSummary trip) {
    return _dateOnly(
          widget.checkIn,
        ).difference(_dateOnly(trip.startDate)).inDays +
        1;
  }

  String get _hotelDestinationName {
    final destinationName = widget.hotel.destinationName.trim();
    if (destinationName.isNotEmpty) {
      return destinationName;
    }

    final addressParts = widget.hotel.address.split(',');
    return addressParts.isNotEmpty ? addressParts.last.trim() : '';
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
    String? destinationName,
  }) {
    final tripStart = _dateOnly(trip.startDate);
    final tripEnd = _dateOnly(trip.endDate);
    final bookingStart = _dateOnly(widget.checkIn);
    final bookingEnd = _lastUsedHotelDate(widget.checkIn, widget.checkOut);
    final hotelDestinationName = destinationName ?? _hotelDestinationName;

    if (!_hotelDestinationMatchesTrip(
      trip,
      destinationId: destinationId ?? widget.hotel.destinationId,
      destinationName: hotelDestinationName,
    )) {
      return 'Khác điểm đến với khách sạn.';
    }

    if (tripStart.isAfter(bookingStart) || tripEnd.isBefore(bookingEnd)) {
      return 'Ngày đi phải bao trọn ngày nhận/trả phòng.';
    }

    return null;
  }

  Future<_SelectedCheckoutTrip?> _createBookingOnlyTrip({
    required int userId,
    required int? destinationId,
    required String destinationName,
  }) async {
    final tripProvider = context.read<TripProvider>();
    final createdTrip = await tripProvider.createTrip(
      CreateTripRequest(
        userId: userId,
        destinationId: destinationId,
        destinationName: destinationName,
        title: 'Đặt phòng - ${widget.hotel.name}',
        startDate: widget.checkIn,
        endDate: widget.checkOut,
        status: 'BOOKING_ONLY',
      ),
    );

    if (createdTrip == null) {
      throw Exception(tripProvider.error ?? 'Không thể tạo đơn đặt phòng.');
    }

    return _SelectedCheckoutTrip(tripId: createdTrip.tripId, dayNumber: 1);
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    if (_hasOverlap() && !_proceededWithOverlap) {
      setState(() => _isProcessing = false);
      final bool? continueBooking = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: const [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                SizedBox(width: 8),
                Text('Cảnh báo đặt trùng'),
              ],
            ),
            content: const Text(
              'Bạn đã có một đặt phòng/lịch trình khác trùng với khoảng thời gian này trên hệ thống. Bạn vẫn muốn tiếp tục chứ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Quay lại',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6B42),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Tiếp tục',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );

      if (continueBooking != true) {
        return;
      }
      _proceededWithOverlap = true;
      setState(() => _isProcessing = true);
    }

    try {
      final profile = context.read<ProfileProvider>().profileData;
      final userId = int.tryParse(profile?.id ?? '') ?? 1;

      final addressParts = widget.hotel.address.split(',');
      final destName = addressParts.isNotEmpty
          ? addressParts.last.trim()
          : 'Đà Lạt';

      final hotelDestName = _hotelDestinationName.isNotEmpty
          ? _hotelDestinationName
          : destName;

      final tripProvider = context.read<TripProvider>();
      int currentTripId;

      final double finalPayPrice = widget.totalPrice - _discountAmount;
      final tripDateBlockReason = _existingTripDateBlockReason();
      if (tripDateBlockReason != null) {
        throw Exception(tripDateBlockReason);
      }

      if (_pendingTripId != null) {
        currentTripId = _pendingTripId!;
      } else {
        _SelectedCheckoutTrip? selectedTrip;
        if (widget.existingTripId != null) {
          selectedTrip = _SelectedCheckoutTrip(
            tripId: widget.existingTripId!,
            dayNumber: _resolveExistingTripDayNumber(),
          );
        } else {
          selectedTrip = await _createBookingOnlyTrip(
            userId: userId,
            destinationId: widget.hotel.destinationId,
            destinationName: hotelDestName,
          );
        }
        if (selectedTrip == null) {
          if (mounted) {
            setState(() => _isProcessing = false);
          }
          return;
        }
        currentTripId = selectedTrip.tripId;
        final itineraryRequest = CreateTripItineraryRequest(
          dayNumber: selectedTrip.dayNumber,
          serviceType: 'HOTEL',
          serviceId: widget.selectedRoom?.id ?? widget.hotel.id,
          quantity: widget.roomQuantity,
          bookedPrice: widget.totalPrice / widget.roomQuantity,
          serviceDate: widget.checkIn,
          hotelCheckOutDate: widget.checkOut,
          adultCount: widget.adultCount,
          childCount: widget.childCount,
          infantCount: widget.infantCount,
        );

        final itineraryId = await tripProvider.addItinerary(
          currentTripId,
          itineraryRequest,
        );
        if (itineraryId == null) {
          throw Exception(
            tripProvider.error ??
                'Không thể thêm thông tin phòng vào lịch trình.',
          );
        }
        _pendingItineraryId = itineraryId;
        await _refreshHotelAvailability();
        _pendingTripId = currentTripId;
      }

      if (finalPayPrice <= 0) {
        final payService = BusService();
        final paymentSuccess = await payService.confirmPayment(
          tripId: currentTripId,
          paymentMethod: 'Promotion',
          transactionId:
              'TXN-FREE-$currentTripId-${DateTime.now().millisecondsSinceEpoch}',
          amount: 0,
        );

        if (!paymentSuccess) {
          throw Exception('Không thể hoàn tất giao dịch khuyến mãi 0đ.');
        }

        if (_appliedPromoCode != null) {
          context.read<ProfileProvider>().useVoucher(_appliedPromoCode!);
        }
        await _syncAfterConfirmedPayment();

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessScreen(
                bookingId: currentTripId,
                itineraryId: widget.existingTripId == null
                    ? _pendingItineraryId
                    : null,
                destinationId: widget.hotel.destinationId,
                destinationName: _hotelDestinationName,
                checkIn: widget.checkIn,
                checkOut: widget.checkOut,
                hotelName: widget.hotel.name,
                dateRange: _formatDateRange(),
                roomInfo:
                    '${widget.adultCount} Người lớn, ${widget.roomQuantity} phòng, ${widget.selectedRoom?.roomType ?? "Phòng Standard"}',
                imageUrl: widget.hotel.coverImageUrl,
                totalPrice: 0,
                paymentMethod: 'Khuyến mãi (0đ)',
                paymentTime: DateTime.now(),
              ),
            ),
            (route) => false,
          );
        }
        return;
      }

      if (selectedPaymentMethod == 0) {
        // PayOS - Thẻ tín dụng/Ghi nợ
        final orderCode = _generateOrderCode(currentTripId);
        final payment = await PaymentService().createPayOsPayment(
          tripId: currentTripId,
          amount: finalPayPrice,
          description: 'Dat phong $currentTripId',
          orderCode: orderCode,
          metadata: {
            'type': 'HOTEL',
            'hotelId': widget.hotel.id,
            if (widget.selectedRoom != null) 'roomId': widget.selectedRoom!.id,
            'quantity': widget.roomQuantity,
          },
        );

        final checkoutUrl = payment.checkoutUrl;
        if (checkoutUrl == null || checkoutUrl.isEmpty) {
          throw Exception('PayOS khong tra ve link thanh toan.');
        }

        _pendingOrderCode = orderCode;
        await _openPayOsCheckout(checkoutUrl);
        if (mounted) setState(() => _isProcessing = false);
        await _showPayOsPendingDialog();
        return;
      }

      if (selectedPaymentMethod == 1) {
        final payment = await PaymentService().createVnPayPayment(
          tripId: currentTripId,
          amount: finalPayPrice,
          description: 'Dat phong $currentTripId',
          metadata: {
            'type': 'HOTEL',
            'hotelId': widget.hotel.id,
            if (widget.selectedRoom != null) 'roomId': widget.selectedRoom!.id,
            'quantity': widget.roomQuantity,
          },
        );

        final checkoutUrl = payment.checkoutUrl;
        if (checkoutUrl == null || checkoutUrl.isEmpty) {
          throw Exception('VNPAY khong tra ve link thanh toan.');
        }

        _pendingOrderCode = payment.orderCode;
        await _openVnPayCheckout(checkoutUrl);
        if (mounted) setState(() => _isProcessing = false);
        await _showVnPayPendingDialog();
        return;
      }

      final paymentMethodStr = selectedPaymentMethod == 2
          ? 'Momo'
          : 'BankTransfer';

      final payService = BusService();
      final paymentSuccess = await payService.confirmPayment(
        tripId: currentTripId,
        paymentMethod: paymentMethodStr,
        transactionId:
            'TXN-HOTEL-$currentTripId-${DateTime.now().millisecondsSinceEpoch}',
        amount: finalPayPrice,
      );

      if (!paymentSuccess) {
        throw Exception('Khong the xac nhan thanh toan dat phong.');
      }

      if (_appliedPromoCode != null) {
        context.read<ProfileProvider>().useVoucher(_appliedPromoCode!);
      }
      await _syncAfterConfirmedPayment();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              bookingId: currentTripId,
              itineraryId: widget.existingTripId == null
                  ? _pendingItineraryId
                  : null,
              destinationId: widget.hotel.destinationId,
              destinationName: _hotelDestinationName,
              checkIn: widget.checkIn,
              checkOut: widget.checkOut,
              hotelName: widget.hotel.name,
              dateRange: _formatDateRange(),
              roomInfo:
                  '${widget.adultCount} Người lớn, ${widget.roomQuantity} phòng, ${widget.selectedRoom?.roomType ?? "Phòng Standard"}',
              imageUrl: widget.hotel.coverImageUrl,
              totalPrice: finalPayPrice,
              paymentMethod: paymentMethodStr,
              paymentTime: DateTime.now(),
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đặt phòng: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        final finalPayPrice = (widget.totalPrice - _discountAmount)
            .clamp(0, double.infinity)
            .toDouble();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentFailedScreen(
              totalPrice: finalPayPrice,
              message: e.toString().replaceFirst('Exception: ', ''),
              onRetry: _handlePayment,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final guestsText =
        '${widget.adultCount} Người lớn${widget.childCount > 0 ? ', ${widget.childCount} Trẻ em' : ''}${widget.infantCount > 0 ? ', ${widget.infantCount} Em bé' : ''}, ${widget.roomQuantity} phòng';

    final double finalPayPrice = widget.totalPrice - _discountAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Xác nhận & Thanh toán',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF6DE899),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Đang xử lý thanh toán...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const CheckoutStepper(currentStep: 3),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ResortSummaryCard(
                      resortName: widget.hotel.name,
                      dateRange: _formatDateRange(),
                      roomInfo: guestsText,
                      imageUrl: widget.hotel.coverImageUrl.isNotEmpty
                          ? widget.hotel.coverImageUrl
                          : 'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Phương thức thanh toán',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (finalPayPrice <= 0)
                    _buildZeroAmountCard()
                  else ...[
                    _buildPaymentMethodOption(
                      index: 0,
                      icon: Icons.qr_code_2,
                      iconColor: Colors.blue,
                      title: 'Thẻ tín dụng/Ghi nợ',
                      subtitle: 'Quet QR hoac thanh toan qua ngan hang',
                    ),
                    _buildPaymentMethodOption(
                      index: 1,
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: const Color(0xFF0068FF),
                      title: 'VNPAY',
                      subtitle: 'Thanh toan qua cong VNPAY',
                    ),
                    _buildPaymentMethodOption(
                      index: 2,
                      icon: Icons.account_balance_wallet,
                      iconColor: Colors.pink,
                      title: 'Ví MoMo',
                      subtitle: 'Thanh toán nhanh qua ứng dụng',
                    ),
                    _buildPaymentMethodOption(
                      index: 3,
                      icon: Icons.account_balance,
                      iconColor: Colors.green,
                      title: 'Chuyển khoản ngân hàng',
                      subtitle: 'Vietcombank, Techcombank...',
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildPriceDetails(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: _isProcessing ? null : _buildBottomBar(context),
    );
  }

  Widget _buildZeroAmountCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[300]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thanh toán khuyến mãi (0đ)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đơn hàng được miễn phí 100% bằng mã giảm giá $_appliedPromoCode.',
                  style: TextStyle(color: Colors.green[800], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required int index,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final bool isSelected = selectedPaymentMethod == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green[400]! : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.green[400] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetails() {
    final double finalPayPrice = widget.totalPrice - _discountAmount;
    final selectedCapacity = widget.selectedRoom?.capacity ?? 2;
    final roomCapacity = selectedCapacity > 0 ? selectedCapacity : 1;
    final standardCapacity = roomCapacity * widget.roomQuantity;
    final extraGuestCount =
        (widget.adultCount + widget.childCount - standardCapacity)
            .clamp(0, widget.roomQuantity)
            .toInt();
    final nights = widget.checkOut
        .difference(widget.checkIn)
        .inDays
        .clamp(1, 365)
        .toInt();
    final extraGuestFee =
        (widget.selectedRoom?.pricePerNight ?? widget.hotel.minPricePerNight) *
        0.2 *
        nights *
        extraGuestCount;
    final roomPrice = widget.totalPrice - extraGuestFee;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mã giảm giá',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: _showVoucherSelectionSheet,
                child: const Text(
                  'Chọn Voucher',
                  style: TextStyle(
                    color: Color(0xFF0D6B42),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  enabled: _appliedPromoCode == null,
                  decoration: InputDecoration(
                    hintText: 'Nhập SUMMER15 hoặc LIMOSMART...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _appliedPromoCode == null
                    ? _applyPromoCode
                    : () {
                        setState(() {
                          _appliedPromoCode = null;
                          _discountAmount = 0.0;
                          _promoController.clear();
                          _promoSuccessMessage = null;
                          _promoError = null;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _appliedPromoCode == null
                      ? const Color(0xFF0D6B42)
                      : Colors.red[400],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _appliedPromoCode == null ? 'Áp dụng' : 'Hủy',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (_promoError != null) ...[
            const SizedBox(height: 6),
            Text(
              _promoError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (_promoSuccessMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _promoSuccessMessage!,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14.0),
            child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
          ),
          const Text(
            'Chi tiết giá',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giá cơ bản phòng',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              Text(
                _formatPriceFull(roomPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (extraGuestCount > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Phụ thu $extraGuestCount khách thêm',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Text(
                  _formatPriceFull(extraGuestFee),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          if (_discountAmount > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Khuyến mãi ($_appliedPromoCode)',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '-${_formatPriceFull(_discountAmount)}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatPriceFull(finalPayPrice < 0 ? 0 : finalPayPrice),
                style: TextStyle(
                  color: Colors.green[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final double finalPayPrice = widget.totalPrice - _discountAmount;

    return Container(
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.all(16.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      finalPayPrice <= 0
                          ? 'Xác nhận đặt miễn phí'
                          : 'Xác nhận & Thanh toán',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.black,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bằng cách nhấn thanh toán, bạn đồng ý với các Điều khoản & Chính sách của chúng tôi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedCheckoutTrip {
  const _SelectedCheckoutTrip({required this.tripId, required this.dayNumber});

  final int tripId;
  final int dayNumber;
}
