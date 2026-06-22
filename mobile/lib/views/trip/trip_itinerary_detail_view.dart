import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../widgets/trip/place_search_field.dart';

class TripItineraryDetailView extends StatefulWidget {
  const TripItineraryDetailView({
    super.key,
    required this.tripId,
    this.tripTitle,
    this.startDate,
    this.endDate,
    this.shareCode,
    this.travelerInitial = 'N',
  });

  final int tripId;
  final String? tripTitle;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? shareCode;
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
      final code = widget.shareCode?.trim();
      if (code != null && code.isNotEmpty) {
        context.read<TripProvider>().fetchSharedTripDetail(code);
      } else {
        context.read<TripProvider>().fetchTripDetail(widget.tripId);
      }
    });
  }

  TripDetail? _detailFrom(TripProvider provider) {
    final isSharedPreview =
        widget.shareCode != null && widget.shareCode!.trim().isNotEmpty;

    if (isSharedPreview) {
      if (provider.currentTrip == null) {
        return null;
      }
      return provider.currentTrip;
    }

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
        label: 'NGÀY ${index + 1}',
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
          tripId: widget.tripId,
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
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTimelineEntrySheet(
        entry: entry,
        tripStartDate: detail.startDate,
        tripEndDate: detail.endDate,
        destinationName: detail.destinationName,
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
        destinationName: detail?.destinationName,
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

    final itineraryId = await provider.addItinerary(widget.tripId, result);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          itineraryId != null ? 'Đã thêm dịch vụ vào lịch trình.' : (provider.error ?? 'Thêm dịch vụ thất bại.'),
        ),
      ),
    );
  }

  Future<void> _saveSharedTrip(TripProvider provider, TripDetail detail) async {
    final savedTrip = await provider.saveSharedTrip(detail.shareCode);
    if (!mounted) {
      return;
    }

    if (savedTrip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Lưu lịch trình thất bại.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu lịch trình vào danh sách chuyến đi.'),
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TripItineraryDetailView(
          tripId: savedTrip.tripId,
          tripTitle: savedTrip.title,
          startDate: savedTrip.startDate,
          endDate: savedTrip.endDate,
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
        final resolvedTitle = detail?.title ?? widget.tripTitle ?? 'Chi tiết chuyến đi';
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
        final canEditTrip = detail?.canEdit ?? widget.shareCode == null;
        final canSaveTrip =
            detail?.canSave == true && (detail?.shareCode ?? '').isNotEmpty;
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
                      onPressed: () {
                        final code = widget.shareCode?.trim();
                        if (code != null && code.isNotEmpty) {
                          tripProvider.fetchSharedTripDetail(code);
                        } else {
                          tripProvider.fetchTripDetail(widget.tripId);
                        }
                      },
                      child: const Text('Thử lại'),
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
                          'Lịch trình chi tiết',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: TripUiColors.textPrimary,
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
                              : 'Đang cập nhật',
                        ),
                        if ((detail?.shareCode ?? '').isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _ShareCodeBanner(shareCode: detail!.shareCode),
                        ],
                        if (!canEditTrip) ...[
                          const SizedBox(height: 10),
                          _ReadOnlyBanner(
                            canSave: canSaveTrip,
                            isSubmitting: tripProvider.isSubmitting,
                            onSave: canSaveTrip && detail != null
                                ? () => _saveSharedTrip(tripProvider, detail)
                                : null,
                          ),
                        ],
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
                        if (canEditTrip)
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
                                      ? 'Đang xử lý...'
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
                            onAddPressed: canEditTrip
                                ? () => _openAddServiceSheet(
                                      tripProvider,
                                      detail,
                                      selectedDayNumber,
                                      selectedServiceDate,
                                      resolvedStartDate,
                                      resolvedEndDate,
                                    )
                                : null,
                          )
                        else
                          TripTimeline(
                            entries: selectedEntries,
                            canManageEntry: canEditTrip ? _isNoteEntry : null,
                            onInvoiceEntry: (entry) =>
                                _openInvoiceDetail(detail, entry),
                            onEditEntry: detail == null || !canEditTrip
                                ? null
                                : (entry) => _openEditEntrySheet(
                                      tripProvider,
                                      detail,
                                      entry,
                                    ),
                            onDeleteEntry: canEditTrip
                                ? (entry) => _deleteEntry(
                                      tripProvider,
                                      entry,
                                    )
                                : null,
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

class _ShareCodeBanner extends StatelessWidget {
  const _ShareCodeBanner({required this.shareCode});

  final String shareCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EDF1)),
      ),
      child: Row(
        children: [
          const Text(
            'Mã chuyến đi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: TripUiColors.textSecondary,
            ),
          ),
          const Spacer(),
          SelectableText(
            shareCode,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: TripUiColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: shareCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép mã chuyến đi'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE8FFF0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.copy_rounded,
                size: 16,
                color: TripUiColors.timelineGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner({
    required this.canSave,
    required this.isSubmitting,
    this.onSave,
  });

  final bool canSave;
  final bool isSubmitting;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FFF0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Bạn đang xem lịch trình được chia sẻ. Lưu về danh sách để chỉnh sửa.',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: TripUiColors.timelineGreen,
              ),
            ),
          ),
          if (canSave) ...[
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: isSubmitting ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: TripUiColors.timelineGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.bookmark_add_rounded, size: 17),
              label: Text(isSubmitting ? 'Đang lưu' : 'Lưu'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditTimelineEntrySheet extends StatefulWidget {
  const _EditTimelineEntrySheet({
    required this.entry,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.destinationName,
  });

  final TripTimelineEntry entry;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final String destinationName;

  @override
  State<_EditTimelineEntrySheet> createState() =>
      _EditTimelineEntrySheetState();
}

class _EditTimelineEntrySheetState extends State<_EditTimelineEntrySheet> {
  late String _contentText;
  late DateTime _serviceDate;
  late TimeOfDay _departureTime;
  String _searchAddress = '';

  bool get _isNote =>
      (widget.entry.serviceType ?? '').toUpperCase() == 'NOTE';

  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final initialDate = widget.entry.serviceDate ?? widget.tripStartDate;
    _serviceDate = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    );
    _departureTime =
        _parseTime(widget.entry.departureTime) ?? TimeOfDay.now();
    _contentText = widget.entry.serviceAddress ??
        (_isNote ? widget.entry.description : '');
    if (_isNote) {
      final parts = _contentText.split('\n');
      _searchAddress = parts.isNotEmpty ? parts[0].trim() : '';
      final noteContent = parts.length > 1 ? parts.skip(1).join('\n').trim() : '';
      _noteController = TextEditingController(text: noteContent);
    } else {
      _searchAddress = _contentText;
      _noteController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
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
    if (picked == null) return;
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
    if (picked == null) return;
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
    final placeName = _isNote ? _searchAddress.trim() : _contentText.trim();
    final noteContent = _isNote ? _noteController.text.trim() : '';

    if (placeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập và chọn địa điểm.')),
      );
      return;
    }

    String combinedAddress = placeName;
    if (_isNote && noteContent.isNotEmpty) {
      combinedAddress = '$placeName\n$noteContent';
    }

    final timeText =
        '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}:00';

    Navigator.of(context).pop(
      UpdateTripItineraryRequest(
        dayNumber: _resolveDayNumber(),
        serviceDate: _serviceDate,
        departureTime: timeText,
        serviceAddress: combinedAddress,
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
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7DDE3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FFF0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_location_alt_rounded,
                    color: TripUiColors.timelineGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isNote ? 'Sửa ghi chú' : 'Sửa mục lịch trình',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: TripUiColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.entry.caption,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: TripUiColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 18),
            if (_isNote) ...[
              PlaceSearchField(
                initialValue: _searchAddress.isNotEmpty ? _searchAddress : null,
                labelText: 'Địa điểm',
                hintText: 'Nhập tên địa điểm để tìm trên bản đồ...',
                destinationName: widget.destinationName,
                onAddressConfirmed: (addr) {
                  setState(() => _searchAddress = addr);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Nội dung ghi chú (không bắt buộc)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TripUiColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Ăn tối, chụp ảnh lưu niệm...',
                  filled: true,
                  fillColor: const Color(0xFFF1F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ] else ...[
              PlaceSearchField(
                initialValue: _contentText,
                labelText: 'Địa điểm',
                hintText: 'Nhập tên địa điểm để tìm trên bản đồ...',
                destinationName: widget.destinationName,
                onAddressConfirmed: (addr) {
                  setState(() => _contentText = addr);
                },
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TripUiColors.timelineGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text(
                  'Lưu thay đổi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
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
