import 'package:flutter/material.dart';

class TripSectionLabel extends StatelessWidget {
  const TripSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF70757E),
      ),
    );
  }
}
