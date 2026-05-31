import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/resort_model.dart';
import '../../models/create_trip_request.dart';
import '../../models/create_trip_itinerary_request.dart';
import '../../providers/trip_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/bus_service.dart';
import '../../widgets/checkout/checkout_stepper.dart';
import '../../widgets/checkout/resort_summary_card.dart';
import 'payment_success_screen.dart';
import 'payment_failed_screen.dart';

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
  int selectedPaymentMethod = 0; // 0: Credit Card, 1: MoMo, 2: Bank Transfer
  bool _isProcessing = false;

  String _formatDateRange() {
    final start = widget.checkIn;
    final end = widget.checkOut;
    return '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';
  }

  String _formatPriceFull(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$formatted₫';
  }

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);
    
    try {
      final profile = context.read<ProfileProvider>().profileData;
      final userId = int.tryParse(profile?.id ?? '') ?? 1;

      // Extract destination name from hotel address, e.g. "12 Hồ Xuân Hương, Đà Lạt" -> "Đà Lạt"
      final addressParts = widget.hotel.address.split(',');
      final destName = addressParts.isNotEmpty ? addressParts.last.trim() : 'Đà Lạt';

      // 1. Tạo Trip trên Backend
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

      final tripProvider = context.read<TripProvider>();
      final createdTrip = await tripProvider.createTrip(tripRequest);
      if (createdTrip == null) {
        throw Exception(tripProvider.error ?? 'Không thể khởi tạo chuyến đi trên hệ thống.');
      }

      // 2. Thêm phòng khách sạn vào Itinerary
      if (widget.selectedRoom == null) {
        throw Exception('Vui lòng chọn hạng phòng trước khi thanh toán.');
      }

      final itineraryRequest = CreateTripItineraryRequest(
        dayNumber: 1,
        serviceType: 'HOTEL',
        serviceId: widget.selectedRoom!.id,
        quantity: 1,
        bookedPrice: widget.totalPrice,
      );

      final itinerarySuccess = await tripProvider.addItinerary(createdTrip.tripId, itineraryRequest);
      if (!itinerarySuccess) {
        throw Exception(tripProvider.error ?? 'Không thể thêm thông tin phòng vào lịch trình.');
      }

      // 3. Thực hiện thanh toán / Confirm Payment
      final paymentMethodStr = selectedPaymentMethod == 0 
          ? 'Card' 
          : selectedPaymentMethod == 1 
              ? 'Momo' 
              : 'BankTransfer';

      final payService = BusService();
      final paymentSuccess = await payService.confirmPayment(
        tripId: createdTrip.tripId,
        paymentMethod: paymentMethodStr,
        transactionId: 'TXN-${createdTrip.tripId}-${DateTime.now().millisecondsSinceEpoch}',
        amount: widget.totalPrice,
      );

      if (!paymentSuccess) {
        throw Exception('Thanh toán thất bại từ cổng thanh toán.');
      }

      // Refresh trips list in background
      tripProvider.fetchTrips(silent: true);

      // 4. Chuyển hướng sang màn hình thành công
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              bookingId: createdTrip.tripId,
              hotelName: widget.hotel.name,
              dateRange: _formatDateRange(),
              roomInfo: '${widget.adultCount} Người lớn, ${widget.selectedRoom?.roomType ?? "Phòng Standard"}',
              imageUrl: widget.hotel.coverImageUrl,
              totalPrice: widget.totalPrice,
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
    final guestsText = '${widget.adultCount} Người lớn' + 
        (widget.childCount > 0 ? ', ${widget.childCount} Trẻ em' : '') +
        (widget.infantCount > 0 ? ', ${widget.infantCount} Em bé' : '');

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
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6DE899))),
                  SizedBox(height: 16),
                  Text('Đang xử lý thanh toán...', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentMethodOption(
                    index: 0,
                    icon: Icons.credit_card,
                    iconColor: Colors.blue,
                    title: 'Thẻ tín dụng/Ghi nợ',
                    subtitle: 'Visa, Mastercard, JCB',
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
                  const SizedBox(height: 24),
                  _buildPriceDetails(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: _isProcessing ? null : _buildBottomBar(context),
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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
    final double serviceFee = widget.totalPrice * 0.1; // 10% tax and service fee included
    final double basePrice = widget.totalPrice - serviceFee;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chi tiết giá', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Giá cơ bản phòng', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text(_formatPriceFull(basePrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thuế & Phí dịch vụ (10%)', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text(_formatPriceFull(serviceFee), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng cộng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_formatPriceFull(widget.totalPrice), style: TextStyle(color: Colors.green[400], fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Xác nhận & Thanh toán', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.black, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bằng cách nhấn thanh toán, bạn đồng ý với các Điều khoản & Chính sách của chúng tôi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            )
          ],
        ),
      ),
    );
  }
}
