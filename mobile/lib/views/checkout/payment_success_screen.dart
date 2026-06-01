import 'package:flutter/material.dart';
import '../../widgets/checkout/resort_summary_card.dart';
import '../main_shell.dart'; // To go back to home
import '../trip/trip_itinerary_detail_view.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final int bookingId;
  final String hotelName;
  final String dateRange;
  final String roomInfo;
  final String imageUrl;
  final double totalPrice;
  final String paymentMethod;
  final DateTime paymentTime;

  const PaymentSuccessScreen({
    Key? key,
    required this.bookingId,
    required this.hotelName,
    required this.dateRange,
    required this.roomInfo,
    required this.imageUrl,
    required this.totalPrice,
    required this.paymentMethod,
    required this.paymentTime,
  }) : super(key: key);

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainShell()), (route) => false),
        ),
        title: const Text(
          'Thanh toán',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                  Text('Mã đặt chỗ: ', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  Text('ST$bookingId', style: TextStyle(color: Colors.green[500], fontWeight: FontWeight.bold, fontSize: 14)),
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
                      resortName: hotelName,
                      dateRange: dateRange,
                      roomInfo: roomInfo,
                      imageUrl: imageUrl.isNotEmpty
                          ? imageUrl
                          : 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=200&q=80',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tổng số tiền thanh toán', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        Text(_formatPrice(totalPrice), style: TextStyle(color: Colors.green[400], fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoRow('Hình thức thanh toán', paymentMethod == 'Momo' ? 'Ví điện tử MoMo' : paymentMethod == 'Zalopay' ? 'Ví điện tử ZaloPay' : paymentMethod == 'BankTransfer' ? 'Chuyển khoản ngân hàng' : 'Thẻ quốc tế'),
              const SizedBox(height: 12),
              _buildInfoRow('Thời gian', _formatDateTime(paymentTime)),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Reset stack to MainShell and push TripItineraryDetailView
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainShell()),
                      (route) => false,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripItineraryDetailView(
                          tripId: bookingId,
                          tripTitle: hotelName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.airplane_ticket, color: Colors.black),
                  label: const Text('Xem vé điện tử', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainShell()), (route) => false);
                  },
                  icon: const Icon(Icons.home, color: Color(0xFF1E293B)),
                  label: const Text('Về trang chủ', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
