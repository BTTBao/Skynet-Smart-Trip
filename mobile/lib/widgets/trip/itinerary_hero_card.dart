import 'package:flutter/material.dart';

class ItineraryHeroCard extends StatelessWidget {
  const ItineraryHeroCard({
    super.key,
    required this.title,
    required this.dateRangeLabel,
  });

  final String title;
  final String dateRangeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 178,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF39A7FF),
            Color(0xFF1E4FA8),
            Color(0xFF183153),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Icon(
              Icons.location_city_rounded,
              size: 120,
              color: Colors.white24,
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dateRangeLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
