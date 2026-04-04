import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/create_trip_itinerary_request.dart';
import '../../models/trip_day_item.dart';
import '../../models/trip_detail.dart';
import '../../models/trip_timeline_entry.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/trip/widgets.dart';
import 'create_trip_view.dart';
import 'edit_itinerary_view.dart';
import 'trip_ui_constants.dart';

class TripItineraryDetailView extends StatefulWidget {
  const TripItineraryDetailView({
    super.key,
    required this.tripId,
    this.tripTitle,
    this.startDate,
    this.endDate,
    this.travelerInitial = 'N',
  });

  final int tripId;
  final String? tripTitle;
  final DateTime? startDate;
  final DateTime? endDate;
  final String travelerInitial;

  @override
  State<TripItineraryDetailView> createState() => _TripItineraryDetailViewState();
}

class _TripItineraryDetailViewState extends State<TripItineraryDetailView> {
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().fetchTripDetail(widget.tripId);
    });
  }

  TripDetail? _detailFrom(TripProvider provider) {
    if (provider.currentTripId != widget.tripId) {
      return null;
    }
    return provider.currentTrip;
  }

  List<TripDayItem> _buildDays(DateTime startDate, DateTime endDate) {
    final totalDays = endDate.difference(startDate).inDays + 1;
    return List.generate(totalDays, (index) {
      final date = startDate.add(Duration(days: index));
      return TripDayItem(
        label: 'NGAY ${index + 1}',
        dayNumber: '${index + 1}'.padLeft(2, '0'),
        date:
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
      );
    });
  }

  List<TripTimelineEntry> _entriesForDay(TripDetail? detail, int selectedDayNumber) {
    if (detail == null) {
      return const [];
    }

    return detail.itineraries
        .where((entry) => (entry.dayNumber ?? 1) == selectedDayNumber)
        .toList();
  }

  void _openEditItinerary(List<TripTimelineEntry> entries, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditItineraryView(
          tripId: widget.tripId,
          tripTitle: title,
          travelerInitial: widget.travelerInitial,
          entries: entries,
        ),
      ),
    );
  }

  Future<void> _openAddServiceSheet(
    TripProvider provider,
    TripDetail? detail,
    int selectedDayNumber,
  ) async {
    final request = await showModalBottomSheet<CreateTripItineraryRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddTripServiceSheet(
        dayNumber: selectedDayNumber,
        destinationId: detail?.destinationId,
      ),
    );

    if (request == null) {
      return;
    }

    final success = await provider.addItinerary(widget.tripId, request);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Da them dich vu vao lich trinh.' : (provider.error ?? 'Them dich vu that bai.'),
        ),
      ),
    );
  }

  String _dateRangeLabel(DateTime startDate, DateTime endDate) {
    final startText =
        '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}';
    final endText =
        '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}';
    return '$startText - $endText';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, _) {
        final detail = _detailFrom(tripProvider);
        final resolvedTitle = detail?.title ?? widget.tripTitle ?? 'Chi tiet chuyen di';
        final resolvedStartDate = detail?.startDate ?? widget.startDate;
        final resolvedEndDate = detail?.endDate ?? widget.endDate;
        final canRenderDays = resolvedStartDate != null && resolvedEndDate != null;
        final days = canRenderDays
            ? _buildDays(resolvedStartDate!, resolvedEndDate!)
            : const <TripDayItem>[];

        if (days.isNotEmpty && _selectedDayIndex >= days.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedDayIndex = days.length - 1;
              });
            }
          });
        }

        final selectedDayNumber = days.isEmpty ? 1 : _selectedDayIndex + 1;
        final selectedEntries = _entriesForDay(detail, selectedDayNumber);

        if (tripProvider.isLoadingTripDetail && detail == null && !canRenderDays) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (detail == null && !canRenderDays) {
          return Scaffold(
            backgroundColor: TripUiColors.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      size: 44,
                      color: TripUiColors.timelineGreen,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tripProvider.error ?? 'Khong tai duoc lich trinh.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => tripProvider.fetchTripDetail(widget.tripId),
                      child: const Text('Thu lai'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

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
                          'Lich trinh chi tiet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: TripUiColors.textPrimary,
                          ),
                        ),
                      ),
                      TripCircleButton(
                        icon: Icons.info_outline_rounded,
                        onTap: () {
                          if (detail != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CreateTripView(
                                  editTripId: detail.tripId,
                                  initialTitle: detail.title,
                                  initialDestination: detail.destinationName,
                                  initialStartDate: detail.startDate,
                                  initialEndDate: detail.endDate,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      TripCircleButton(
                        icon: Icons.edit_note_rounded,
                        onTap: () => _openEditItinerary(selectedEntries, resolvedTitle),
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
                          style: const TextStyle(
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
                          title: resolvedTitle,
                          dateRangeLabel: canRenderDays
                              ? _dateRangeLabel(resolvedStartDate!, resolvedEndDate!)
                              : 'Dang cap nhat',
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
                                  label: 'Lich trinh',
                                  isSelected: true,
                                  onTap: () {},
                                ),
                              ),
                              Expanded(
                                child: ItinerarySegmentButton(
                                  label: 'Ban do',
                                  isSelected: false,
                                  onTap: () {},
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (days.isNotEmpty)
                          TripDaySelector(
                            days: days,
                            selectedDayIndex: _selectedDayIndex,
                            onSelected: (index) => setState(() => _selectedDayIndex = index),
                          ),
                        const SizedBox(height: 18),
                        InkWell(
                          onTap: tripProvider.isSubmitting
                              ? null
                              : () => _openAddServiceSheet(
                                    tripProvider,
                                    detail,
                                    selectedDayNumber,
                                  ),
                          borderRadius: BorderRadius.circular(22),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: const Color(0xFFE8FFF0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 16,
                                  color: TripUiColors.timelineGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tripProvider.isSubmitting
                                      ? 'Dang xu ly...'
                                      : 'Them dich vu',
                                  style: const TextStyle(
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
                        if (selectedEntries.isEmpty)
                          TripTimelineEmptyState(
                            onAddPressed: () => _openAddServiceSheet(
                              tripProvider,
                              detail,
                              selectedDayNumber,
                            ),
                          )
                        else
                          TripTimeline(entries: selectedEntries),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
