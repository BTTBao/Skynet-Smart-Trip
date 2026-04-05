import 'package:flutter/material.dart';

import '../../models/edit_itinerary_activity.dart';
import '../../views/trip/trip_ui_constants.dart';

class EditItineraryActivityCard extends StatelessWidget {
  const EditItineraryActivityCard({
    super.key,
    required this.activity,
    required this.onDelete,
  });

  final EditItineraryActivity activity;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 64,
            alignment: Alignment.center,
            child: Container(
              width: 3,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFE6EBEF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: activity.imageGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.landscape_rounded,
              color: Colors.white70,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: TripUiColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: TripUiColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: TripUiColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activity.timeRange,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: TripUiColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Color(0xFFE25555),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
