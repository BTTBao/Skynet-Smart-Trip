import 'package:flutter/material.dart';

import '../../models/my_trip_summary.dart';
import '../../views/trip/trip_ui_constants.dart';

class MyTripCard extends StatelessWidget {
  const MyTripCard({
    super.key,
    required this.trip,
    required this.onTap,
    this.onReviewTap,
    this.onEditTap,
    this.onDeleteTap,
  });

  final MyTripSummary trip;
  final VoidCallback onTap;
  final VoidCallback? onReviewTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 184,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: trip.imageGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Icon(
                      Icons.location_city_rounded,
                      size: 110,
                      color: Colors.white30,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: trip.statusBackgroundColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    trip.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: trip.statusColor,
                    ),
                  ),
                ),
              ),
              if (onEditTap != null || onDeleteTap != null)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEditTap != null)
                        _TripCardActionIcon(
                          icon: Icons.edit_outlined,
                          tooltip: 'Sửa chuyến đi',
                          onTap: onEditTap!,
                        ),
                      if (onEditTap != null && onDeleteTap != null)
                        const SizedBox(width: 8),
                      if (onDeleteTap != null)
                        _TripCardActionIcon(
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'Xóa chuyến đi',
                          onTap: onDeleteTap!,
                          isDestructive: true,
                        ),
                    ],
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Text(
                  trip.destination.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: TripUiColors.textPrimary,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      trip.dateRange,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: TripUiColors.textMuted,
                      ),
                    ),
                    if (trip.shareCode.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Mã: ${trip.shareCode}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: TripUiColors.timelineGreen,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            trip.description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: TripUiColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TripUiColors.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Xem chi tiết',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (onReviewTap != null) ...[
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Đánh giá dịch vụ',
                  child: InkWell(
                    onTap: onReviewTap,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 48,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFD27A)),
                      ),
                      child: const Icon(
                        Icons.star_rate_rounded,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TripCardActionIcon extends StatelessWidget {
  const _TripCardActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 18,
              color: isDestructive
                  ? const Color(0xFFDC2626)
                  : TripUiColors.timelineGreen,
            ),
          ),
        ),
      ),
    );
  }
}
