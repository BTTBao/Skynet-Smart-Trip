import 'package:flutter/material.dart';

import '../../models/edit_itinerary_activity.dart';
import '../../models/edit_itinerary_favorite.dart';
import '../../models/edit_itinerary_service_type.dart';
import 'trip_ui_constants.dart';

const editItineraryDefaultActivities = [
  EditItineraryActivity(
    title: 'Ăn sáng tại Khách sạn',
    location: 'Sảnh ăn',
    timeRange: '09:00 - 09:30',
    imageGradient: [Color(0xFF613414), Color(0xFFD98E54)],
  ),
  EditItineraryActivity(
    title: 'Tham quan Vịnh Hạ Long',
    location: 'Vịnh Hạ Long',
    timeRange: '09:30 - 12:00',
    imageGradient: [Color(0xFF1D4ED8), Color(0xFF7DD3FC)],
  ),
  EditItineraryActivity(
    title: 'Bữa trưa Hải sản',
    location: 'Nhà hàng biển',
    timeRange: '12:30 - 13:30',
    imageGradient: [Color(0xFF7C2D12), Color(0xFFF59E0B)],
  ),
];

const editItineraryServiceTypes = [
  EditItineraryServiceType(
    label: 'Dịch vụ đặt',
    icon: Icons.shopping_bag_outlined,
    backgroundColor: Color(0xFFE8FFF0),
    iconColor: TripUiColors.timelineGreen,
  ),
  EditItineraryServiceType(
    label: 'Yêu thích',
    icon: Icons.favorite_rounded,
    backgroundColor: Color(0xFFE8FBFF),
    iconColor: Color(0xFF2CB7D9),
  ),
];

const editItineraryFavorites = [
  EditItineraryFavorite(
    title: 'Massage Chân Thảo Dược',
    subtitle: 'Thư giãn • 60 phút',
    imageGradient: [Color(0xFF7A3E00), Color(0xFFF2A33B)],
  ),
  EditItineraryFavorite(
    title: 'Tour Ẩm Thực Đêm',
    subtitle: 'Trải nghiệm • 2 giờ',
    imageGradient: [Color(0xFF5A2500), Color(0xFFF27B35)],
  ),
];
