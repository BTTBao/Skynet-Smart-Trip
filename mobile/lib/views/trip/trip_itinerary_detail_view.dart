import 'package:flutter/material.dart';

import 'edit_itinerary_view.dart';
import '../../models/trip_day_item.dart';
import '../../models/trip_timeline_entry.dart';
import 'trip_ui_constants.dart';
import '../../widgets/trip/widgets.dart';

class TripItineraryDetailView extends StatefulWidget {
  const TripItineraryDetailView({
    super.key,
    required this.tripTitle,
    required this.startDate,
    required this.endDate,
    this.travelerInitial = 'N',
  });

  final String tripTitle;
  final DateTime startDate;
  final DateTime endDate;
  final String travelerInitial;

  @override
  State<TripItineraryDetailView> createState() => _TripItineraryDetailViewState();
}

class _TripItineraryDetailViewState extends State<TripItineraryDetailView> {
  int _selectedDayIndex = 0;
  final Map<int, List<TripTimelineEntry>> _entriesByDay = {};

  List<TripDayItem> get _days {
    final totalDays = widget.endDate.difference(widget.startDate).inDays + 1;
    return List.generate(totalDays, (index) {
      final date = widget.startDate.add(Duration(days: index));
      return TripDayItem(
        label: 'NGÀY ${index + 1}',
        dayNumber: '${index + 1}'.padLeft(2, '0'),
        date: '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
      );
    });
  }

  List<TripTimelineEntry> get _selectedEntries =>
      _entriesByDay[_selectedDayIndex] ?? const [];

  void _openEditItinerary() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditItineraryView(
          tripTitle: widget.tripTitle,
          travelerInitial: widget.travelerInitial,
          entries: _selectedEntries,
        ),
      ),
    );
  }

  Future<void> _openAddServiceSheet() async {
    final entry = await showModalBottomSheet<TripTimelineEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const AddTripServiceSheet(),
    );

    if (entry == null) {
      return;
    }

    setState(() {
      final currentEntries = List<TripTimelineEntry>.from(_selectedEntries)
        ..add(entry)
        ..sort((a, b) => a.time.compareTo(b.time));
      _entriesByDay[_selectedDayIndex] = currentEntries;
    });
  }

  String get _dateRangeLabel {
    final start = widget.startDate;
    final end = widget.endDate;
    final startText = '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}';
    final endText =
        '${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
    return '$startText - $endText';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TripUiColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  TripCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Lịch trình chi tiết',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: TripUiColors.textPrimary,
                      ),
                    ),
                  ),
                  TripCircleButton(
                    icon: Icons.edit_outlined,
                    onTap: _openEditItinerary,
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFB7F5C6), Color(0xFF1FB266)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.travelerInitial,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    ItineraryHeroCard(
                      title: widget.tripTitle,
                      dateRangeLabel: _dateRangeLabel,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: TripUiColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ItinerarySegmentButton(
                              label: 'Lịch trình',
                              isSelected: true,
                              onTap: () {},
                            ),
                          ),
                          Expanded(
                            child: ItinerarySegmentButton(
                              label: 'Bản đồ',
                              isSelected: false,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TripDaySelector(
                      days: _days,
                      selectedDayIndex: _selectedDayIndex,
                      onSelected: (index) => setState(() => _selectedDayIndex = index),
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      onTap: _openAddServiceSheet,
                      borderRadius: BorderRadius.circular(22),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: const Color(0xFFE8FFF0),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              size: 16,
                              color: TripUiColors.timelineGreen,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Thêm dịch vụ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: TripUiColors.timelineGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_selectedEntries.isEmpty)
                      TripTimelineEmptyState(
                        onAddPressed: _openAddServiceSheet,
                      )
                    else
                      TripTimeline(entries: _selectedEntries),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
