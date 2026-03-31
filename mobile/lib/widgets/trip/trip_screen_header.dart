import 'package:flutter/material.dart';

import '../../views/trip/trip_ui_constants.dart';
import 'trip_circle_button.dart';

class TripScreenHeader extends StatelessWidget {
  const TripScreenHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TripCircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 12),
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
        trailing ?? const SizedBox(width: 42),
      ],
    );
  }
}
