import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/resort_model.dart';
import '../../models/create_trip_request.dart';
import '../../models/create_trip_itinerary_request.dart';
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
  final double totalPrice;
  final String fullName;
  final String email;
  final String phone;
  final String specialRequest;

  const PaymentConfirmScreen({
    Key? key,
    required this.hotel,
    this.selectedRoom,
    required this.checkIn,
    required this.checkOut,
    required this.adultCount,
    required this.childCount,
    required this.infantCount,
    required this.totalPrice,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.specialRequest,
  }) : super(key: key);

  @override
  State<PaymentConfirmScreen> createState() => _PaymentConfirmScreenState();
}

class _PaymentConfirmScreenState extends State<PaymentConfirmScreen> {
  int selectedPaymentMethod = 0; // 0: PayOS
  bool _isProcessing = false;
  int? _pendingOrderCode;
  int? _pendingTripId;

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
      final bool overlaps = (start1.isBefore(end2) || start1.isAtSameMomentAs(end2)) &&
                            (end1.isAfter(start2) || end1.isAtSameMomentAs(start2));
      if (overlaps) {
        return true;
      }
    }
    return false;
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
        _promoSuccessMessage = 'Áp dụng mã SUMMER15 thành công! Giảm 15% phòng khách sạn.';
      });
    } else if (code == 'LIMOSMART') {
      discount = widget.totalPrice > 30000 ? 30000.0 : widget.totalPrice;
      setState(() {
        _discountAmount = discount;
        _appliedPromoCode = code;
        _promoError = null;
        _promoSuccessMessage = 'Áp dụng mã LIMOSMART thành công! Giảm 30.000đ.';
      });
    } else if (code == 'FREE100') {
      discount = widget.totalPrice;
      setState(() {
        _discountAmount = discount;
        _appliedPromoCode = code;
        _promoError = null;
        _promoSuccessMessage = 'Áp dụng mã FREE100 thành công! Miễn phí 100% hóa đơn.';
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
                    'Chọn Voucher của bạn',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildVoucherCard(
                code: 'FREE100',
                title: 'Miễn phí đặt phòng khách sạn (100% OFF)',
                description: 'Áp dụng cho mọi resort. Giảm giá tối đa 100% tổng tiền phòng.',
                expiry: 'Hạn dùng: 31/12/2026',
              ),
              const SizedBox(height: 12),
              _buildVoucherCard(
                code: 'SUMMER15',
                title: 'Khuyến mãi hè rực rỡ (15% OFF)',
                description: 'Áp dụng cho mọi resort. Giảm giá 15% tổng tiền phòng khách sạn.',
                expiry: 'Hạn dùng: 30/09/2026',
              ),
              const SizedBox(height: 12),
              _buildVoucherCard(
                code: 'LIMOSMART',
                title: 'Trải nghiệm Limousine tiện nghi (-30k)',
                description: 'Giảm 30.000đ trực tiếp vào hóa đơn đặt phòng hoặc dịch vụ.',
                expiry: 'Hạn dùng: 31/08/2026',
              ),
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
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
            child: const Text(
              'Dùng',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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

  Future<void> _openPayOsCheckout(String checkoutUrl) async {
    final opened = await launchUrl(
      Uri.parse(checkoutUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      throw Exception('Khong the mo trang thanh toan PayOS.');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PayOS dang o trang thai ${payment.status}.')),
        );
        return;
      }

      final double finalPayPrice = widget.totalPrice - _discountAmount;

      context.read<TripProvider>().fetchTrips(silent: true);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            bookingId: tripId,
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
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text('Cảnh báo đặt trùng'),
              ],
            ),
            content: const Text(
              'Bạn đã có một đặt phòng/lịch trình khác trùng với khoảng thời gian này trên hệ thống. Bạn vẫn muốn tiếp tục chứ?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Quay lại', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6B42),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Tiếp tục', style: TextStyle(color: Colors.white)),
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

      final tripProvider = context.read<TripProvider>();
      int currentTripId;

      final double finalPayPrice = widget.totalPrice - _discountAmount;

      if (_pendingTripId != null) {
        currentTripId = _pendingTripId!;
      } else {
        final tripRequest = CreateTripRequest(
          userId: userId,
          title: widget.selectedRoom != null
              ? 'Đặt phòng: ${widget.hotel.name} (${widget.selectedRoom!.roomType})'
              : 'Đặt phòng: ${widget.hotel.name}',
          startDate: widget.checkIn,
          endDate: widget.checkOut,
          destinationName: destName,
          status: 'PENDING',
        );

        final createdTrip = await tripProvider.createTrip(tripRequest);
        if (createdTrip == null) {
          throw Exception(
            tripProvider.error ?? 'Không thể khởi tạo chuyến đi trên hệ thống.',
          );
        }
        currentTripId = createdTrip.tripId;

        final itineraryRequest = CreateTripItineraryRequest(
          dayNumber: 1,
          serviceType: 'HOTEL',
          serviceId: widget.hotel.id,
          quantity: 1,
          bookedPrice: finalPayPrice < 0 ? 0 : finalPayPrice,
        );

        final itinerarySuccess = await tripProvider.addItinerary(
          currentTripId,
          itineraryRequest,
        );
        if (!itinerarySuccess) {
          throw Exception(
            tripProvider.error ??
                'Không thể thêm thông tin phòng vào lịch trình.',
          );
        }
        _pendingTripId = currentTripId;
      }

      if (finalPayPrice <= 0) {
        final payService = BusService();
        final paymentSuccess = await payService.confirmPayment(
          tripId: currentTripId,
          paymentMethod: 'Promotion',
          transactionId: 'TXN-FREE-$currentTripId-${DateTime.now().millisecondsSinceEpoch}',
          amount: 0,
        );

        if (!paymentSuccess) {
          throw Exception('Không thể hoàn tất giao dịch khuyến mãi 0đ.');
        }

        tripProvider.fetchTrips(silent: true);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessScreen(
                bookingId: currentTripId,
                hotelName: widget.hotel.name,
                dateRange: _formatDateRange(),
                roomInfo:
                    '${widget.adultCount} Người lớn, ${widget.selectedRoom?.roomType ?? "Phòng Standard"}',
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

      if (selectedPaymentMethod == 0) { // PayOS - Thẻ tín dụng/Ghi nợ
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

      final paymentMethodStr = selectedPaymentMethod == 1
          ? 'Momo'
          : 'BankTransfer';

      final payService = BusService();
      final paymentSuccess = await payService.confirmPayment(
        tripId: currentTripId,
        paymentMethod: paymentMethodStr,
        transactionId:
            'TXN-$currentTripId-${DateTime.now().millisecondsSinceEpoch}',
        amount: finalPayPrice,
      );

      if (!paymentSuccess) {
        throw Exception('Thanh toán thất bại từ cổng thanh toán.');
      }

      tripProvider.fetchTrips(silent: true);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              bookingId: currentTripId,
              hotelName: widget.hotel.name,
              dateRange: _formatDateRange(),
              roomInfo:
                  '${widget.adultCount} Người lớn, ${widget.selectedRoom?.roomType ?? "Phòng Standard"}',
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
    final guestsText =
        '${widget.adultCount} Người lớn' +
        (widget.childCount > 0 ? ', ${widget.childCount} Trẻ em' : '') +
        (widget.infantCount > 0 ? ', ${widget.infantCount} Em bé' : '');

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
                      icon: Icons.account_balance_wallet,
                      iconColor: Colors.pink,
                      title: 'Ví MoMo',
                      subtitle: 'Thanh toán nhanh qua ứng dụng',
                    ),
                    _buildPaymentMethodOption(
                      index: 2,
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
          )
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
            child: const Icon(Icons.card_giftcard, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thanh toán khuyến mãi (0đ)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B5E20)),
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
    final double serviceFee = widget.totalPrice * 0.1; // 10% tax and service fee included
    final double basePrice = widget.totalPrice - serviceFee;

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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
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
                    hintText: 'Nhập SUMMER15, LIMOSMART, FREE100...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  backgroundColor: _appliedPromoCode == null ? const Color(0xFF0D6B42) : Colors.red[400],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(
                  _appliedPromoCode == null ? 'Áp dụng' : 'Hủy',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          if (_promoError != null) ...[
            const SizedBox(height: 6),
            Text(_promoError!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
          if (_promoSuccessMessage != null) ...[
            const SizedBox(height: 6),
            Text(_promoSuccessMessage!, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
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
                _formatPriceFull(basePrice),
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
                _formatPriceFull(serviceFee),
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
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500),
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
                    const Icon(Icons.arrow_forward, color: Colors.black, size: 20),
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
