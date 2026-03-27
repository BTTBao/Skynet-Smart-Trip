import 'package:flutter/material.dart';

class TripTimelineEntry {
  const TripTimelineEntry({
    required this.time,
    required this.sectionTitle,
    required this.caption,
    required this.description,
    required this.icon,
    this.badge,
    this.badgeColor,
    this.badgeTextColor,
    this.rating,
    this.imageColors,
  });

  final String time;
  final String sectionTitle;
  final String caption;
  final String description;
  final IconData icon;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final int? rating;
  final List<Color>? imageColors;
}
