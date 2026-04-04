import 'package:flutter/material.dart';

import '../../views/trip/trip_ui_constants.dart';

class TripTimelineEmptyState extends StatelessWidget {
  const TripTimelineEmptyState({
    super.key,
    required this.onAddPressed,
  });

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7EDF1)),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFE8FFF0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.event_note_rounded,
              color: TripUiColors.timelineGreen,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Chưa có dịch vụ nào',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: TripUiColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bắt đầu xây lịch trình cho ngày này bằng cách thêm chuyến đi, khách sạn, ăn uống hoặc điểm tham quan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: TripUiColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAddPressed,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: TripUiColors.timelineGreen),
              foregroundColor: TripUiColors.timelineGreen,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Thêm dịch vụ đầu tiên',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
