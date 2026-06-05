import 'package:flutter/material.dart';

import '../../models/chat_response.dart';

class ItineraryBubble extends StatefulWidget {
  final SuggestedItinerary itinerary;
  final void Function(HotelPlanSuggestion hotel)? onBookHotel;
  final void Function(TransportPlanSuggestion transport)? onBookTransport;
  final Future<void> Function(SuggestedItinerary itinerary)? onSaveTrip;

  const ItineraryBubble({
    super.key,
    required this.itinerary,
    this.onBookHotel,
    this.onBookTransport,
    this.onSaveTrip,
  });

  @override
  State<ItineraryBubble> createState() => _ItineraryBubbleState();
}

class _ItineraryBubbleState extends State<ItineraryBubble> {
  int _expandedDay = 0;

  IconData _getActivityIcon(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'attraction':
        return Icons.photo_camera_outlined;
      case 'transport':
        return Icons.directions_car;
      case 'hotel':
        return Icons.hotel;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'entertainment':
        return Icons.local_activity;
      default:
        return Icons.location_on;
    }
  }

  Color _getActivityColor(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return const Color(0xFFE57373);
      case 'attraction':
        return const Color(0xFF64B5F6);
      case 'transport':
        return const Color(0xFFFFB74D);
      case 'hotel':
        return const Color(0xFF9575CD);
      case 'shopping':
        return const Color(0xFF4DB6AC);
      case 'entertainment':
        return const Color(0xFFFF8A65);
      default:
        return const Color(0xFF90A4AE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itinerary = widget.itinerary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.map_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itinerary.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${itinerary.totalDays} ngày - ${itinerary.estimatedBudget ?? ""}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ...itinerary.days.map(_buildDaySection),
            if (itinerary.costBreakdown != null || widget.onSaveTrip != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (itinerary.costBreakdown != null)
                      _buildCostBreakdown(itinerary.costBreakdown!),
                    if (widget.onSaveTrip != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () => widget.onSaveTrip!(itinerary),
                            icon: const Icon(Icons.save_outlined, size: 18),
                            label: const Text('Lưu thành chuyến đi'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySection(ItineraryDay day) {
    final isExpanded = _expandedDay == day.dayNumber - 1;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedDay = isExpanded ? -1 : day.dayNumber - 1;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isExpanded ? const Color(0xFFF0FFF4) : Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? const Color(0xFF11998e)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${day.dayNumber}',
                      style: TextStyle(
                        color: isExpanded ? Colors.white : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ngày ${day.dayNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (day.theme != null)
                        Text(
                          day.theme!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            color: const Color(0xFFF9FFF9),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: day.activities.map(_buildActivity).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildActivity(ItineraryActivity activity) {
    final color = _getActivityColor(activity.icon);
    final bookHotel =
        activity.icon == 'hotel' ? widget.itinerary.hotelSuggestion : null;
    final bookTransport = activity.icon == 'transport'
        ? widget.itinerary.transportSuggestion
        : null;
    final canShowBookAction =
        (bookHotel != null && widget.onBookHotel != null) ||
        (bookTransport != null && widget.onBookTransport != null);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  activity.time,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getActivityIcon(activity.icon),
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (activity.description != null &&
                        activity.description!.trim().isNotEmpty)
                      Text(
                        activity.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    if (activity.estimatedCost != null &&
                        activity.estimatedCost!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '~${activity.estimatedCost}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (canShowBookAction)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 90),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    if (bookHotel != null && widget.onBookHotel != null) {
                      widget.onBookHotel!(bookHotel);
                      return;
                    }

                    if (bookTransport != null &&
                        widget.onBookTransport != null) {
                      widget.onBookTransport!(bookTransport);
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Đặt ngay'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdown(ItineraryCostBreakdown cost) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng chi phí dự kiến',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _buildCostRow('Di chuyển', cost.transportCost),
          _buildCostRow('Khách sạn', cost.hotelCost),
          _buildCostRow('Ăn uống', cost.foodCost),
          _buildCostRow('Vui chơi', cost.activityCost),
          const Divider(height: 18),
          _buildCostRow('Tổng dự kiến', cost.totalCost, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, double? value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            _formatMoney(value),
            style: TextStyle(
              fontSize: isTotal ? 13 : 12,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isTotal ? const Color(0xFF047857) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double? value) {
    if (value == null) {
      return 'Liên hệ';
    }

    final normalized = value.round();
    final digits = normalized.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return '$buffer đ';
  }
}
