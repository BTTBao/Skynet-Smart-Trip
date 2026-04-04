import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyTripSummary {
  MyTripSummary({
    required this.tripId,
    required this.title,
    required this.destination,
    required this.dateRange,
    required this.description,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackgroundColor,
    required this.imageGradient,
    required this.avatarColors,
    required this.startDate,
    required this.endDate,
    required this.itineraryCount,
    this.destinationId,
  });

  final int tripId;
  final int? destinationId;
  final String title;
  final String destination;
  final String dateRange;
  final String description;
  final String status;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackgroundColor;
  final List<Color> imageGradient;
  final List<Color> avatarColors;
  final DateTime startDate;
  final DateTime endDate;
  final int itineraryCount;

  factory MyTripSummary.fromJson(Map<String, dynamic> json) {
    final tripId = (json['tripId'] as num?)?.toInt() ?? 0;
    final title = (json['title'] ?? '').toString().trim();
    final destination = (json['destinationName'] ?? 'Chua cap nhat').toString();
    final startDate = DateTime.tryParse((json['startDate'] ?? '').toString()) ??
        DateTime.now();
    final endDate = DateTime.tryParse((json['endDate'] ?? '').toString()) ?? startDate;
    final status = (json['status'] ?? 'DRAFT').toString().toUpperCase();
    final palette = _palettes[tripId % _palettes.length];
    final statusStyle = _statusStyle(status, startDate, endDate);
    final itineraryCount = (json['itineraryCount'] as num?)?.toInt() ?? 0;
    final durationDays = endDate.difference(startDate).inDays + 1;
    final destinationDescription =
        (json['destinationDescription'] ?? '').toString().trim();

    return MyTripSummary(
      tripId: tripId,
      destinationId: (json['destinationId'] as num?)?.toInt(),
      title: title.isEmpty ? 'Chuyen di #$tripId' : title,
      destination: destination,
      dateRange:
          '${DateFormat('dd/MM').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
      description: destinationDescription.isNotEmpty
          ? destinationDescription
          : 'Hanh trinh $durationDays ngay den $destination voi $itineraryCount muc lich trinh.',
      status: status,
      statusLabel: statusStyle.label,
      statusColor: statusStyle.textColor,
      statusBackgroundColor: statusStyle.backgroundColor,
      imageGradient: palette.imageGradient,
      avatarColors: palette.avatarColors,
      startDate: startDate,
      endDate: endDate,
      itineraryCount: itineraryCount,
    );
  }

  static _TripCardPalette get fallbackPalette => _palettes.first;

  static _TripStatusStyle _statusStyle(
    String status,
    DateTime startDate,
    DateTime endDate,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day);

    if (status == 'CANCELLED') {
      return const _TripStatusStyle(
        label: 'DA HUY',
        textColor: Color(0xFFB42318),
        backgroundColor: Color(0xFFFEE4E2),
      );
    }

    if (normalizedEndDate.isBefore(today)) {
      return const _TripStatusStyle(
        label: 'DA DI',
        textColor: Color(0xFF6B7280),
        backgroundColor: Color(0xFFF0F2F4),
      );
    }

    if (status == 'PAID') {
      return const _TripStatusStyle(
        label: 'DA THANH TOAN',
        textColor: Color(0xFF166534),
        backgroundColor: Color(0xFFDCFCE7),
      );
    }

    if (status == 'PENDING') {
      return const _TripStatusStyle(
        label: 'SAP TOI',
        textColor: Color(0xFF15803D),
        backgroundColor: Color(0xFFE2FBEA),
      );
    }

    return const _TripStatusStyle(
      label: 'BAN NHAP',
      textColor: Color(0xFF1D4ED8),
      backgroundColor: Color(0xFFDBEAFE),
    );
  }

  static const List<_TripCardPalette> _palettes = [
    _TripCardPalette(
      imageGradient: [Color(0xFF65C3D6), Color(0xFF2E7DA2)],
      avatarColors: [Color(0xFFC57D56), Color(0xFF2D6CDF), Color(0xFF6ED89A)],
    ),
    _TripCardPalette(
      imageGradient: [Color(0xFF8FCF95), Color(0xFF2C7A7B)],
      avatarColors: [Color(0xFFE59E63), Color(0xFF4DA3FF), Color(0xFF34D399)],
    ),
    _TripCardPalette(
      imageGradient: [Color(0xFF9CC7E7), Color(0xFF5B87AA)],
      avatarColors: [Color(0xFFD97706), Color(0xFF2563EB), Color(0xFF10B981)],
    ),
  ];
}

class _TripStatusStyle {
  const _TripStatusStyle({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;
}

class _TripCardPalette {
  const _TripCardPalette({
    required this.imageGradient,
    required this.avatarColors,
  });

  final List<Color> imageGradient;
  final List<Color> avatarColors;
}
