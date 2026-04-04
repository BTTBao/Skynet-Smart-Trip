import 'package:flutter/material.dart';
import 'transport_ticket_screen.dart';

class TransportCheckoutScreen extends StatelessWidget {
  const TransportCheckoutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Thanh toán', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('THÔNG TIN ĐẶT VÉ', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 16),
              _buildTicketInfoCard(),
              const SizedBox(height: 32),
              const Text('PHƯƠNG THỨC THANH TOÁN', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 16),
              _buildPaymentMethod(
                icon: Icons.account_balance_wallet,
                iconColor: Colors.pink,
                title: 'Ví MoMo',
                subtitle: 'Thanh toán nhanh qua ứng dụng',
                isSelected: true,
              ),
              const SizedBox(height: 16),
              _buildPaymentMethod(
                icon: Icons.payment,
                iconColor: Colors.blue,
                title: 'ZaloPay',
                subtitle: 'Giảm ngay 20k cho khách mới',
                isSelected: false,
              ),
              const SizedBox(height: 16),
              _buildPaymentMethod(
                icon: Icons.account_balance,
                iconColor: Colors.grey[800]!,
                title: 'ATM / Mobile Banking',
                subtitle: 'Hỗ trợ tất cả ngân hàng nội địa',
                isSelected: false,
              ),
              const SizedBox(height: 16),
              _buildPaymentMethod(
                icon: Icons.credit_card,
                iconColor: Colors.teal,
                title: 'Thẻ quốc tế',
                subtitle: 'Visa, Mastercard, JCB',
                isSelected: false,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildTicketInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('TP. HCM ➔ Đà Lạt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.greenAccent[100], borderRadius: BorderRadius.circular(8)),
                child: const Text('VIP CLASS', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
              )
            ],
          ),
          const SizedBox(height: 4),
          Text('Hãng xe Limousine Cao Cấp', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NGÀY KHỞI HÀNH', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    const Text('24 Tháng 12,\n2024', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GIỜ XUẤT BẾN', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    const Text('23:00 (Đêm)\n', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VỊ TRÍ GHẾ', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    const Text('A12, A14', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TỔNG CỘNG', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    const Text('700.000đ', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPaymentMethod({required IconData icon, required Color iconColor, required String title, required String subtitle, required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: Colors.green, width: 2) : Border.all(color: Colors.transparent),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: isSelected ? Colors.green[800] : Colors.grey[400],
          )
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền thanh toán', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                  child: Text('Đã bao gồm thuế/phí', style: TextStyle(color: Colors.green[800], fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 8),
            const Text('700.000đ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                   Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const TransportTicketScreen()),
                      (route) => route.isFirst,
                   );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6B42),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: const Text('Xác nhận thanh toán', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
