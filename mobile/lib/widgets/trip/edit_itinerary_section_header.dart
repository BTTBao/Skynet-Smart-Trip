import 'package:flutter/material.dart';

import '../../views/trip/trip_ui_constants.dart';

class EditItinerarySectionHeader extends StatelessWidget {
  const EditItinerarySectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: TripUiColors.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: TripUiColors.timelineGreen,
              ),
            ),
          ),
      ],
    );
  }
}
