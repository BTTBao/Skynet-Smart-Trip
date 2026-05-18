import 'package:flutter/material.dart';

import '../../models/chat_response.dart';
import '../../utils/app_text.dart';

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
            context.tr(
              vi: 'Tro ly du lich thong minh cua ban',
              en: 'Your smart travel assistant',
            ),
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 36),
          _buildFeatureCard(
            icon: Icons.explore_outlined,
            color: const Color(0xFF667eea),
            title: context.tr(
              vi: 'Goi y diem den',
              en: 'Discover destinations',
            ),
            subtitle: context.tr(
              vi: 'Kham pha nhung noi tuyet voi nhat Viet Nam',
              en: 'Explore standout places across Vietnam',
            ),
            action: const QuickAction(
              label: 'Goi y diem den',
              icon: 'explore',
              actionPayload: 'Goi y cho toi 3 diem den dep nhat o Viet Nam',
            ),
          ),
          _buildFeatureCard(
            icon: Icons.calendar_month_outlined,
            color: const Color(0xFF11998e),
            title: context.tr(
              vi: 'Lap lich trinh',
              en: 'Plan an itinerary',
            ),
            subtitle: context.tr(
              vi: 'Tu dong tao ke hoach chi tiet theo ngay',
              en: 'Generate a day-by-day travel plan',
            ),
            action: const QuickAction(
              label: 'Lap lich trinh',
              icon: 'calendar',
              actionPayload: 'Lap lich trinh du lich Da Lat 3 ngay 2 dem',
            ),
          ),
          _buildFeatureCard(
            icon: Icons.hotel_outlined,
            color: const Color(0xFF1a237e),
            title: context.tr(
              vi: 'Tim khach san',
              en: 'Find hotels',
            ),
            subtitle: context.tr(
              vi: 'So sanh va tim cho o phu hop nhat',
              en: 'Compare stays that fit your trip',
            ),
            action: const QuickAction(
              label: 'Tim khach san',
              icon: 'hotel',
              actionPayload: 'Tim khach san dep o Phu Quoc',
            ),
          ),
          _buildFeatureCard(
            icon: Icons.wb_sunny_outlined,
            color: const Color(0xFFFF9800),
            title: context.tr(
              vi: 'Thoi tiet du lich',
              en: 'Travel weather',
            ),
            subtitle: context.tr(
              vi: 'Kiem tra thoi tiet truoc khi len duong',
              en: 'Check the weather before you go',
            ),
            action: const QuickAction(
              label: 'Xem thoi tiet',
              icon: 'weather',
              actionPayload: 'Thoi tiet Da Nang hom nay the nao?',
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
