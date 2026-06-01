import 'package:flutter/material.dart';

class ExploreColors {
  ExploreColors._();

  static const background = Color(0xFFF4F6F8);
  static const primary = Color(0xFF18A558);
  static const primaryLight = Color(0xFF80ED99);
  static const accent = Color(0xFF57CC99);
  static const cardSurface = Colors.white;
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const chipActive = Color(0xFF18A558);
  static const chipActiveBg = Color(0xFFE7FFF0);
  static const chipInactive = Color(0xFF6B7280);
  static const chipInactiveBg = Color(0xFFF3F4F6);
  static const border = Color(0xFFE5E7EB);
  static const heartRed = Color(0xFFEF4444);
  static const overlayDark = Color(0xCC000000);
}

class ExploreTextStyles {
  ExploreTextStyles._();

  static const postTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1.3,
    shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
  );

  static const cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: ExploreColors.textPrimary,
    height: 1.35,
  );

  static const locationTag = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  static const sectionHeading = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: ExploreColors.textPrimary,
    height: 1.1,
  );
}

class ExploreSpacing {
  ExploreSpacing._();

  static const pagePadding = EdgeInsets.fromLTRB(16, 12, 16, 100);
  static const cardRadius = 20.0;
  static const chipRadius = 999.0;
}
