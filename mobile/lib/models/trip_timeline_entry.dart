import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripTimelineEntry {
  const TripTimelineEntry({
    required this.time,
    required this.sectionTitle,
    required this.caption,
    required this.description,
    required this.icon,
    this.itineraryId,
    this.dayNumber,
    this.serviceType,
    this.serviceId,
    this.quantity,
    this.bookedPrice,
    this.badge,
    this.badgeColor,
    this.badgeTextColor,
    this.rating,
    this.imageColors,
  });

  final int? itineraryId;
  final int? dayNumber;
  final String? serviceType;
  final int? serviceId;
  final int? quantity;
  final double? bookedPrice;
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

  factory TripTimelineEntry.fromJson(Map<String, dynamic> json) {
    final serviceType = (json['serviceType'] ?? '').toString().toUpperCase();
    final bookedPrice = (json['bookedPrice'] as num?)?.toDouble();
    final quantity = (json['quantity'] as num?)?.toInt() ?? 1;
    final subtitle = (json['serviceSubtitle'] ?? '').toString().trim();
    final priceLabel = bookedPrice == null
        ? null
        : NumberFormat.currency(
            locale: 'vi_VN',
            symbol: 'VND ',
            decimalDigits: 0,
          ).format(bookedPrice);

    final descriptionParts = <String>[
      if (subtitle.isNotEmpty) subtitle,
      if (priceLabel != null) 'Gia: $priceLabel',
      'So luong: $quantity',
    ];

    return TripTimelineEntry(
      itineraryId: (json['itineraryId'] as num?)?.toInt(),
      dayNumber: (json['dayNumber'] as num?)?.toInt(),
      serviceType: serviceType,
      serviceId: (json['serviceId'] as num?)?.toInt(),
      quantity: quantity,
      bookedPrice: bookedPrice,
      time: '',
      sectionTitle: _sectionTitleForServiceType(serviceType),
      caption: (json['serviceName'] ?? 'Dich vu').toString(),
      description: descriptionParts.join(' • '),
      icon: _iconForServiceType(serviceType),
      badge: serviceType.isEmpty ? null : serviceType,
      badgeColor: _badgeBackgroundForServiceType(serviceType),
      badgeTextColor: _badgeTextForServiceType(serviceType),
    );
  }

  static String _sectionTitleForServiceType(String serviceType) {
    switch (serviceType) {
      case 'HOTEL':
        return 'Luu tru';
      case 'BUS':
        return 'Di chuyen';
      default:
        return 'Dich vu';
    }
  }

  static IconData _iconForServiceType(String serviceType) {
    switch (serviceType) {
      case 'HOTEL':
        return Icons.hotel_rounded;
      case 'BUS':
        return Icons.directions_bus_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  static Color _badgeBackgroundForServiceType(String serviceType) {
    switch (serviceType) {
      case 'HOTEL':
        return const Color(0xFFEAF4FF);
      case 'BUS':
        return const Color(0xFFE4FFF0);
      default:
        return const Color(0xFFF1F4F6);
    }
  }

  static Color _badgeTextForServiceType(String serviceType) {
    switch (serviceType) {
      case 'HOTEL':
        return const Color(0xFF2A6FD6);
      case 'BUS':
        return const Color(0xFF20B15A);
      default:
        return const Color(0xFF4B5563);
    }
  }
}
