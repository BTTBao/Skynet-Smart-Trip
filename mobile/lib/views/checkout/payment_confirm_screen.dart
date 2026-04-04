import 'package:flutter/material.dart';
import '../../widgets/checkout/checkout_stepper.dart';
import '../../widgets/checkout/resort_summary_card.dart';
import 'payment_success_screen.dart';
import 'payment_failed_screen.dart';

class PaymentConfirmScreen extends StatefulWidget {
  const PaymentConfirmScreen({Key? key}) : super(key: key);

  @override
  State<PaymentConfirmScreen> createState() => _PaymentConfirmScreenState();
}

class _PaymentConfirmScreenState extends State<PaymentConfirmScreen> {
  int selectedPaymentMethod = 0; // 0: Credit Card, 1: MoMo, 2: Bank Transfer

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const CheckoutStepper(currentStep: 3),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ResortSummaryCard(
                resortName: 'Resort Sun Valley',
                dateRange: '15 Thg 10 - 17 Thg 10',
                roomInfo: '2 Người lớn, 1 Phòng',
                imageUrl: 'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
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
      bottomNavigationBar: _buildBottomBar(context),
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
              Text('Giá cơ bản (2 đêm)', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const Text('4.500.000₫', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thuế & Phí dịch vụ', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const Text('450.000₫', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Giảm giá (TRAVEL2024)', style: TextStyle(color: Colors.green[400], fontSize: 14)),
              Text('-200.000₫', style: TextStyle(color: Colors.green[400], fontWeight: FontWeight.bold, fontSize: 14)),
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
              Text('4.750.000₫', style: TextStyle(color: Colors.green[400], fontWeight: FontWeight.bold, fontSize: 20)),
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
                onPressed: () {
                   // Mock paying logic: we can randomly go to success or failed, but let's go to success by default
                   Navigator.pushAndRemoveUntil(
                     context,
                     MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
                     (route) => false, // Clear stack
                   );
                },
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
