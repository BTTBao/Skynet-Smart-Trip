import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bus_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/trip_provider.dart';
import '../../models/create_trip_request.dart';
import '../../models/create_trip_itinerary_request.dart';
import '../../models/bus_schedule_model.dart';
import '../../services/payment_service.dart';
import '../../services/catalog_service.dart';
import 'transport_ticket_screen.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF0D6B42);
const _kBg = Color(0xFFF4F7F5);

// ─── Screen ───────────────────────────────────────────────────────────────────

class TransportCheckoutScreen extends StatefulWidget {
  const TransportCheckoutScreen({
    super.key,
    this.existingTripId,
    this.itineraryDayNumber = 1,
  });

  final int? existingTripId;
  final int itineraryDayNumber;

  @override
  State<TransportCheckoutScreen> createState() =>
      _TransportCheckoutScreenState();
}

class _TransportCheckoutScreenState extends State<TransportCheckoutScreen> {
  int selectedPaymentMethod =
      0; // 0: MoMo, 1: ZaloPay, 2: ATM, 3: Visa, 4: VNPAY
  bool _isProcessing = false;
  int? _pendingOrderCode;
  int? _pendingTripId;
  int? _pendingItineraryId;

  double _discountAmount = 0.0;
  String? _appliedPromoCode;
  final TextEditingController _promoController = TextEditingController();
  String? _promoError;
  String? _promoSuccessMessage;

  Timer? _countdownTimer;
  int _secondsRemaining = 600; // 10 minutes

