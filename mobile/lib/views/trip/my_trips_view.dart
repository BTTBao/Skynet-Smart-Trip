import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/activity_history.dart';
import '../../models/my_trip_summary.dart';
import '../../providers/trip_provider.dart';
import '../../services/activity_history_service.dart';
import '../../services/api_service_base.dart';
import '../../services/trip_service.dart';
import '../../widgets/trip/widgets.dart';
import 'create_trip_view.dart';
import 'trip_itinerary_detail_view.dart';
import 'trip_ui_constants.dart';

class MyTripsView extends StatefulWidget {
  const MyTripsView({super.key});

  @override
  State<MyTripsView> createState() => _MyTripsViewState();
}

class _MyTripsViewState extends State<MyTripsView> {
  int _selectedTabIndex = 0;
  final TextEditingController _shareCodeController = TextEditingController();
  final ActivityHistoryService _activityHistoryService = ActivityHistoryService();
  final TripService _tripService = TripService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().fetchTrips();
    });
  }

  @override
  void dispose() {
    _shareCodeController.dispose();
    super.dispose();
  }

  void _openCreateTrip() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateTripView()),
    );
  }

  void _openEditTrip(MyTripSummary trip) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateTripView(
          editTripId: trip.tripId,
          initialTitle: trip.title,
          initialDestination: trip.destination,
          initialDestinationId: trip.destinationId,
          initialShareCode: trip.shareCode,
          initialStartDate: trip.startDate,
          initialEndDate: trip.endDate,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTrip(
    TripProvider provider,
    MyTripSummary trip,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xóa chuyến đi?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Bạn có chắc muốn xóa "${trip.title}"? Hành động này không thể hoàn tác.',
          style: const TextStyle(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await provider.deleteTrip(trip.tripId);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã xóa chuyến đi.'
              : (provider.error ?? 'Xóa chuyến đi thất bại.'),
        ),
        backgroundColor: success ? TripUiColors.timelineGreen : Colors.redAccent,
      ),
    );
  }

  void _openTripDetail(MyTripSummary trip) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripItineraryDetailView(
          tripId: trip.tripId,
          tripTitle: trip.title,
          startDate: trip.startDate,
          endDate: trip.endDate,
          travelerInitial: trip.title.isEmpty ? 'T' : trip.title[0].toUpperCase(),
        ),
      ),
    );
  }

  Future<void> _openSharedTripByCode(TripProvider provider) async {
    final code = _shareCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập mã chuyến đi để tìm kiếm.')),
      );
      return;
    }

    if (provider.trips.isEmpty) {
      await provider.fetchTrips(silent: true);
      if (!mounted) return;
    }

    final existingTrip = provider.findTripByShareCode(code);
    if (existingTrip != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chuyến đi đã có trong danh sách của bạn.'),
        ),
      );
      _openTripDetail(existingTrip);
      return;
    }

    final sharedTrip = await provider.fetchSharedTripDetail(code);
    if (!mounted) {
      return;
    }

    if (sharedTrip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Không tìm thấy chuyến đi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (sharedTrip.canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chuyến đi đã có trong danh sách của bạn.'),
        ),
      );
      MyTripSummary? ownTrip;
      for (final trip in provider.trips) {
        if (trip.tripId == sharedTrip.tripId) {
          ownTrip = trip;
          break;
        }
      }
      if (ownTrip != null) {
        _openTripDetail(ownTrip);
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TripItineraryDetailView(
              tripId: sharedTrip.tripId,
              tripTitle: sharedTrip.title,
              startDate: sharedTrip.startDate,
              endDate: sharedTrip.endDate,
            ),
          ),
        );
      }
      return;
    }

    if (!sharedTrip.canSave) {
      final savedTripId = sharedTrip.savedTripId;
      if (savedTripId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chuyến đi đã có trong danh sách của bạn.'),
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TripItineraryDetailView(
              tripId: savedTripId,
              tripTitle: sharedTrip.title,
              startDate: sharedTrip.startDate,
              endDate: sharedTrip.endDate,
            ),
          ),
        );
        return;
      }

      final savedCopy = provider.findSavedCopyOfTrip(sharedTrip.tripId);
      if (savedCopy != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chuyến đi đã có trong danh sách của bạn.'),
          ),
        );
        _openTripDetail(savedCopy);
        return;
      }
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripItineraryDetailView(
          tripId: sharedTrip.tripId,
          tripTitle: sharedTrip.title,
          startDate: sharedTrip.startDate,
          endDate: sharedTrip.endDate,
          shareCode: code.trim().toUpperCase(),
        ),
      ),
    );
  }

  Future<void> _openReviewServices(MyTripSummary trip) async {
    _showBlockingLoader();

    try {
      final history = await _activityHistoryService.getActivityHistory();
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      final services = _reviewableServicesForTrip(history, trip.tripId);
      _showReviewServicesSheet(trip, services);
    } catch (error) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      final message = error is ApiException
          ? error.message
          : error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  List<_ReviewableService> _reviewableServicesForTrip(
    ActivityHistory history,
    int tripId,
  ) {
    final hotelServices = history.hotels
        .where((item) => item.tripId == tripId)
        .where(
          (item) => _canReviewService(
            isReviewed: item.isReviewed,
            status: item.status,
            completedAt: item.checkOutDate,
          ),
        )
        .map(
          (item) => _ReviewableService(
            tripId: item.tripId,
            targetType: 'Hotel',
            targetId: item.serviceId,
            title: item.hotelName,
            subtitle: item.destinationName.isEmpty
                ? item.address
                : '${item.destinationName} - ${item.address}',
            serviceLabel: 'khách sạn',
            icon: Icons.hotel_rounded,
          ),
        );

    final busServices = history.buses
        .where((item) => item.tripId == tripId)
        .where(
          (item) => _canReviewService(
            isReviewed: item.isReviewed,
            status: item.status,
            completedAt: item.arrivalTime,
          ),
        )
        .map(
          (item) => _ReviewableService(
            tripId: item.tripId,
            targetType: 'BusCompany',
            targetId: item.companyId,
            title: item.companyName,
            subtitle: '${item.fromDestination} -> ${item.toDestination}',
            serviceLabel: 'nhà xe',
            icon: Icons.directions_bus_rounded,
          ),
        );

    return [...hotelServices, ...busServices];
  }

  bool _canReviewService({
    required bool isReviewed,
    required String status,
    required String? completedAt,
  }) {
    if (isReviewed || status.toUpperCase() != 'PAID') {
      return false;
    }

    final parsed = DateTime.tryParse(completedAt ?? '');
    if (parsed == null) {
      return false;
    }

    final now = DateTime.now();
    final raw = (completedAt ?? '').trim();
    final completedLocal = parsed.toLocal();
    final hasExplicitTime = raw.contains('T') || raw.contains(':');

    if (hasExplicitTime) {
      return !completedLocal.isAfter(now);
    }

    final today = DateTime(now.year, now.month, now.day);
    final completedDate = DateTime(
      completedLocal.year,
      completedLocal.month,
      completedLocal.day,
    );
    return today.isAfter(completedDate);
  }

  void _showBlockingLoader() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: TripUiColors.primaryGreen),
      ),
    );
  }

  void _showReviewServicesSheet(
    MyTripSummary trip,
    List<_ReviewableService> services,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7DEE5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Dịch vụ có thể đánh giá',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: TripUiColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trip.title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: TripUiColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                if (services.isEmpty)
                  const _ReviewEmptyState()
                else
                  ...services.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReviewServiceTile(
                        service: service,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _showReviewFormSheet(service);
                        },
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

  void _showReviewFormSheet(_ReviewableService service) {
    int selectedRating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD7DEE5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7E6),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                service.icon,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Đánh giá ${service.serviceLabel}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    service.title,
                                    style: const TextStyle(
                                      color: TripUiColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: Text(
                            _ratingLabel(selectedRating),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: TripUiColors.timelineGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starRating = index + 1;
                            return IconButton(
                              tooltip: '$starRating sao',
                              icon: Icon(
                                starRating <= selectedRating
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: const Color(0xFFF59E0B),
                                size: 42,
                              ),
                              onPressed: isSubmitting
                                  ? null
                                  : () => setSheetState(() {
                                        selectedRating = starRating;
                                      }),
                            );
                          }),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: commentController,
                          minLines: 4,
                          maxLines: 4,
                          maxLength: 500,
                          enabled: !isSubmitting,
                          decoration: InputDecoration(
                            hintText:
                                'Chia sẻ điều bạn thích hoặc điều cần cải thiện...',
                            filled: true,
                            fillColor: const Color(0xFFF7F9FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: TripUiColors.timelineGreen,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () => Navigator.of(sheetContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text('Để sau'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        setSheetState(() {
                                          isSubmitting = true;
                                        });

                                        try {
                                          await _tripService.submitReview(
                                            tripId: service.tripId,
                                            targetType: service.targetType,
                                            targetId: service.targetId,
                                            rating: selectedRating,
                                            comment:
                                                commentController.text.trim(),
                                          );

                                          if (!mounted) {
                                            return;
                                          }

                                          Navigator.of(sheetContext).pop();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Cảm ơn bạn đã gửi đánh giá.',
                                              ),
                                              backgroundColor:
                                                  TripUiColors.timelineGreen,
                                            ),
                                          );
                                        } catch (error) {
                                          if (!mounted) {
                                            return;
                                          }

                                          setSheetState(() {
                                            isSubmitting = false;
                                          });
                                          final message = error is ApiException
                                              ? error.message
                                              : error
                                                  .toString()
                                                  .replaceFirst(
                                                    'Exception: ',
                                                    '',
                                                  );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(message),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TripUiColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Gửi đánh giá',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _ratingLabel(int rating) {
    return switch (rating) {
      1 => 'Không hài lòng',
      2 => 'Cần cải thiện',
      3 => 'Ổn',
      4 => 'Rất tốt',
      _ => 'Tuyệt vời',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, _) {
        final visibleTrips = _selectedTabIndex == 0
            ? tripProvider.upcomingTrips
            : tripProvider.completedTrips;

        return Scaffold(
          backgroundColor: TripUiColors.background,
          floatingActionButton: MyTripsFab(
            onTap: _openCreateTrip,
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => tripProvider.fetchTrips(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chuyến đi của tôi',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: TripUiColors.textPrimary,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Khám phá và quản lý những hành trình tuyệt vời của bạn.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: TripUiColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SharedTripSearchBox(
                      controller: _shareCodeController,
                      isLoading: tripProvider.isSearchingSharedTrip,
                      onSearch: () => _openSharedTripByCode(tripProvider),
                    ),
                    const SizedBox(height: 18),
                    MyTripFilterTabs(
                      selectedIndex: _selectedTabIndex,
                      onSelected: (value) => setState(() => _selectedTabIndex = value),
                    ),
                    const SizedBox(height: 18),
                    if (tripProvider.isLoadingTrips && tripProvider.trips.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (tripProvider.error != null && tripProvider.trips.isEmpty)
                      _TripStateCard(
                        title: 'Không tải được danh sách chuyến đi',
                        subtitle: tripProvider.error!,
                        actionLabel: 'Thử lại',
                        onTap: () => tripProvider.fetchTrips(),
                      )
                    else if (visibleTrips.isEmpty)
                      _TripStateCard(
                        title: _selectedTabIndex == 0
                            ? 'Chưa có chuyến đi sắp tới'
                            : 'Chưa có chuyến đi đã hoàn thành',
                        subtitle: _selectedTabIndex == 0
                            ? 'Tạo chuyến đi mới để bắt đầu lên lịch trình.'
                            : 'Những chuyến đi đã qua sẽ xuất hiện ở đây.',
                        actionLabel: 'Tạo chuyến đi',
                        onTap: _openCreateTrip,
                      )
                    else
                      ...visibleTrips.map((trip) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: MyTripCard(
                            trip: trip,
                            onTap: () => _openTripDetail(trip),
                            onEditTap: trip.canEdit
                                ? () => _openEditTrip(trip)
                                : null,
                            onDeleteTap: () => _confirmDeleteTrip(tripProvider, trip),
                            onReviewTap: _selectedTabIndex == 1 &&
                                    trip.status != 'CANCELLED'
                                ? () => _openReviewServices(trip)
                                : null,
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SharedTripSearchBox extends StatelessWidget {
  const _SharedTripSearchBox({
    required this.controller,
    required this.isLoading,
    required this.onSearch,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EDF1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isLoading,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Nhập mã chuyến đi',
                hintStyle: TextStyle(fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: TripUiColors.textSecondary,
                  size: 20,
                ),
                prefixIconConstraints: BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              onSubmitted: (_) => isLoading ? null : onSearch(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: TripUiColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Tìm',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripStateCard extends StatelessWidget {
  const _TripStateCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7EDF1)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.route_outlined,
            size: 40,
            color: TripUiColors.timelineGreen,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: TripUiColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: TripUiColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: TripUiColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _ReviewableService {
  const _ReviewableService({
    required this.tripId,
    required this.targetType,
    required this.targetId,
    required this.title,
    required this.subtitle,
    required this.serviceLabel,
    required this.icon,
  });

  final int tripId;
  final String targetType;
  final int targetId;
  final String title;
  final String subtitle;
  final String serviceLabel;
  final IconData icon;
}

class _ReviewServiceTile extends StatelessWidget {
  const _ReviewServiceTile({
    required this.service,
    required this.onTap,
  });

  final _ReviewableService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F9FA),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  service.icon,
                  color: TripUiColors.timelineGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: TripUiColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      service.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: TripUiColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewEmptyState extends StatelessWidget {
  const _ReviewEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 34,
            color: TripUiColors.timelineGreen,
          ),
          SizedBox(height: 10),
          Text(
            'Chưa có dịch vụ cần đánh giá',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: TripUiColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Các dịch vụ đã đánh giá hoặc chưa đủ điều kiện sẽ không hiện ở đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: TripUiColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
