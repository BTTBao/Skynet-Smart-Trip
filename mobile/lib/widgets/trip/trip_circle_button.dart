import 'package:flutter/material.dart';

import '../../views/trip/trip_ui_constants.dart';

class TripCircleButton extends StatelessWidget {
  const TripCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: TripUiColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TripUiColors.border),
        ),
        child: Icon(icon, color: const Color(0xFF4B5563), size: 18),
      ),
    );
  }
}
