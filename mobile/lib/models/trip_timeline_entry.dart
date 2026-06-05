import 'package:flutter/material.dart';

import '../utils/app_currency_formatter.dart';

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
    this.adultCount,
    this.childCount,
    this.infantCount,
    this.bookedPrice,
    this.serviceDate,
    this.hotelCheckOutDate,
    this.departureTime,
    this.serviceAddress,
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
  final int? adultCount;
  final int? childCount;
  final int? infantCount;
  final double? bookedPrice;
  final DateTime? serviceDate;
  final DateTime? hotelCheckOutDate;
  final String? departureTime;
  final String? serviceAddress;
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
    final adultCount = (json['adultCount'] as num?)?.toInt() ?? 0;
    final childCount = (json['childCount'] as num?)?.toInt() ?? 0;
    final infantCount = (json['infantCount'] as num?)?.toInt() ?? 0;
    final subtitle = (json['serviceSubtitle'] ?? '').toString().trim();
    final priceLabel = bookedPrice == null
        ? null
        : AppCurrencyFormatter.format(bookedPrice);
    final serviceAddress = json['serviceAddress']?.toString().trim();
    final parsedServiceDate = _parseServiceDate(json['serviceDate']);
    final parsedHotelCheckOutDate = _parseServiceDate(
      json['hotelCheckOutDate'],
    );
    final parsedDeparture = _normalizeTime(json['departureTime']?.toString());

    final descriptionParts = serviceType == 'NOTE'
        ? <String>[
            if (subtitle.isNotEmpty)
              subtitle
            else if ((serviceAddress ?? '').isNotEmpty)
              serviceAddress!,
          ]
        : <String>[
            if (subtitle.isNotEmpty) subtitle,
            if ((serviceAddress ?? '').isNotEmpty) 'Địa chỉ: $serviceAddress',
            if (priceLabel != null) 'Giá: $priceLabel',
            'Số lượng: $quantity',
          ];

    if (serviceType == 'HOTEL') {
      descriptionParts.add(
        'Khach: $adultCount nguoi lon, $childCount tre em, $infantCount em be',
      );
    }

    return TripTimelineEntry(
      itineraryId: (json['itineraryId'] as num?)?.toInt(),
      dayNumber: (json['dayNumber'] as num?)?.toInt(),
      serviceType: serviceType,
      serviceId: (json['serviceId'] as num?)?.toInt(),
      quantity: quantity,
      adultCount: adultCount,
      childCount: childCount,
      infantCount: infantCount,
      bookedPrice: bookedPrice,
      serviceDate: parsedServiceDate,
      hotelCheckOutDate: parsedHotelCheckOutDate,
      departureTime: parsedDeparture,
      serviceAddress: (serviceAddress ?? '').isEmpty ? null : serviceAddress,
      time: parsedDeparture ?? '',
      sectionTitle: _sectionTitleForServiceType(serviceType),
      caption: (json['serviceName'] ?? 'Dich vu').toString(),
      description: descriptionParts.join(' - '),
      icon: _iconForServiceType(serviceType),
      badge: serviceType.isEmpty ? null : serviceType,
      badgeColor: _badgeBackgroundForServiceType(serviceType),
      badgeTextColor: _badgeTextForServiceType(serviceType),
    );
  }

  String? get hotelBookingDateLabel =>
      _hotelDateLabel(serviceType ?? '', serviceDate, hotelCheckOutDate);

  static DateTime? _parseServiceDate(dynamic rawValue) {
    final text = rawValue?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  static String? _normalizeTime(String? rawValue) {
    final text = rawValue?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    final parts = text.split(':');
    if (parts.length < 2) {
      return text;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return text;
    }

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static String? _hotelDateLabel(
    String serviceType,
    DateTime? checkIn,
    DateTime? checkOut,
  ) {
    if (serviceType != 'HOTEL' || checkIn == null) {
      return null;
    }

    final checkInText = _formatDate(checkIn);
    final checkOutText = checkOut == null
        ? 'Dang cap nhat'
        : _formatDate(checkOut);
    return 'Nhan phong: $checkInText - Tra phong: $checkOutText';
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _sectionTitleForServiceType(String serviceType) {
    switch (serviceType) {
      case 'HOTEL':
        return 'Lưu trú';
      case 'BUS':
        return 'Di chuyển';
      case 'NOTE':
        return 'Ghi chú';
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
      case 'NOTE':
        return Icons.sticky_note_2_rounded;
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
      case 'NOTE':
        return const Color(0xFFFFF7ED);
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
      case 'NOTE':
        return const Color(0xFFC2410C);
      default:
        return const Color(0xFF4B5563);
    }
  }
}
