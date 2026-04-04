import 'package:flutter/material.dart';
import '../../models/chat_response.dart';

class ItineraryBubble extends StatefulWidget {
  final SuggestedItinerary itinerary;

  const ItineraryBubble({super.key, required this.itinerary});

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
            // Header
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
                    child: const Icon(Icons.map_outlined, color: Colors.white, size: 24),
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
                          '${itinerary.totalDays} ngày · ${itinerary.estimatedBudget ?? ""}',
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
            // Days
            ...itinerary.days.map((day) => _buildDaySection(day)),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySection(ItineraryDay day) {
    final isExpanded = _expandedDay == day.dayNumber - 1;

    return Column(
      children: [
        // Day header
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
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isExpanded ? const Color(0xFF11998e) : Colors.grey.shade300,
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
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      if (day.theme != null)
                        Text(
                          day.theme!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
        // Activities (expandable)
        if (isExpanded)
          Container(
            color: const Color(0xFFF9FFF9),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: day.activities.map((activity) => _buildActivity(activity)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildActivity(ItineraryActivity activity) {
    final color = _getActivityColor(activity.icon);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time
          SizedBox(
            width: 40,
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
          // Timeline dot
          Column(
            children: [
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
            ],
          ),
          const SizedBox(width: 10),
          // Content
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
                if (activity.description != null)
                  Text(
                    activity.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                  ),
                if (activity.estimatedCost != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '~${activity.estimatedCost}',
                      style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
