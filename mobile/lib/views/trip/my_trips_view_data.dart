import 'package:flutter/material.dart';

import '../../models/my_trip_summary.dart';

final upcomingTrips = [
  MyTripSummary(
    title: 'Mùa hè Đà Nẵng',
    destination: 'Đà Nẵng',
    dateRange: '16/07 - 20/07/2024',
    description: 'Hành trình khám phá vẻ đẹp của biển Mỹ Khê, Ngũ Hành Sơn và phố cổ Hội An.',
    statusLabel: 'ĐANG CHỜ',
    statusColor: const Color(0xFF2F855A),
    statusBackgroundColor: const Color(0xFFDDF9E7),
    imageGradient: const [Color(0xFF65C3D6), Color(0xFF2E7DA2)],
    avatarColors: const [Color(0xFFC57D56), Color(0xFF2D6CDF), Color(0xFF6ED89A)],
    startDate: DateTime(2024, 7, 16),
    endDate:  DateTime(2024, 7, 20),
  ),
  MyTripSummary(
    title: 'Hạ Long Kỳ Thú',
    destination: 'Hạ Long',
    dateRange: '02/09 - 05/09/2024',
    description: 'Du ngoạn trên vịnh, thưởng thức hải sản và nghỉ dưỡng trong không gian xanh mát.',
    statusLabel: '3 thành viên',
    statusColor: const Color(0xFF15803D),
    statusBackgroundColor: const Color(0xFFE2FBEA),
    imageGradient: const [Color(0xFF8FCF95), Color(0xFF2C7A7B)],
    avatarColors: const [Color(0xFFE59E63), Color(0xFF4DA3FF), Color(0xFF34D399)],
    startDate: DateTime(2024, 9, 2),
    endDate: DateTime(2024, 9, 5),
  ),
];

final completedTrips = [
  MyTripSummary(
    title: 'Sài Gòn Cuối Tuần',
    destination: 'TP.HCM',
    dateRange: '12/05 - 14/05/2024',
    description: 'Một chuyến đi ngắn với cà phê, ẩm thực đường phố và những con hẻm rất riêng của Sài Gòn.',
    statusLabel: 'ĐÃ ĐI',
    statusColor: const Color(0xFF6B7280),
    statusBackgroundColor: const Color(0xFFF0F2F4),
    imageGradient: const [Color(0xFF9CC7E7), Color(0xFF5B87AA)],
    avatarColors: const [Color(0xFFD97706), Color(0xFF2563EB), Color(0xFF10B981)],
    startDate: DateTime(2024, 5, 12),
    endDate:  DateTime(2024, 5, 14),
  ),
];
