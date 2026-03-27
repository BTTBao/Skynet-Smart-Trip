import 'package:flutter/material.dart';

import '../../models/trip_timeline_entry.dart';
import '../../views/trip/trip_ui_constants.dart';

class TripTimeline extends StatelessWidget {
  const TripTimeline({
    super.key,
    required this.entries,
  });

  final List<TripTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(entries.length, (index) {
        final entry = entries[index];
        final isLast = index == entries.length - 1;
        final connectorHeight = entry.imageColors == null ? 146.0 : 220.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE8FFF0),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: TripUiColors.timelineGreen,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: connectorHeight,
                      color: const Color(0xFFD7DDE3),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.time} • ${entry.sectionTitle.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF22A559),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: TripUiColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8FFF0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  entry.icon,
                                  color: TripUiColors.timelineGreen,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.caption,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: TripUiColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entry.description,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: TripUiColors.textSecondary,
                            ),
                          ),
                          if (entry.badge != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: entry.badgeColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                entry.badge!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: entry.badgeTextColor,
                                ),
                              ),
                            ),
                          ],
                          if (entry.rating != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: List.generate(
                                entry.rating!,
                                (_) => const Padding(
                                  padding: EdgeInsets.only(right: 3),
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: Color(0xFFFFB020),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (entry.imageColors != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              height: 110,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: LinearGradient(
                                  colors: entry.imageColors!,
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.temple_buddhist_rounded,
                                  color: Colors.white70,
                                  size: 56,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
