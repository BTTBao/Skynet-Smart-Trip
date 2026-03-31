import 'package:flutter/material.dart';

class CreateTripHeroCard extends StatelessWidget {
  const CreateTripHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF70D6FF),
            Color(0xFF275DAD),
            Color(0xFF143D63),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF143D63).withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -28,
            right: -18,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            left: -6,
            right: -6,
            bottom: 28,
            child: Icon(
              Icons.landscape_rounded,
              size: 128,
              color: Colors.white24,
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bắt đầu hành trình của bạn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lưu lịch trình, chọn điểm đến và chuẩn bị mọi thứ thật gọn gàng.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
