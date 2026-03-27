import 'package:flutter/material.dart';

class EditItineraryActivity {
  const EditItineraryActivity({
    required this.title,
    required this.location,
    required this.timeRange,
    required this.imageGradient,
    this.isActive = true,
  });

  final String title;
  final String location;
  final String timeRange;
  final List<Color> imageGradient;
  final bool isActive;
}
