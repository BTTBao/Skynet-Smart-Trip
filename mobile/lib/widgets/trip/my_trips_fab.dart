import 'package:flutter/material.dart';

import '../../views/trip/trip_ui_constants.dart';

class MyTripsFab extends StatelessWidget {
  const MyTripsFab({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onTap,
      backgroundColor: TripUiColors.timelineGreen,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.add_rounded, size: 30),
    );
  }
}
