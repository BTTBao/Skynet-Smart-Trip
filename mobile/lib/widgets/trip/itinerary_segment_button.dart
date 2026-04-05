import 'package:flutter/material.dart';

import '../../views/trip/trip_ui_constants.dart';

class ItinerarySegmentButton extends StatelessWidget {
  const ItinerarySegmentButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8FFF0) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isSelected ? TripUiColors.timelineGreen : TripUiColors.textMuted,
          ),
        ),
      ),
    );
  }
}
