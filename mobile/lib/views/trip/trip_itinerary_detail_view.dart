import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/create_trip_itinerary_request.dart';
import '../../models/trip_day_item.dart';
import '../../models/trip_detail.dart';
import '../../models/trip_timeline_entry.dart';
import '../../models/update_trip_itinerary_request.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/trip/widgets.dart';
import '../profile/invoice_detail_view.dart';
import '../transport/transport_checkout_screen.dart';
import 'trip_itinerary_map_view.dart';
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
        .where((entry) => _entryDayNumber(detail, entry) == selectedDayNumber)
        .toList();
  }

  int _entryDayNumber(TripDetail detail, TripTimelineEntry entry) {
    final serviceDate = entry.serviceDate;
    if (serviceDate != null) {
      final tripStart = DateTime(
        detail.startDate.year,
        detail.startDate.month,
        detail.startDate.day,
      );
      final entryDate = DateTime(
        serviceDate.year,
        serviceDate.month,
        serviceDate.day,
      );
      final dayNumber = entryDate.difference(tripStart).inDays + 1;
      if (dayNumber > 0) {
        return dayNumber;
      }
    }

    return entry.dayNumber ?? 1;
  }

  bool _isNoteEntry(TripTimelineEntry entry) {
    return (entry.serviceType ?? '').toUpperCase() == 'NOTE';
  }

  void _openInvoiceDetail(TripDetail? detail, TripTimelineEntry entry) {
    final serviceType = (entry.serviceType ?? '').toUpperCase();
    final isBus = serviceType == 'BUS';
    final isHotel = serviceType == 'HOTEL';

    if (!isBus && !isHotel) {
      return;
    }

    final dateText = isHotel
        ? entry.hotelBookingDateLabel ?? _dateLabel(entry.serviceDate)
        : _busDateLabel(entry);
    final quantityText = isHotel
        ? '${entry.quantity ?? 1} phòng'
        : _busQuantityLabel(entry);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvoiceDetailView(
          title: detail?.title ?? widget.tripTitle ?? entry.caption,
          serviceType: isBus ? 'Vé xe' : 'Khách sạn',
          providerName: entry.caption,
          routeOrAddress: entry.serviceAddress ?? entry.description,
          dateText: dateText,
          quantityText: quantityText,
          amount: entry.bookedPrice ?? 0,
          status: detail?.status ?? 'PAID',
          invoiceNumber: null,
        ),
      ),
    );
  }

  String _dateLabel(DateTime? date) {
    if (date == null) {
      return 'Đang cập nhật';
    }

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _busDateLabel(TripTimelineEntry entry) {
    final date = _dateLabel(entry.serviceDate);
    final time = (entry.departureTime ?? entry.time).trim();
    return time.isEmpty ? date : '$date $time';
  }

  String _busQuantityLabel(TripTimelineEntry entry) {
    final address = entry.serviceAddress ?? '';
    final seatMatch = RegExp(r'Gh[ếe]:\s*([^•]+)', caseSensitive: false)
        .firstMatch(address);
    final seats = seatMatch?.group(1)?.trim();
    if (seats != null && seats.isNotEmpty) {
      return 'Ghế $seats';
    }

    return '${entry.quantity ?? 1} vé';
  }

  void _openMapView(TripDetail? detail, String title) {
    final entries = detail?.itineraries ?? const <TripTimelineEntry>[];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripItineraryMapView(
          tripTitle: title,
          entries: entries,
        ),
      ),
    );
  }

  Future<void> _openEditEntrySheet(
    TripProvider provider,
    TripDetail detail,
    TripTimelineEntry entry,
  ) async {
    if (entry.itineraryId == null) {
      return;
    }

    final request = await showModalBottomSheet<UpdateTripItineraryRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditTimelineEntrySheet(
        entry: entry,
        tripStartDate: detail.startDate,
        tripEndDate: detail.endDate,
      ),
    );

    if (request == null || !mounted) {
      return;
    }

    final success = await provider.updateItinerary(entry.itineraryId!, request);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Đã cập nhật lịch trình.' : (provider.error ?? 'Cập nhật thất bại.'),
        ),
      ),
    );
  }

  Future<void> _deleteEntry(
    TripProvider provider,
    TripTimelineEntry entry,
  ) async {
    final itineraryId = entry.itineraryId;
    if (itineraryId == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa mục này?'),
        content: Text('Bạn có chắc muốn xóa "${entry.caption}" khỏi lịch trình không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    final success = await provider.deleteItinerary(itineraryId);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Đã xóa khỏi lịch trình.' : (provider.error ?? 'Xóa thất bại.'),
        ),
      ),
    );
  }

  Future<void> _openAddServiceSheet(
    TripProvider provider,
    TripDetail? detail,
    int selectedDayNumber,
    DateTime selectedServiceDate,
    DateTime? tripStartDate,
    DateTime? tripEndDate,
  ) async {
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddTripServiceSheet(
        tripId: widget.tripId,
        dayNumber: selectedDayNumber,
        destinationId: detail?.destinationId,
        initialServiceDate: selectedServiceDate,
        tripStartDate: tripStartDate,
        tripEndDate: tripEndDate,
      ),
    );

    if (result == null) {
      return;
    }

    if (result is TripBusCheckoutRequest) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TransportCheckoutScreen(
            existingTripId: result.tripId,
            itineraryDayNumber: result.dayNumber,
          ),
        ),
      );
      return;
    }

    if (result is! CreateTripItineraryRequest) {
      return;
    }

    final request = result;
    final success = await provider.addItinerary(widget.tripId, request);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Đã thêm dịch vụ vào lịch trình.' : (provider.error ?? 'Thêm dịch vụ thất bại.'),
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
            ? _buildDays(resolvedStartDate, resolvedEndDate)
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
        final selectedServiceDate = canRenderDays
            ? DateTime(
                resolvedStartDate.year,
                resolvedStartDate.month,
                resolvedStartDate.day,
              ).add(Duration(days: selectedDayNumber - 1))
            : DateTime.now();

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
                      tripProvider.error ?? 'Không tải được lịch trình.',
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
                              ? _dateRangeLabel(resolvedStartDate, resolvedEndDate)
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
                                  onTap: () => _openMapView(detail, resolvedTitle),
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
                                    selectedServiceDate,
                                    resolvedStartDate,
                                    resolvedEndDate,
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
                                      : 'Thêm dịch vụ',
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
                              selectedServiceDate,
                              resolvedStartDate,
                              resolvedEndDate,
                            ),
                          )
                        else
                          TripTimeline(
                            entries: selectedEntries,
                            canManageEntry: _isNoteEntry,
                            onInvoiceEntry: (entry) =>
                                _openInvoiceDetail(detail, entry),
                            onEditEntry: detail == null
                                ? null
                                : (entry) => _openEditEntrySheet(
                                      tripProvider,
                                      detail,
                                      entry,
                                    ),
                            onDeleteEntry: (entry) => _deleteEntry(
                              tripProvider,
                              entry,
                            ),
                          ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openMapView(detail, resolvedTitle),
                            icon: const Icon(Icons.route_rounded),
                            label: const Text('Xem lịch trình trên map'),
                          ),
                        ),
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

