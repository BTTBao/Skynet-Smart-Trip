import 'package:flutter/material.dart';

class TransportTicketScreen extends StatelessWidget {
  const TransportTicketScreen({Key? key}) : super(key: key);

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
        title: const Text('Chi tiết vé', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.greenAccent[100], shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.green, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('Đặt vé thành công!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 24)),
              const SizedBox(height: 4),
              Text('Vui lòng xuất trình mã QR khi lên xe', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 32),
              _buildTicketCard(),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, color: Colors.white, size: 18),
                label: const Text('Tải về máy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6B42),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.map, color: Colors.green[900], size: 18),
                label: Text('Xem bản đồ điểm đón', style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 32),
              RichText(
                text: TextSpan(
                  text: 'Cần hỗ trợ? Gọi ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  children: [
                    TextSpan(text: '1900 6067', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    child: const Icon(Icons.qr_code_2, size: 100, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('BOOKING-88291', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text('Mã đặt chỗ', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE), indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HÃNG XE', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.directions_bus, color: Colors.red, size: 16),
                            ),
                            const SizedBox(width: 8),
                            const Text('Phương Trang\n(FUTA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('SỐ GHẾ', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        const Text('B12,\nB13', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green), textAlign: TextAlign.right),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sài Gòn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('08:00 • 24/10', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(child: Container(height: 1, color: Colors.grey[300])),
                            Icon(Icons.directions_bus, size: 16, color: Colors.green[700]),
                            Expanded(child: Container(height: 1, color: Colors.grey[300])),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Đà Lạt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('14:30 • 24/10', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Điểm đón', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Bến xe Miền Tây - Quầy vé số 12, 395 Kinh Dương Vương, An Lạc, Bình Tân', style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5)),
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
