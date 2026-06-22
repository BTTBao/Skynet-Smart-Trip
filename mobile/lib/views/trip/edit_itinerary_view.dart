import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/edit_itinerary_activity.dart';
import '../../models/trip_timeline_entry.dart';
import '../../models/update_trip_itinerary_request.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/trip/widgets.dart';
import 'edit_itinerary_view_data.dart';
import 'trip_ui_constants.dart';
import '../../widgets/trip/place_search_field.dart';

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
          SnackBar(
            content: Text(tripProvider.error ?? 'Xóa dịch vụ thất bại.'),
          ),
        );
        return;
      }
    }

    setState(() {
      _activities.removeAt(index);
    });
  }

  Future<void> _editActivity(int index) async {
    final activity = _activities[index];
    if (activity.itineraryId == null) {
      _showComingSoonMessage('Chinh sua muc goi y');
      return;
    }

    final updatedActivity = await showModalBottomSheet<EditItineraryActivity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditActivitySheet(activity: activity),
    );

    if (updatedActivity == null || !mounted) {
      return;
    }

    final tripProvider = context.read<TripProvider>();
    final success = await tripProvider.updateItinerary(
      updatedActivity.itineraryId!,
      UpdateTripItineraryRequest(
        dayNumber: updatedActivity.dayNumber,
        serviceDate: updatedActivity.serviceDate,
        departureTime: updatedActivity.departureTime,
        serviceAddress: updatedActivity.serviceAddress,
      ),
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tripProvider.error ?? 'Cap nhat dia diem that bai.'),
        ),
      );
      return;
    }

    setState(() {
      _activities[index] = updatedActivity;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Da cap nhat dia diem trong lich trinh.')),
    );
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
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                ...List.generate(_activities.length, (index) {
                  final activity = _activities[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: EditItineraryActivityCard(
                      activity: activity,
                      onEdit: () => _editActivity(index),
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
                    onTap: () => _showComingSoonMessage(
                      editItineraryServiceTypes[0].label,
                    ),
                  ),
                  const SizedBox(width: 12),
                  EditItineraryServiceTypeCard(
                    serviceType: editItineraryServiceTypes[1],
                    onTap: () => _showComingSoonMessage(
                      editItineraryServiceTypes[1].label,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              EditItinerarySectionHeader(
                title: 'Gợi ý từ Yêu thích',
                actionLabel: 'Xem tất cả',
                onActionTap: () =>
                    _showComingSoonMessage('Danh sách yêu thích'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 170,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: editItineraryFavorites.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
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
                      const SnackBar(
                        content: Text(
                          'Chức năng cập nhật số lượng sẽ có trong phiên bản tới.',
                        ),
                      ),
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
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
      serviceDate: entry.serviceDate,
      departureTime: entry.departureTime,
      serviceAddress: entry.serviceAddress,
      quantity: entry.quantity,
      bookedPrice: entry.bookedPrice,
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

class _EditActivitySheet extends StatefulWidget {
  const _EditActivitySheet({required this.activity});

  final EditItineraryActivity activity;

  @override
  State<_EditActivitySheet> createState() => _EditActivitySheetState();
}

class _EditActivitySheetState extends State<_EditActivitySheet> {
  late String _addressText;
  late DateTime _serviceDate;
  late TimeOfDay _departureTime;
  String _searchAddress = '';
  late final TextEditingController _noteController;

  bool get _isNote => widget.activity.title.toLowerCase().contains('ghi chu');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _serviceDate = widget.activity.serviceDate == null
        ? DateTime(now.year, now.month, now.day)
        : DateTime(
            widget.activity.serviceDate!.year,
            widget.activity.serviceDate!.month,
            widget.activity.serviceDate!.day,
          );
    _departureTime =
        _parseTime(widget.activity.departureTime) ?? TimeOfDay.now();
    _addressText = widget.activity.serviceAddress ?? '';
    
    if (_isNote) {
      final parts = _addressText.split('\n');
      _searchAddress = parts.isNotEmpty ? parts[0].trim() : '';
      final noteContent = parts.length > 1 ? parts.skip(1).join('\n').trim() : '';
      _noteController = TextEditingController(text: noteContent);
    } else {
      _searchAddress = _addressText;
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
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Chon ngay',
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
      helpText: 'Chon gio',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _departureTime = picked;
    });
  }

  void _submit() {
    final placeName = _isNote ? _searchAddress.trim() : _addressText.trim();
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
    final dayNumber = widget.activity.dayNumber;
    Navigator.of(context).pop(
      EditItineraryActivity(
        itineraryId: widget.activity.itineraryId,
        dayNumber: dayNumber,
        title: widget.activity.title,
        location: combinedAddress.replaceAll('\n', ' - '),
        timeRange:
            '${timeText.substring(0, 5)} - ${_buildEndTimeFromText(timeText.substring(0, 5))}',
        imageGradient: widget.activity.imageGradient,
        serviceDate: _serviceDate,
        departureTime: timeText,
        serviceAddress: combinedAddress,
        quantity: widget.activity.quantity,
        bookedPrice: widget.activity.bookedPrice,
      ),
    );
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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

  static String _buildEndTimeFromText(String time) {
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final timeLabel =
        '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}';

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
                  child: Text(
                    widget.activity.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: TripUiColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SheetButton(
                    icon: Icons.calendar_month_rounded,
                    label: _dateLabel(_serviceDate),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SheetButton(
                    icon: Icons.access_time_rounded,
                    label: timeLabel,
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
                initialValue: _addressText,
                labelText: 'Địa chỉ',
                hintText: 'Nhập tên địa điểm để tìm trên bản đồ...',
                onAddressConfirmed: (addr) {
                  setState(() => _addressText = addr);
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
                  'Luu thay doi',
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

class _SheetButton extends StatelessWidget {
  const _SheetButton({
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