class _EditTimelineEntrySheet extends StatefulWidget {
  const _EditTimelineEntrySheet({
    required this.entry,
    required this.tripStartDate,
    required this.tripEndDate,
  });

  final TripTimelineEntry entry;
  final DateTime tripStartDate;
  final DateTime tripEndDate;

  @override
  State<_EditTimelineEntrySheet> createState() => _EditTimelineEntrySheetState();
}

class _EditTimelineEntrySheetState extends State<_EditTimelineEntrySheet> {
  late final TextEditingController _contentController;
  late DateTime _serviceDate;
  late TimeOfDay _departureTime;

  bool get _isNote => (widget.entry.serviceType ?? '').toUpperCase() == 'NOTE';

  @override
  void initState() {
    super.initState();
    final initialDate = widget.entry.serviceDate ?? widget.tripStartDate;
    _serviceDate = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    );
    _departureTime = _parseTime(widget.entry.departureTime) ?? TimeOfDay.now();
    _contentController = TextEditingController(
      text: widget.entry.serviceAddress ?? (_isNote ? widget.entry.description : ''),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: widget.tripStartDate,
      lastDate: widget.tripEndDate,
      helpText: 'Chọn ngày',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _serviceDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departureTime,
      helpText: _isNote ? 'Chọn thời gian' : 'Chọn giờ',
    );

    if (picked == null) {
      return;
    }

    setState(() => _departureTime = picked);
  }

  int _resolveDayNumber() {
    final tripStart = DateTime(
      widget.tripStartDate.year,
      widget.tripStartDate.month,
      widget.tripStartDate.day,
    );
    return _serviceDate.difference(tripStart).inDays + 1;
  }

  void _submit() {
    final content = _contentController.text.trim();
    if (_isNote && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập nội dung ghi chú.')),
      );
      return;
    }

    final timeText =
        '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}:00';

    Navigator.of(context).pop(
      UpdateTripItineraryRequest(
        dayNumber: _resolveDayNumber(),
        serviceDate: _serviceDate,
        departureTime: timeText,
        serviceAddress: content,
      ),
    );
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _timeLabel(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static TimeOfDay? _parseTime(String? value) {
    final parts = (value ?? '').split(':');
    if (parts.length < 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7DDE3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _isNote ? 'Sửa ghi chú' : 'Sửa mục lịch trình',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: TripUiColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _InlineSheetButton(
                    icon: Icons.calendar_month_rounded,
                    label: _dateLabel(_serviceDate),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InlineSheetButton(
                    icon: Icons.access_time_rounded,
                    label: _timeLabel(_departureTime),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _isNote ? 'Nội dung ghi chú' : 'Địa chỉ / ghi chú',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TripUiColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              minLines: _isNote ? 3 : 1,
              maxLines: _isNote ? 5 : 3,
              decoration: InputDecoration(
                hintText: _isNote
                    ? 'Nhập nội dung ghi chú'
                    : 'Nhập địa chỉ hoặc ghi chú ngắn',
                filled: true,
                fillColor: const Color(0xFFF1F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TripUiColors.timelineGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Lưu thay đổi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineSheetButton extends StatelessWidget {
  const _InlineSheetButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: TripUiColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TripUiColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
