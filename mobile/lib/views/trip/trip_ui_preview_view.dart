import 'package:flutter/material.dart';

import 'create_trip_view.dart';
import 'my_trips_view.dart';
import 'trip_itinerary_detail_view.dart';

class TripUiPreviewView extends StatelessWidget {
  const TripUiPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Trip UI Preview',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PreviewCard(
            title: 'Chuyen di cua toi',
            subtitle: 'Danh sach chuyen di voi nut tao moi.',
            icon: Icons.luggage_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyTripsView()),
              );
            },
          ),
          const SizedBox(height: 14),
          _PreviewCard(
            title: 'Tao chuyen di moi',
            subtitle: 'Form tao trip va goi API tao moi.',
            icon: Icons.add_road_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateTripView()),
              );
            },
          ),
          const SizedBox(height: 14),
          _PreviewCard(
            title: 'Lich trinh chi tiet',
            subtitle: 'Mo nhanh man hinh chi tiet bang trip id = 1.',
            icon: Icons.route_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TripItineraryDetailView(
                    tripId: 1,
                    tripTitle: 'Trip #1',
                    startDate: DateTime(2026, 4, 1),
                    endDate: DateTime(2026, 4, 3),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFE8FFF0),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: const Color(0xFF20B15A), size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: Color(0xFF7B8794),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}
