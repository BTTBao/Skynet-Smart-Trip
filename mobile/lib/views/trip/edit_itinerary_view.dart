import 'package:provider/provider.dart';

import '../../models/edit_itinerary_activity.dart';
import '../../models/edit_itinerary_favorite.dart';
import '../../models/edit_itinerary_service_type.dart';
import '../../models/trip_timeline_entry.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/trip/widgets.dart';
import 'edit_itinerary_view_data.dart';
import 'trip_ui_constants.dart';

class EditItineraryView extends StatefulWidget {
  const EditItineraryView({
    super.key,
    required this.tripId,
    required this.tripTitle,
    required this.travelerInitial,
    required this.entries,
  });

  final int tripId;
  final String tripTitle;
  final String travelerInitial;
  final List<TripTimelineEntry> entries;

  @override
  State<EditItineraryView> createState() => _EditItineraryViewState();
}

class _EditItineraryViewState extends State<EditItineraryView> {
  late final List<EditItineraryActivity> _activities;

  @override
  void initState() {
    super.initState();
    _activities = widget.entries.isEmpty
        ? List<EditItineraryActivity>.from(editItineraryDefaultActivities)
        : widget.entries.map(_mapTimelineEntryToActivity).toList();
  }

  Future<void> _removeActivity(int index) async {
    final activity = _activities[index];
    if (activity.itineraryId != null) {
      final tripProvider = context.read<TripProvider>();
      final success = await tripProvider.deleteItinerary(activity.itineraryId!);
      if (!mounted) return;
      
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tripProvider.error ?? 'Xóa dịch vụ thất bại.')),
        );
        return;
      }
    }

    setState(() {
      _activities.removeAt(index);
    });
  }

  void _showComingSoonMessage(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label sẽ được nối chức năng ở bước tiếp theo.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TripUiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TripScreenHeader(
                title: 'Chỉnh sửa Lịch trình',
                onBack: () => Navigator.of(context).maybePop(),
                trailing: Container(
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
              ),
              const SizedBox(height: 8),
              Text(
                widget.tripTitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: TripUiColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              const EditItinerarySectionHeader(title: 'Danh sách hoạt động'),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Hoạt động',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: TripUiColors.timelineGreen,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Khung thời gian',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: TripUiColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (context.watch<TripProvider>().isSubmitting)
                const Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ))
              else
                ...List.generate(_activities.length, (index) {
                  final activity = _activities[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: EditItineraryActivityCard(
                      activity: activity,
                      onDelete: () => _removeActivity(index),
                    ),
                  );
                }),
              const SizedBox(height: 18),
              const EditItinerarySectionHeader(title: 'Thêm dịch vụ mới'),
              const SizedBox(height: 12),
              Row(
                children: [
                  EditItineraryServiceTypeCard(
                    serviceType: editItineraryServiceTypes[0],
                    onTap: () => _showComingSoonMessage(editItineraryServiceTypes[0].label),
                  ),
                  const SizedBox(width: 12),
                  EditItineraryServiceTypeCard(
                    serviceType: editItineraryServiceTypes[1],
                    onTap: () => _showComingSoonMessage(editItineraryServiceTypes[1].label),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              EditItinerarySectionHeader(
                title: 'Gợi ý từ Yêu thích',
                actionLabel: 'Xem tất cả',
                onActionTap: () => _showComingSoonMessage('Danh sách yêu thích'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 170,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: editItineraryFavorites.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return EditItineraryFavoriteCard(
                      favorite: editItineraryFavorites[index],
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng cập nhật số lượng sẽ có trong phiên bản tới.')),
                    );
                    Navigator.of(context).maybePop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7BE495),
                    foregroundColor: const Color(0xFF135D2B),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text(
                    'Hoàn tất chỉnh sửa',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  EditItineraryActivity _mapTimelineEntryToActivity(TripTimelineEntry entry) {
    return EditItineraryActivity(
      itineraryId: entry.itineraryId,
      dayNumber: entry.dayNumber,
      title: entry.caption,
      location: entry.description,
      timeRange: '${entry.time} - ${_buildEndTime(entry.time)}',
      imageGradient: _gradientForSection(entry.sectionTitle),
    );
  }

  String _buildEndTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) {
      return time;
    }

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final endMinutes = (hour * 60) + minute + 90;
    final endHour = ((endMinutes ~/ 60) % 24).toString().padLeft(2, '0');
    final endMinute = (endMinutes % 60).toString().padLeft(2, '0');
    return '$endHour:$endMinute';
  }

  List<Color> _gradientForSection(String sectionTitle) {
    final normalized = sectionTitle.toLowerCase();
    if (normalized.contains('bay') || normalized.contains('di chuyển')) {
      return const [Color(0xFF2D6CDF), Color(0xFF6CC3FF)];
    }
    if (normalized.contains('nhận phòng') || normalized.contains('lưu trú')) {
      return const [Color(0xFF0F766E), Color(0xFF5EEAD4)];
    }
    if (normalized.contains('ăn') || normalized.contains('food')) {
      return const [Color(0xFFB45309), Color(0xFFFBBF24)];
    }
    return const [Color(0xFF6D28D9), Color(0xFFBAA6FF)];
  }
}
