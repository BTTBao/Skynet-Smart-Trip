import 'package:flutter/material.dart';

class EditItineraryActivity {
  const EditItineraryActivity({
    this.itineraryId,
    this.dayNumber,
    required this.title,
    required this.location,
    required this.timeRange,
    required this.imageGradient,
    this.isActive = true,
  });

  final int? itineraryId;
  final int? dayNumber;
  final String title;
  final String location;
  final String timeRange;
  final List<Color> imageGradient;
  final bool isActive;
}
