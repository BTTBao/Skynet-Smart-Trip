import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bus_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/trip_provider.dart';
import '../../models/create_trip_request.dart';
import '../../models/create_trip_itinerary_request.dart';
import '../../models/bus_schedule_model.dart';
import '../../models/my_trip_summary.dart';
import '../../services/payment_service.dart';
import 'transport_ticket_screen.dart';
import '../checkout/payment_failed_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class TransportCheckoutScreen extends StatefulWidget {
  const TransportCheckoutScreen({
    Key? key,
    this.existingTripId,
    this.itineraryDayNumber = 1,
  }) : super(key: key);

  final int? existingTripId;
  final int itineraryDayNumber;

  @override
  State<TransportCheckoutScreen> createState() =>
      _TransportCheckoutScreenState();
}

class _TransportCheckoutScreenState extends State<TransportCheckoutScreen> {
  int selectedPaymentMethod = 0; // 0: MoMo, 1: ZaloPay, 2: ATM, 3: Visa
  bool _isProcessing = false;
  int? _pendingOrderCode;
  int? _pendingTripId;

  String _formatPrice(double price) {
    final formatted = price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formattedđ';
  }

  String _formatDateFull(DateTime dt) {
    return '${dt.day} Tháng ${dt.month}, ${dt.year}';
  }

