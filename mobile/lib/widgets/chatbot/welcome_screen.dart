import 'package:flutter/material.dart';
import '../../models/chat_response.dart';

class WelcomeScreen extends StatelessWidget {
  final Function(QuickAction) onQuickAction;

  const WelcomeScreen({super.key, required this.onQuickAction});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Sky mascot / icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF80ed99), Color(0xFF38ef7d)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF80ed99).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sky Assistant',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B4332),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trợ lý du lịch thông minh của bạn',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 36),
          // Feature cards
          _buildFeatureCard(
            icon: Icons.explore_outlined,
            color: const Color(0xFF667eea),
            title: 'Gợi ý điểm đến',
            subtitle: 'Khám phá những nơi tuyệt vời nhất Việt Nam',
            action: QuickAction(
              label: 'Gợi ý điểm đến',
              icon: 'explore',
              actionPayload: 'Gợi ý cho tôi 3 điểm đến đẹp nhất ở Việt Nam',
            ),
          ),
          _buildFeatureCard(
            icon: Icons.calendar_month_outlined,
            color: const Color(0xFF11998e),
            title: 'Lập lịch trình',
            subtitle: 'Tự động tạo kế hoạch chi tiết theo ngày',
            action: QuickAction(
              label: 'Lập lịch trình',
              icon: 'calendar',
              actionPayload: 'Lập lịch trình du lịch Đà Lạt 3 ngày 2 đêm',
            ),
          ),
          _buildFeatureCard(
            icon: Icons.hotel_outlined,
            color: const Color(0xFF1a237e),
            title: 'Tìm khách sạn',
            subtitle: 'So sánh và tìm chỗ ở phù hợp nhất',
            action: QuickAction(
              label: 'Tìm khách sạn',
              icon: 'hotel',
              actionPayload: 'Tìm khách sạn đẹp ở Phú Quốc',
            ),
          ),
          _buildFeatureCard(
            icon: Icons.wb_sunny_outlined,
            color: const Color(0xFFFF9800),
            title: 'Thời tiết du lịch',
            subtitle: 'Kiểm tra thời tiết trước khi lên đường',
            action: QuickAction(
              label: 'Xem thời tiết',
              icon: 'weather',
              actionPayload: 'Thời tiết Đà Nẵng hôm nay thế nào?',
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required QuickAction action,
  }) {
    return GestureDetector(
      onTap: () => onQuickAction(action),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
