import 'package:flutter/material.dart';
import '../../models/bus_schedule_model.dart';

class TransportTicketScreen extends StatelessWidget {
  final int bookingId;
  final BusScheduleModel schedule;
  final List<String> seats;

  const TransportTicketScreen({
    Key? key,
    required this.bookingId,
    required this.schedule,
    required this.seats,
  }) : super(key: key);

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D6B42)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chi tiết vé', style: TextStyle(color: Color(0xFF0D6B42), fontWeight: FontWeight.bold)),
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
                decoration: const BoxDecoration(color: Color(0xFFE8F8F0), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Color(0xFF0D6B42), size: 40),
              ),
              const SizedBox(height: 16),
              const Text('Đặt vé thành công!', style: TextStyle(color: Color(0xFF0D6B42), fontWeight: FontWeight.bold, fontSize: 24)),
              const SizedBox(height: 4),
              Text('Vui lòng xuất trình mã QR khi lên xe', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 32),
              _buildTicketCard(),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đang tải vé điện tử về máy...')),
                  );
                },
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
                icon: const Icon(Icons.map, color: Color(0xFF0D6B42), size: 18),
                label: const Text('Xem bản đồ điểm đón', style: TextStyle(color: Color(0xFF0D6B42), fontWeight: FontWeight.bold, fontSize: 15)),
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
                    TextSpan(text: schedule.companyHotline, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D6B42))),
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
    final code = 'BOOKING-#SKN-${bookingId.toString().padLeft(4, '0')}';
    final departureStr = '${_formatTime(schedule.departureTime)} • ${_formatDate(schedule.departureTime)}';
    final arrivalStr = '${_formatTime(schedule.arrivalTime)} • ${_formatDate(schedule.arrivalTime)}';

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
                Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
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
                              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.directions_bus, color: Colors.red, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(schedule.companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('SỐ GHẾ', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text(seats.join(', '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0D6B42)), textAlign: TextAlign.right),
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
                        Text(schedule.fromDestName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(departureStr, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(child: Container(height: 1, color: Colors.grey[300])),
                            const Icon(Icons.directions_bus, size: 16, color: Color(0xFF0D6B42)),
                            Expanded(child: Container(height: 1, color: Colors.grey[300])),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(schedule.toDestName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(arrivalStr, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF0D6B42), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Điểm đón', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Bến xe trung tâm ${schedule.fromDestName}. Vui lòng có mặt tại quầy vé của ${schedule.companyName} trước giờ chạy 15 phút.', style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5)),
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