  int _generateOrderCode(int tripId) {
    final timePart = DateTime.now().millisecondsSinceEpoch % 10000000000;
    return (timePart * 1000) + (tripId % 1000);
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
                await _checkPayOsStatus(schedule, seats);
              },
              child: const Text('Kiem tra thanh toan'),
            ),
          ],
        );
      },
    );
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  int _dayNumberForTrip(MyTripSummary trip, DateTime serviceDate) {
    return _dateOnly(serviceDate).difference(_dateOnly(trip.startDate)).inDays + 1;
  }

  bool _tripDestinationMatchesSchedule(
    MyTripSummary trip,
    BusScheduleModel schedule,
  ) {
    if (schedule.toDestId != null && trip.destinationId != null) {
      return trip.destinationId == schedule.toDestId;
    }

    return trip.destination.trim().toLowerCase() ==
        schedule.toDestName.trim().toLowerCase();
  }

  String? _transportTripBlockReason(MyTripSummary trip, BusScheduleModel schedule) {
    final departureDate = _dateOnly(schedule.departureTime);
    final tripStart = _dateOnly(trip.startDate);
    final tripEnd = _dateOnly(trip.endDate);

    if (!_tripDestinationMatchesSchedule(trip, schedule)) {
      return 'Khác điểm đến với tuyến xe.';
    }

    if (tripStart.isAfter(departureDate) || tripEnd.isBefore(departureDate)) {
      return 'Ngày đi của chuyến xe không nằm trong chuyến đi này.';
    }

    return null;
  }

  Future<_SelectedTransportTrip?> _selectOrCreateTripForBooking({
    required int userId,
    required BusScheduleModel schedule,
  }) async {
    final tripProvider = context.read<TripProvider>();
    await tripProvider.fetchTrips(silent: true);

    if (!mounted) {
      return null;
    }

    final trips = tripProvider.upcomingTrips
        .where((trip) =>
            trip.status != 'CANCELLED' &&
            _transportTripBlockReason(trip, schedule) == null)
        .toList(growable: false)
      ..sort((left, right) => left.startDate.compareTo(right.startDate));

    return showModalBottomSheet<_SelectedTransportTrip>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var isCreating = false;
        var title = 'Chuyến đi ${schedule.toDestName}';
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
          final createdTrip = await tripProvider.createTrip(
            CreateTripRequest(
              userId: userId,
              destinationId: schedule.toDestId,
              destinationName: schedule.toDestName,
              title: normalizedTitle,
              startDate: schedule.departureTime,
              endDate: schedule.arrivalTime,
              status: 'PENDING',
            ),
          );

          if (!sheetContext.mounted) {
            return;
          }

          setSheetState(() => isCreating = false);
          if (createdTrip == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tripProvider.error ?? 'Không thể tạo chuyến đi.')),
            );
            return;
          }

          Navigator.of(sheetContext).pop(
            _SelectedTransportTrip(tripId: createdTrip.tripId, dayNumber: 1),
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
                          trip.title.toLowerCase().contains(normalizedQuery) ||
                          trip.destination.toLowerCase().contains(normalizedQuery) ||
                          trip.dateRange.toLowerCase().contains(normalizedQuery),
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chọn chuyến đi phù hợp với tuyến ${schedule.fromDestName} → ${schedule.toDestName}, hoặc tạo chuyến đi mới.',
                        style: const TextStyle(color: Colors.grey, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        enabled: !isCreating,
                        onChanged: (value) => setSheetState(() => query = value),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          labelText: 'Tìm chuyến đi',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (visibleTrips.isNotEmpty) ...[
                        ...visibleTrips.map((trip) {
                          final blockedReason = _transportTripBlockReason(trip, schedule);
                          final canSelect = blockedReason == null;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: isCreating || !canSelect
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(
                                        _SelectedTransportTrip(
                                          tripId: trip.tripId,
                                          dayNumber: _dayNumberForTrip(
                                            trip,
                                            schedule.departureTime,
                                          ),
                                        ),
                                      ),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: canSelect ? Colors.white : const Color(0xFFF8FAFC),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.map_rounded, color: Color(0xFF0D6B42)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            trip.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${trip.destination} • ${trip.dateRange}',
                                            style: const TextStyle(color: Colors.grey),
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
                                      color: canSelect ? Colors.black87 : Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ] else ...[
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
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        enabled: !isCreating,
                        controller: TextEditingController(text: title)
                          ..selection = TextSelection.collapsed(offset: title.length),
                        onChanged: (value) => title = value,
                        decoration: InputDecoration(
                          labelText: 'Tên chuyến đi mới',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isCreating ? null : () => createTrip(setSheetState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6B42),
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

    setState(() => _isProcessing = true);

    try {
      final profile = context.read<ProfileProvider>().profileData;
      final userId = int.tryParse(profile?.id ?? '') ?? 1;
      final totalPrice = schedule.price * seats.length;

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
          bookedPrice: totalPrice,
          bookedCommissionRate: 0.08,
          serviceDate: schedule.departureTime,
          departureTime:
              '${schedule.departureTime.hour.toString().padLeft(2, '0')}:${schedule.departureTime.minute.toString().padLeft(2, '0')}:00',
          serviceAddress: [
            '${schedule.fromDestName} → ${schedule.toDestName}',
            'Ghế: ${seats.join(', ')}',
          ].join(' • '),
        );

        final itinerarySuccess = await tripProvider.addItinerary(
          currentTripId,
          itineraryRequest,
        );
        if (!itinerarySuccess) {
          throw Exception(
            tripProvider.error ??
                'Không thể thêm thông tin vé xe vào lịch trình.',
          );
        }
        _pendingTripId = currentTripId;
      } else {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        final selectedTrip = await _selectOrCreateTripForBooking(
          userId: userId,
          schedule: schedule,
        );
        if (selectedTrip == null) {
          return;
        }
        if (mounted) {
          setState(() => _isProcessing = true);
        }
        currentTripId = selectedTrip.tripId;
        // 2. Thêm vé xe khách vào Itinerary
        final itineraryRequest = CreateTripItineraryRequest(
          dayNumber: selectedTrip.dayNumber,
          serviceType: 'BUS',
          serviceId: schedule.id,
          quantity: seats.length,
          bookedPrice: totalPrice,
          bookedCommissionRate: 0.08,
          serviceDate: schedule.departureTime,
          departureTime:
              '${schedule.departureTime.hour.toString().padLeft(2, '0')}:${schedule.departureTime.minute.toString().padLeft(2, '0')}:00',
          serviceAddress: [
            '${schedule.fromDestName} → ${schedule.toDestName}',
            'Ghế: ${seats.join(', ')}',
          ].join(' • '),
        );

        final itinerarySuccess = await tripProvider.addItinerary(
          currentTripId,
          itineraryRequest,
        );
        if (!itinerarySuccess) {
          throw Exception(
            tripProvider.error ??
                'Không thể thêm thông tin vé xe vào lịch trình.',
          );
        }
        _pendingTripId = currentTripId;
      }

      // 3. Thực hiện thanh toán / Confirm Payment & Gán ghế
      if (selectedPaymentMethod == 2 || selectedPaymentMethod == 3) {
        // PayOS (ATM / Thẻ quốc tế)
        final orderCode = _generateOrderCode(currentTripId);
        final payment = await PaymentService().createPayOsPayment(
          tripId: currentTripId,
          amount: totalPrice,
          description: 'Ve xe $currentTripId',
          orderCode: orderCode,
          metadata: {
            'type': 'BUS',
            'scheduleId': schedule.id,
            'selectedSeats': seats,
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

      // Giả lập thanh toán nội bộ cho MoMo và ZaloPay
      final paymentMethodStr = selectedPaymentMethod == 0
          ? 'Momo'
          : 'Zalopay';

      final paymentSuccess = await busProvider.confirmCheckoutPayment(
        tripId: currentTripId,
        scheduleId: schedule.id,
        paymentMethod: paymentMethodStr,
        transactionId:
            'TXN-BUS-$currentTripId-${DateTime.now().millisecondsSinceEpoch}',
        amount: totalPrice,
      );

      if (!paymentSuccess) {
        throw Exception(
          busProvider.error ?? 'Thanh toán thất bại từ cổng thanh toán.',
        );
      }

      // Refresh list trips in background
      tripProvider.fetchTrips(silent: true);
      if (widget.existingTripId != null) {
        tripProvider.fetchTripDetail(widget.existingTripId!);
      }

      // 4. Chuyển hướng sang màn hình Chi tiết vé
      if (mounted && context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => TransportTicketScreen(
              bookingId: currentTripId,
              schedule: schedule,
              seats: seats,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi thanh toán: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PaymentFailedScreen()),
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

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D6B42)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thanh toán',
          style: TextStyle(
            color: Color(0xFF0D6B42),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF0D6B42),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Đang xử lý đặt vé xe...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'THÔNG TIN ĐẶT VÉ',
                      style: TextStyle(
                        color: Color(0xFF0D6B42),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTicketInfoCard(schedule, seats, totalPrice),
                    const SizedBox(height: 32),
                    const Text(
                      'PHƯƠNG THỨC THANH TOÁN',
                      style: TextStyle(
                        color: Color(0xFF0D6B42),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentMethod(
                      index: 0,
                      icon: Icons.account_balance_wallet,
                      iconColor: Colors.pink,
                      title: 'Ví MoMo',
                      subtitle: 'Thanh toán nhanh qua ứng dụng',
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentMethod(
                      index: 1,
                      icon: Icons.payment,
                      iconColor: Colors.blue,
                      title: 'ZaloPay',
                      subtitle: 'Thanh toán trực tuyến an toàn',
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentMethod(
                      index: 2,
                      icon: Icons.account_balance,
                      iconColor: Colors.grey[800]!,
                      title: 'ATM / Mobile Banking',
                      subtitle: 'Hỗ trợ tất cả ngân hàng nội địa',
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentMethod(
                      index: 3,
                      icon: Icons.credit_card,
                      iconColor: Colors.teal,
                      title: 'Thẻ quốc tế',
                      subtitle: 'Visa, Mastercard, JCB',
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _isProcessing
          ? null
          : _buildBottomBar(context, busProvider, totalPrice),
    );
  }

  Widget _buildTicketInfoCard(
    BusScheduleModel schedule,
    List<String> seats,
    double total,
  ) {
    final timeStartStr =
        '${schedule.departureTime.hour.toString().padLeft(2, '0')}:${schedule.departureTime.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              Expanded(
                child: Text(
                  '${schedule.fromDestName} ➔ ${schedule.toDestName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'GIƯỜNG NẰM',
                  style: TextStyle(
                    color: Color(0xFF0D6B42),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            schedule.companyName,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NGÀY KHỞI HÀNH',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateFull(schedule.departureTime),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GIỜ XUẤT BẾN',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$timeStartStr (${schedule.departureTime.hour >= 18 || schedule.departureTime.hour <= 5 ? 'Đêm' : 'Ngày'})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
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
                        fontSize: 15,
                        color: Color(0xFF0D6B42),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      _formatPrice(total),
                      style: const TextStyle(
                        color: Color(0xFF0D6B42),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod({
    required int index,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final bool isSelected = selectedPaymentMethod == index;
    return GestureDetector(
      onTap: () => setState(() => selectedPaymentMethod = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: const Color(0xFF0D6B42), width: 2)
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF0D6B42) : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    BusProvider busProvider,
    double total,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng tiền thanh toán',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Đã bao gồm thuế/phí',
                    style: TextStyle(
                      color: Color(0xFF0D6B42),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatPrice(total),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handlePayment(context, busProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6B42),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Xác nhận thanh toán',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedTransportTrip {
  const _SelectedTransportTrip({
    required this.tripId,
    required this.dayNumber,
  });

  final int tripId;
  final int dayNumber;
}
