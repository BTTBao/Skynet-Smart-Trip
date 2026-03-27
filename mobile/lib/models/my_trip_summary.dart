import 'package:flutter/material.dart';

class MyTripSummary {
  const MyTripSummary({
    required this.title,
    required this.destination,
    required this.dateRange,
    required this.description,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackgroundColor,
    required this.imageGradient,
    required this.avatarColors,
    required this.startDate,
    required this.endDate,
  });

  final String title;
  final String destination;
  final String dateRange;
  final String description;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackgroundColor;
  final List<Color> imageGradient;
  final List<Color> avatarColors;
  final DateTime startDate;
  final DateTime endDate;
}