  // Passenger Form Fields
  bool _isPassengerTheUser = true;
  final _passengerFormKey = GlobalKey<FormState>();
  final TextEditingController _passengerNameController =
      TextEditingController();
  final TextEditingController _passengerPhoneController =
      TextEditingController();
  final TextEditingController _passengerEmailController =
      TextEditingController();
  final TextEditingController _passengerNotesController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Populate user profile info into passenger controllers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<ProfileProvider>().profileData;
      if (user != null) {
        _passengerNameController.text = user.name;
        _passengerPhoneController.text = user.phone;
        _passengerEmailController.text = user.email;
      }
    });
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _countdownTimer?.cancel();
        _handleHoldExpired();
      }
    });
  }

  void _handleHoldExpired() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Hết hạn giữ ghế',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Thời gian giữ ghế của bạn đã hết hạn (10 phút). Ghế đã được giải phóng để hành khách khác lựa chọn. Vui lòng thực hiện đặt vé lại.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              child: const Text('Quay lại chọn ghế'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _promoController.dispose();
    _passengerNameController.dispose();
    _passengerPhoneController.dispose();
    _passengerEmailController.dispose();
    _passengerNotesController.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatPrice(double price) {
    final fmt = price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$fmtđ';
  }

  String _formatDateFull(DateTime dt) =>
      '${dt.day} Tháng ${dt.month}, ${dt.year}';

  int _generateOrderCode(int tripId) {
    final timePart = DateTime.now().millisecondsSinceEpoch % 10000000000;
    return (timePart * 1000) + (tripId % 1000);
  }

  // ─── Payment logic (unchanged) ────────────────────────────────────────────

  Future<void> _openPayOsCheckout(String checkoutUrl) async {
    final opened = await launchUrl(
      Uri.parse(checkoutUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) throw Exception('Khong the mo trang thanh toan PayOS.');
  }

  Future<void> _openVnPayCheckout(String checkoutUrl) async {
    final opened = await launchUrl(
      Uri.parse(checkoutUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) throw Exception('Khong the mo trang thanh toan VNPAY.');
  }

  Future<void> _checkPayOsStatus(
    BusScheduleModel schedule,
    List<String> seats,
  ) async {
    final orderCode = _pendingOrderCode;
    final tripId = _pendingTripId;
    if (orderCode == null || tripId == null) return;

    setState(() => _isProcessing = true);
    try {
      final payment = await PaymentService().getPaymentByOrderCode(orderCode);
      if (!mounted) return;

      if (!payment.isPaid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PayOS dang o trang thai ${payment.status}.')),
        );
        return;
      }

      if (_appliedPromoCode != null) {
        context.read<ProfileProvider>().useVoucher(_appliedPromoCode!);
      }

      context.read<TripProvider>().fetchTrips(silent: true);
      if (widget.existingTripId != null) {
        context.read<TripProvider>().fetchTripDetail(widget.existingTripId!);
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => TransportTicketScreen(
            bookingId: tripId,
            itineraryId: widget.existingTripId == null ? _pendingItineraryId : null,
            destinationId: schedule.toDestId,
            destinationName: schedule.toDestName,
            schedule: schedule,
            seats: seats,
          ),
        ),
        (route) => route.isFirst,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showPayOsPendingDialog(
    BusScheduleModel schedule,
    List<String> seats,
  ) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Hoàn tất thanh toán',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Trang PayOS đã được mở. Sau khi thanh toán xong, quay lại app và bấm kiểm tra.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _checkPayOsStatus(schedule, seats);
              },
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              child: const Text('Kiểm tra thanh toán'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkVnPayStatus(
    BusScheduleModel schedule,
    List<String> seats,
  ) async {
    final orderCode = _pendingOrderCode;
    final tripId = _pendingTripId;
    if (orderCode == null || tripId == null) return;

    setState(() => _isProcessing = true);
    try {
      final payment = await PaymentService().getPaymentByOrderCode(orderCode);
      if (!mounted) return;

      if (!payment.isPaid) {
        final status = payment.status.toUpperCase();
        final message = payment.isFailed
            ? (payment.message?.trim().isNotEmpty == true
                  ? payment.message!
                  : 'VNPAY da tra ve trang thai $status.')
            : 'VNPAY dang o trang thai ${payment.status}.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return;
      }

      if (_appliedPromoCode != null) {
        context.read<ProfileProvider>().useVoucher(_appliedPromoCode!);
      }

      context.read<TripProvider>().fetchTrips(silent: true);
      if (widget.existingTripId != null) {
        context.read<TripProvider>().fetchTripDetail(widget.existingTripId!);
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => TransportTicketScreen(
            bookingId: tripId,
            schedule: schedule,
            seats: seats,
          ),
        ),
        (route) => route.isFirst,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showVnPayPendingDialog(
    BusScheduleModel schedule,
    List<String> seats,
  ) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Hoan tat thanh toan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
                await _checkVnPayStatus(schedule, seats);
              },
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              child: const Text('Kiem tra thanh toan'),
            ),
          ],
        );
      },
    );
  }

  Future<_SelectedTransportTrip> _createBookingOnlyTrip({
    required int userId,
    required BusScheduleModel schedule,
  }) async {
    final tripProvider = context.read<TripProvider>();
    final createdTrip = await tripProvider.createTrip(
      CreateTripRequest(
        userId: userId,
        destinationId: schedule.toDestId,
        destinationName: schedule.toDestName,
        title:
            'Hóa đơn vé xe - ${schedule.fromDestName} đến ${schedule.toDestName}',
        startDate: schedule.departureTime,
        endDate: schedule.arrivalTime,
        status: 'BOOKING_ONLY',
      ),
    );

    if (createdTrip == null) {
      throw Exception(tripProvider.error ?? 'Không thể tạo hóa đơn vé xe.');
    }

    return _SelectedTransportTrip(tripId: createdTrip.tripId, dayNumber: 1);
  }

  Future<void> _handlePayment(
    BuildContext context,
    BusProvider busProvider,
  ) async {
    final schedule = busProvider.selectedSchedule;
    final seats = busProvider.selectedSeatNumbers;

    if (schedule == null || seats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn chuyến xe và vị trí ghế ngồi trước.'),
        ),
      );
      return;
    }

    // Validate Passenger Info Form
    if (_passengerFormKey.currentState == null ||
        !_passengerFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin hành khách đi xe.'),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final profile = context.read<ProfileProvider>().profileData;
      final userId = int.tryParse(profile?.id ?? '') ?? 1;
      final totalPrice = schedule.price * seats.length;
      final finalPayPrice = totalPrice - _discountAmount;

      final tripProvider = context.read<TripProvider>();
      int currentTripId;

      if (_pendingTripId != null) {
        currentTripId = _pendingTripId!;
      } else if (widget.existingTripId != null) {
        currentTripId = widget.existingTripId!;

        final itineraryRequest = CreateTripItineraryRequest(
          dayNumber: widget.itineraryDayNumber,
          serviceType: 'BUS',
          serviceId: schedule.id,
          quantity: seats.length,
          bookedPrice: finalPayPrice < 0 ? 0 : finalPayPrice,
          bookedCommissionRate: 0.08,
          serviceDate: schedule.departureTime,
          departureTime:
              '${schedule.departureTime.hour.toString().padLeft(2, '0')}:${schedule.departureTime.minute.toString().padLeft(2, '0')}:00',
          serviceAddress: [
            '${schedule.fromDestName} → ${schedule.toDestName}',
            'Ghế: ${seats.join(', ')}',
          ].join(' • '),
          selectedSeats: seats.join(', '),
        );

        final itineraryId = await tripProvider.addItinerary(
          currentTripId,
          itineraryRequest,
        );
        if (itineraryId == null) {
          throw Exception(
            tripProvider.error ??
                'Không thể thêm thông tin vé xe vào lịch trình.',
          );
        }
        _pendingTripId = currentTripId;
      } else {
        // Luôn tạo chuyến đi tạm BOOKING_ONLY trước thanh toán
        final selectedTrip = await _createBookingOnlyTrip(userId: userId, schedule: schedule);
        currentTripId = selectedTrip.tripId;

        final itineraryRequest = CreateTripItineraryRequest(
          dayNumber: selectedTrip.dayNumber,
          serviceType: 'BUS',
          serviceId: schedule.id,
          quantity: seats.length,
          bookedPrice: finalPayPrice < 0 ? 0 : finalPayPrice,
          bookedCommissionRate: 0.08,
          serviceDate: schedule.departureTime,
          departureTime:
              '${schedule.departureTime.hour.toString().padLeft(2, '0')}:${schedule.departureTime.minute.toString().padLeft(2, '0')}:00',
          serviceAddress: [
            '${schedule.fromDestName} → ${schedule.toDestName}',
            'Ghế: ${seats.join(', ')}',
          ].join(' • '),
          selectedSeats: seats.join(', '),
        );

        final itineraryId = await tripProvider.addItinerary(
          currentTripId,
          itineraryRequest,
        );
        if (itineraryId == null) {
          throw Exception(
            tripProvider.error ??
                'Không thể thêm thông tin vé xe vào lịch trình.',
          );
        }
        _pendingItineraryId = itineraryId;
        _pendingTripId = currentTripId;
      }

      if (finalPayPrice <= 0) {
        final paymentSuccess = await busProvider.confirmCheckoutPayment(
          tripId: currentTripId,
          scheduleId: schedule.id,
          paymentMethod: 'Promotion',
          transactionId:
              'TXN-FREE-$currentTripId-${DateTime.now().millisecondsSinceEpoch}',
          amount: 0,
        );

        if (!paymentSuccess) {
          throw Exception(
            busProvider.error ?? 'Không thể xác nhận thanh toán khuyến mãi 0đ.',
          );
        }

        if (_appliedPromoCode != null) {
          context.read<ProfileProvider>().useVoucher(_appliedPromoCode!);
        }

        tripProvider.fetchTrips(silent: true);

        if (mounted && context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => TransportTicketScreen(
                bookingId: currentTripId,
                itineraryId: widget.existingTripId == null ? _pendingItineraryId : null,
                destinationId: schedule.toDestId,
                destinationName: schedule.toDestName,
                schedule: schedule,
                seats: seats,
              ),
            ),
            (route) => route.isFirst,
          );
        }
        return;
      }

      if (selectedPaymentMethod == 2 || selectedPaymentMethod == 3) {
        final orderCode = _generateOrderCode(currentTripId);
        final payment = await PaymentService().createPayOsPayment(
          tripId: currentTripId,
          amount: finalPayPrice < 0 ? 0 : finalPayPrice,
          description: 'Ve xe $currentTripId',
          orderCode: orderCode,
          metadata: {
            'type': 'BUS',
            'scheduleId': schedule.id,
            'selectedSeats': seats,
            'passengerName': _passengerNameController.text.trim(),
            'passengerPhone': _passengerPhoneController.text.trim(),
            'passengerEmail': _passengerEmailController.text.trim(),
            'passengerNotes': _passengerNotesController.text.trim(),
          },
        );

        final checkoutUrl = payment.checkoutUrl;
        if (checkoutUrl == null || checkoutUrl.isEmpty) {
          throw Exception('PayOS khong tra ve link thanh toan.');
        }

        _pendingOrderCode = orderCode;
        await _openPayOsCheckout(checkoutUrl);
        if (mounted) setState(() => _isProcessing = false);
        await _showPayOsPendingDialog(schedule, seats);
        return;
      }

      if (selectedPaymentMethod == 4) {
        final payment = await PaymentService().createVnPayPayment(
          tripId: currentTripId,
          amount: finalPayPrice < 0 ? 0 : finalPayPrice,
          description: 'Ve xe $currentTripId',
          metadata: {
            'type': 'BUS',
            'scheduleId': schedule.id,
            'selectedSeats': seats,
            'passengerName': _passengerNameController.text.trim(),
            'passengerPhone': _passengerPhoneController.text.trim(),
            'passengerEmail': _passengerEmailController.text.trim(),
            'passengerNotes': _passengerNotesController.text.trim(),
          },
        );

        final checkoutUrl = payment.checkoutUrl;
        if (checkoutUrl == null || checkoutUrl.isEmpty) {
          throw Exception('VNPAY khong tra ve link thanh toan.');
        }

        _pendingOrderCode = payment.orderCode;
        await _openVnPayCheckout(checkoutUrl);
        if (mounted) setState(() => _isProcessing = false);
        await _showVnPayPendingDialog(schedule, seats);
        return;
      }

      final paymentMethodStr = selectedPaymentMethod == 0 ? 'Momo' : 'Zalopay';

      final paymentSuccess = await busProvider.confirmCheckoutPayment(
        tripId: currentTripId,
        scheduleId: schedule.id,
        paymentMethod: paymentMethodStr,
        transactionId:
            'TXN-BUS-$currentTripId-${DateTime.now().millisecondsSinceEpoch}',
        amount: finalPayPrice < 0 ? 0 : finalPayPrice,
      );

      if (!paymentSuccess) {
        throw Exception(
          busProvider.error ?? 'Khong the xac nhan thanh toan chuyen xe.',
        );
      }

      if (_appliedPromoCode != null) {
        context.read<ProfileProvider>().useVoucher(_appliedPromoCode!);
      }

      tripProvider.fetchTrips(silent: true);
      if (widget.existingTripId != null) {
        tripProvider.fetchTripDetail(widget.existingTripId!);
      }

      if (mounted && context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => TransportTicketScreen(
              bookingId: currentTripId,
              itineraryId: widget.existingTripId == null ? _pendingItineraryId : null,
              destinationId: schedule.toDestId,
              destinationName: schedule.toDestName,
              schedule: schedule,
              seats: seats,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busProvider = context.watch<BusProvider>();
    final schedule = busProvider.selectedSchedule;
    final seats = busProvider.selectedSeatNumbers;

    if (schedule == null || seats.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thanh toán')),
        body: const Center(
          child: Text('Không tìm thấy thông tin đặt vé. Vui lòng chọn lại.'),
        ),
      );
    }

    final totalPrice = schedule.price * seats.length;
    final finalPayPrice = totalPrice - _discountAmount;

    return Scaffold(
      backgroundColor: _kBg,
      body: _isProcessing
          ? _buildProcessingState()
          : Column(
              children: [
                _buildGradientHeader(context),
                _buildTimerBanner(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Section: Booking info ──────────────────────────
                        _SectionLabel(
                          icon: Icons.confirmation_number_rounded,
                          label: 'Thông tin đặt vé',
                        ),
                        const SizedBox(height: 12),
                        _BoardingPassCard(
                          schedule: schedule,
                          seats: seats,
                          totalPrice: totalPrice,
                          formatPrice: _formatPrice,
                          formatDate: _formatDateFull,
                        ),
                        const SizedBox(height: 28),

                        // ── Section: Passenger Info ────────────────────────
                        _SectionLabel(
                          icon: Icons.person_rounded,
                          label: 'Thông tin hành khách',
                        ),
                        const SizedBox(height: 12),
                        _buildPassengerInfoCard(),
                        const SizedBox(height: 28),

                        // ── Section: Payment ───────────────────────────────
                        _SectionLabel(
                          icon: Icons.payment_rounded,
                          label: 'Phương thức thanh toán',
                        ),
                        const SizedBox(height: 12),
                        if (finalPayPrice <= 0)
                          _buildZeroAmountCard()
                        else ...[
                          _PaymentMethodCard(
                            index: 0,
                            selectedIndex: selectedPaymentMethod,
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: const Color(0xFFAE2070),
                            bgColor: const Color(0xFFFCE4EC),
                            title: 'Ví MoMo',
                            subtitle: 'Thanh toán nhanh qua ứng dụng',
                            badge: 'Phổ biến nhất',
                            onTap: () =>
                                setState(() => selectedPaymentMethod = 0),
                          ),
                          const SizedBox(height: 12),
                          _PaymentMethodCard(
                            index: 1,
                            selectedIndex: selectedPaymentMethod,
                            icon: Icons.payment_rounded,
                            iconColor: const Color(0xFF0068FF),
                            bgColor: const Color(0xFFE3F2FF),
                            title: 'ZaloPay',
                            subtitle: 'Thanh toán trực tuyến an toàn',
                            onTap: () =>
                                setState(() => selectedPaymentMethod = 1),
                          ),
                          const SizedBox(height: 12),
                          _PaymentMethodCard(
                            index: 2,
                            selectedIndex: selectedPaymentMethod,
                            icon: Icons.account_balance_rounded,
                            iconColor: const Color(0xFF37474F),
                            bgColor: const Color(0xFFECEFF1),
                            title: 'ATM / Mobile Banking',
                            subtitle: 'Hỗ trợ tất cả ngân hàng nội địa',
                            onTap: () =>
                                setState(() => selectedPaymentMethod = 2),
                          ),
                          const SizedBox(height: 12),
                          _PaymentMethodCard(
                            index: 3,
                            selectedIndex: selectedPaymentMethod,
                            icon: Icons.credit_card_rounded,
                            iconColor: const Color(0xFF00796B),
                            bgColor: const Color(0xFFE0F2F1),
                            title: 'Thẻ quốc tế',
                            subtitle: 'Visa, Mastercard, JCB',
                            onTap: () =>
                                setState(() => selectedPaymentMethod = 3),
                          ),
                          const SizedBox(height: 12),
                          _PaymentMethodCard(
                            index: 4,
                            selectedIndex: selectedPaymentMethod,
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: const Color(0xFF0068FF),
                            bgColor: const Color(0xFFEAF1FF),
                            title: 'VNPAY',
                            subtitle: 'Cong thanh toan VNPAY',
                            onTap: () =>
                                setState(() => selectedPaymentMethod = 4),
                          ),
                        ],
                        const SizedBox(height: 28),

                        // ── Section: Promo Code ────────────────────────────
                        const _SectionLabel(
                          icon: Icons.local_offer_rounded,
                          label: 'Ưu đãi & Khuyến mãi',
                        ),
                        const SizedBox(height: 12),
                        _buildPromoCodeSection(totalPrice),
                        const SizedBox(height: 28),

                        // ── Section: Detailed Price Breakdown ───────────────
                        const _SectionLabel(
                          icon: Icons.receipt_long_rounded,
                          label: 'Chi tiết giá',
                        ),
                        const SizedBox(height: 12),
                        _buildPriceDetailsSection(totalPrice),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _isProcessing
          ? null
          : _buildBottomBar(
              context,
              busProvider,
              finalPayPrice < 0 ? 0 : finalPayPrice,
            ),
    );
  }

  Widget _buildZeroAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC2E8D4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: _kPrimary, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thanh toán 0đ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _kPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Hóa đơn đã được giảm giá hoàn toàn. Không cần chọn phương thức thanh toán.',
                  style: TextStyle(color: Color(0xFF0A4F30), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection(double totalPrice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: _showVoucherSelectionSheet,
                child: const Text(
                  'Chọn Voucher',
                  style: TextStyle(
                    color: _kPrimary,
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
                      ? _kPrimary
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
        ],
      ),
    );
  }

  Future<void> _applyPromoCode() async {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _promoError = 'Vui lòng nhập mã giảm giá';
        _promoSuccessMessage = null;
      });
      return;
    }

    final busProvider = context.read<BusProvider>();
    final schedule = busProvider.selectedSchedule;
    final seats = busProvider.selectedSeatNumbers;
    if (schedule == null || seats.isEmpty) return;

    final totalPrice = schedule.price * seats.length;

    setState(() {
      _promoError = null;
      _promoSuccessMessage = null;
    });

    try {
      final promoData = await CatalogService().validatePromotion(code);
      if (promoData != null) {
        final double discountPercent = (promoData['discountPercent'] as num?)?.toDouble() ?? 0.0;
        final double maxDiscountAmount = (promoData['maxDiscountAmount'] as num?)?.toDouble() ?? 0.0;
        
        double discount = 0.0;
        String successMsg = '';
        if (discountPercent > 0) {
          discount = totalPrice * (discountPercent / 100.0);
          if (maxDiscountAmount > 0 && discount > maxDiscountAmount) {
            discount = maxDiscountAmount;
          }
          successMsg = 'Áp dụng mã $code thành công! Giảm ${discountPercent.toStringAsFixed(0)}% tổng tiền vé${maxDiscountAmount > 0 ? ' (Tối đa ${_formatPrice(maxDiscountAmount)})' : ''}.';
        } else if (maxDiscountAmount > 0) {
          discount = totalPrice > maxDiscountAmount ? maxDiscountAmount : totalPrice.toDouble();
          successMsg = 'Áp dụng mã $code thành công! Giảm ${_formatPrice(maxDiscountAmount)}.';
        } else {
          discount = 0.0;
          successMsg = 'Áp dụng mã $code thành công!';
        }

        setState(() {
          _discountAmount = discount;
          _appliedPromoCode = code;
          _promoError = null;
          _promoSuccessMessage = successMsg;
        });
      } else {
        setState(() {
          _promoError = 'Mã giảm giá không hợp lệ hoặc đã hết hạn.';
          _promoSuccessMessage = null;
          _discountAmount = 0.0;
          _appliedPromoCode = null;
        });
      }
    } catch (e) {
      setState(() {
        _promoError = 'Lỗi kết nối khi áp dụng mã giảm giá.';
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
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              if (activeVouchers.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      'Hiện không có mã khuyến mãi khả dụng.',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                )
              else
                ...activeVouchers.map((voucher) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildVoucherCard(
                      code: voucher.code,
                      title: voucher.code == 'SUMMER15'
                          ? 'Khuyến mãi hè rực rỡ (15% OFF)'
                          : 'Trải nghiệm Limousine tiện nghi (-30k)',
                      description: voucher.description,
                      expiry: voucher.expiry,
                      quantity: voucher.quantity,
                    ),
                  );
                }),
              const SizedBox(height: 16),
            ],
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
            color: Colors.black.withValues(alpha: 0.01),
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
                color: _kPrimary,
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
              backgroundColor: _kPrimary,
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

  Widget _buildPriceDetailsSection(double totalPrice) {
    final double serviceFee = totalPrice * 0.1; // 10% VAT and service fee
    final double basePrice = totalPrice - serviceFee;
    final double finalPayPrice = totalPrice - _discountAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              Text(
                'Giá vé gốc',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              Text(
                _formatPrice(basePrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thuế & Phí dịch vụ (10%)',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              Text(
                _formatPrice(serviceFee),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
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
                  '-${_formatPrice(_discountAmount)}',
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatPrice(finalPayPrice < 0 ? 0 : finalPayPrice),
                style: const TextStyle(
                  color: _kPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBanner() {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: const Color(0xFFFFF3CD),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFF856404), size: 18),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              text: 'Thời gian giữ ghế còn lại: ',
              style: const TextStyle(color: Color(0xFF856404), fontSize: 13),
              children: [
                TextSpan(
                  text: '$minutes:$seconds',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF721C24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A4F30), Color(0xFF0D6B42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Xác nhận đặt vé',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Step indicator
          Row(
            children: [
              _StepDot(
                step: 1,
                label: 'Chọn ghế',
                isDone: true,
                isActive: false,
              ),
              _StepLine(isActive: true),
              _StepDot(
                step: 2,
                label: 'Thanh toán',
                isDone: false,
                isActive: true,
              ),
              _StepLine(isActive: false),
              _StepDot(
                step: 3,
                label: 'Hoàn tất',
                isDone: false,
                isActive: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
          ),
          SizedBox(height: 20),
          Text(
            'Đang xử lý đặt vé xe...',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    BusProvider busProvider,
    double total,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng thanh toán',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Đã bao gồm thuế/phí',
                    style: TextStyle(
                      color: _kPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatPrice(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handlePayment(context, busProvider),
                    child: Container(
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
                      child: const Center(
                        child: Text(
                          'Xác nhận thanh toán',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerInfoCard() {
    final user = context.watch<ProfileProvider>().profileData;
    return Container(
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
      child: Form(
        key: _passengerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tôi là người đi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tự động điền thông tin cá nhân của bạn',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isPassengerTheUser,
                  onChanged: (val) {
                    setState(() {
                      _isPassengerTheUser = val;
                      if (val && user != null) {
                        _passengerNameController.text = user.name;
                        _passengerPhoneController.text = user.phone;
                        _passengerEmailController.text = user.email;
                      } else if (!val) {
                        _passengerNameController.clear();
                        _passengerPhoneController.clear();
                        _passengerEmailController.clear();
                      }
                    });
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: _kPrimary,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
            ),
            _buildPassengerTextField(
              label: 'Họ và tên hành khách',
              hint: 'Nhập họ và tên',
              controller: _passengerNameController,
              isRequired: true,
              enabled: !_isPassengerTheUser,
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập họ và tên hành khách';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildPassengerTextField(
              label: 'Số điện thoại',
              hint: 'Nhập số điện thoại liên hệ',
              controller: _passengerPhoneController,
              isRequired: true,
              enabled: !_isPassengerTheUser,
              keyboardType: TextInputType.phone,
              icon: Icons.phone_outlined,
              validator: (value) {
                final raw = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                if (raw.isEmpty) {
                  return 'Vui lòng nhập số điện thoại';
                }
                if (raw.length < 10 || raw.length > 11) {
                  return 'Số điện thoại không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildPassengerTextField(
              label: 'Email nhận vé',
              hint: 'Nhập email nhận vé điện tử',
              controller: _passengerEmailController,
              isRequired: true,
              enabled: !_isPassengerTheUser,
              keyboardType: TextInputType.emailAddress,
              icon: Icons.email_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập địa chỉ email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value.trim())) {
                  return 'Địa chỉ email không hợp lệ';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isRequired = false,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 13,
            ),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontSize: 14,
            color: enabled ? Colors.black87 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade100),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
            errorStyle: const TextStyle(height: 0.8, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

// ─── Step Dot ─────────────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.step,
    required this.label,
    required this.isDone,
    required this.isActive,
  });

  final int step;
  final String label;
  final bool isDone;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    Color dotBg;
    Widget dotChild;

    if (isDone) {
      dotBg = const Color(0xFF80ED99);
      dotChild = const Icon(
        Icons.check_rounded,
        color: Color(0xFF0A4F30),
        size: 14,
      );
    } else if (isActive) {
      dotBg = Colors.white;
      dotChild = Text(
        '$step',
        style: const TextStyle(
          color: _kPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    } else {
      dotBg = Colors.white.withValues(alpha: 0.3);
      dotChild = Text(
        '$step',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: dotBg, shape: BoxShape.circle),
          child: Center(child: dotChild),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive || isDone
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.only(bottom: 16),
        color: isActive
            ? const Color(0xFF80ED99)
            : Colors.white.withValues(alpha: 0.3),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _kPrimary, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// ─── Boarding Pass Card ───────────────────────────────────────────────────────

class _BoardingPassCard extends StatelessWidget {
  const _BoardingPassCard({
    required this.schedule,
    required this.seats,
    required this.totalPrice,
    required this.formatPrice,
    required this.formatDate,
  });

  final BusScheduleModel schedule;
  final List<String> seats;
  final double totalPrice;
  final String Function(double) formatPrice;
  final String Function(DateTime) formatDate;

  String _time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company + bus type
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: _kPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.companyName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Giường nằm ${schedule.totalSeats} chỗ',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D6B42), Color(0xFF1A9058)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'GIƯỜNG NẰM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Route visualizer
                Row(
                  children: [
                    // Departure
                    Column(
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
                        const SizedBox(height: 4),
                        Text(
                          _time(schedule.departureTime),
                          style: const TextStyle(
                            color: _kPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),

                    // Line
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Text(
                              schedule.duration,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: _kPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        height: 1.5,
                                        color: Colors.grey[200],
                                      ),
                                      const Icon(
                                        Icons.directions_bus_rounded,
                                        color: _kPrimary,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 8,
                                  height: 8,
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
                          ],
                        ),
                      ),
                    ),

                    // Arrival
                    Column(
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
                        const SizedBox(height: 4),
                        Text(
                          _time(schedule.arrivalTime),
                          style: const TextStyle(
                            color: _kPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Date row
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label: formatDate(schedule.departureTime),
                    ),
                    const SizedBox(width: 10),
                    _InfoChip(
                      icon:
                          schedule.departureTime.hour >= 18 ||
                              schedule.departureTime.hour <= 5
                          ? Icons.nights_stay_rounded
                          : Icons.wb_sunny_rounded,
                      label:
                          schedule.departureTime.hour >= 18 ||
                              schedule.departureTime.hour <= 5
                          ? 'Đêm'
                          : 'Ban ngày',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Boarding pass notch
          _TicketNotch(),

          // Bottom section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VỊ TRÍ GHẾ',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        seats.join(', '),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TỔNG CỘNG',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatPrice(totalPrice),
                      style: const TextStyle(
                        color: _kPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ticket Notch (Boarding Pass effect) ─────────────────────────────────────

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
          // Left semicircle
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
          // Right semicircle
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

// ─── Info Chip ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey[600]),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Payment Method Card ──────────────────────────────────────────────────────

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final int index;
  final int selectedIndex;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  bool get _isSelected => index == selectedIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isSelected ? _kPrimary : Colors.grey[200]!,
            width: _isSelected ? 2 : 1,
          ),
          boxShadow: _isSelected
              ? [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _isSelected ? _kPrimary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isSelected ? _kPrimary : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: _isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedTransportTrip {
  const _SelectedTransportTrip({required this.tripId, required this.dayNumber});

  final int tripId;
  final int dayNumber;
}
