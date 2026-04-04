import 'package:flutter/material.dart';

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết đặt chỗ',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQRCodeCard(),
              const SizedBox(height: 24),
              const Text('TRẠNG THÁI DỊCH VỤ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
              const SizedBox(height: 16),
              _buildTimelineStepper(),
              const SizedBox(height: 24),
              _buildServiceInfoCard(),
              const SizedBox(height: 16),
              _buildLocationCard(),
              const SizedBox(height: 80), // Space for bottom bar
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildBottomActions(),
    );
  }

  Widget _buildQRCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A3A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              // Ideally use 'qr_flutter' package. We'll simulate with an icon/image
              child: const Icon(Icons.qr_code_2, size: 120, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            text: const TextSpan(
              text: 'Mã đặt chỗ: ',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              children: [
                TextSpan(text: '#BK-98245', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text('Đưa mã này cho nhân viên khi đến nơi', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTimelineStepper() {
    return Column(
      children: [
        _buildTimelineStep(
          isActive: true,
          isCompleted: true,
          title: 'Đang chuẩn bị',
          time: '14:20 - 24/05/2024',
          icon: Icons.check,
        ),
        _buildTimelineStep(
          isActive: true,
          isCompleted: false,
          title: 'Đã sẵn sàng',
          time: 'Dự kiến: 14:45',
          icon: Icons.refresh,
          isLastActive: true,
        ),
        _buildTimelineStep(
          isActive: false,
          isCompleted: false,
          title: 'Đang sử dụng',
          time: 'Chưa bắt đầu',
          icon: Icons.play_arrow,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required bool isActive,
    required bool isCompleted,
    required String title,
    required String time,
    required IconData icon,
    bool isLastActive = false,
    bool isLast = false,
  }) {
    Color primaryColor = isActive ? Colors.green[400]! : Colors.grey[300]!;
    Color bgColor = isCompleted ? Colors.green[400]! : (isActive ? Colors.green[200]! : Colors.grey[200]!);
    Color iconColor = isCompleted ? Colors.white : (isActive ? Colors.green[600]! : Colors.grey[500]!);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isLastActive ? Colors.grey[200] : primaryColor,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isActive ? Colors.black : Colors.grey[500])),
            const SizedBox(height: 4),
            Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               Icon(Icons.info, color: Colors.green[400], size: 20),
               const SizedBox(width: 8),
               const Text('Thông tin dịch vụ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Dịch vụ:', 'Chăm sóc Spa Cao cấp'),
          const SizedBox(height: 12),
          _buildInfoRow('Thời gian:', '15:00 - 16:30'),
          const SizedBox(height: 12),
          _buildInfoRow('Nhân viên:', 'Nguyễn Minh Anh'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               Icon(Icons.location_on, color: Colors.green[400], size: 20),
               const SizedBox(width: 8),
               const Text('Vị trí cửa hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://maps.googleapis.com/maps/api/staticmap?center=Ho+Chi+Minh+City&zoom=14&size=600x250&maptype=roadmap&key=YOUR_API_KEY', // Placeholder
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(height: 120, width: double.infinity, color: Colors.blueGrey[100], child: const Center(child: Icon(Icons.map, size: 40))),
            ),
          ),
          const SizedBox(height: 12),
          const Text('123 Đường Lê Lợi, Quận 1, TP. HCM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Cách bạn 1.2 km', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.chat_bubble, color: Colors.green[400], size: 18),
                label: Text('Chat với hỗ trợ', style: TextStyle(color: Colors.green[400], fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.green[400]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.phone, color: Colors.black, size: 18),
                label: const Text('Gọi điện', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[400],
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
