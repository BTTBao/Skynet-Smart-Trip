import 'package:flutter/material.dart';

import '../explore_ui_constants.dart';

class ExploreFilterChip extends StatelessWidget {
  const ExploreFilterChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? ExploreColors.chipActiveBg : Colors.white,
          borderRadius: BorderRadius.circular(ExploreSpacing.chipRadius),
          border: Border.all(
            color: isActive ? ExploreColors.chipActive : ExploreColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? ExploreColors.chipActive : ExploreColors.chipInactive,
          ),
        ),
      ),
    );
  }
}
