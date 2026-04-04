import 'package:flutter/material.dart';

import '../../views/trip/trip_ui_constants.dart';

class MyTripFilterTabs extends StatelessWidget {
  const MyTripFilterTabs({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTab(index: 0, label: 'Sắp tới'),
          _buildTab(index: 1, label: 'Đã đi'),
        ],
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected ? TripUiColors.timelineGreen : TripUiColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
