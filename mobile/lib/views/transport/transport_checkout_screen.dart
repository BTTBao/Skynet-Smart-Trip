import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bus_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/trip_provider.dart';
import '../../models/create_trip_request.dart';
import '../../models/create_trip_itinerary_request.dart';
import '../../models/bus_schedule_model.dart';
import '../../services/payment_service.dart';
import 'transport_ticket_screen.dart';
import '../checkout/payment_failed_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class TransportCheckoutScreen extends StatefulWidget {
  const TransportCheckoutScreen({Key? key}) : super(key: key);

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
      } else {
        // 1. Tạo Trip trên Backend
        final tripRequest = CreateTripRequest(
          userId: userId,
          title:
              'Vé xe: ${schedule.companyName} (${schedule.fromDestName} - ${schedule.toDestName})',
          startDate: schedule.departureTime,
          endDate: schedule.arrivalTime,
          destinationName: schedule.toDestName,
          status: 'PENDING',
        );

        final createdTrip = await tripProvider.createTrip(tripRequest);
        if (createdTrip == null) {
          throw Exception(
            tripProvider.error ?? 'Không thể khởi tạo chuyến đi trên hệ thống.',
          );
        }
        currentTripId = createdTrip.tripId;

        // 2. Thêm vé xe khách vào Itinerary
        final itineraryRequest = CreateTripItineraryRequest(
          dayNumber: 1,
          serviceType: 'BUS',
          serviceId: schedule.id,
          quantity: seats.length,
          bookedPrice: totalPrice,
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
