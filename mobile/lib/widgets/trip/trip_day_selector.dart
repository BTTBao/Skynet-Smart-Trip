import 'package:flutter/material.dart';

import '../../models/trip_day_item.dart';
import '../../views/trip/trip_ui_constants.dart';

class TripDaySelector extends StatelessWidget {
  const TripDaySelector({
    super.key,
    required this.days,
    required this.selectedDayIndex,
    required this.onSelected,
  });

  final List<TripDayItem> days;
  final int selectedDayIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = selectedDayIndex == index;

          return GestureDetector(
            onTap: () => onSelected(index),
            child: Container(
              width: 82,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? TripUiColors.timelineGreen : TripUiColors.surfaceWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      day.label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white70 : TripUiColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    day.dayNumber,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : TripUiColors.textPrimary,
                    ),
                  ),
                  Text(
                    day.date,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : TripUiColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
