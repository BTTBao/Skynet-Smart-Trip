import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/create_trip_request.dart';
import '../../models/destination.dart';
import '../../models/update_trip_request.dart';
import '../../providers/destination_provider.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/trip/widgets.dart';
import 'trip_itinerary_detail_view.dart';
import 'trip_ui_constants.dart';

class CreateTripView extends StatefulWidget {
  final int? editTripId;
  final String? initialTitle;
  final String? initialDestination;
  final int? initialDestinationId;
  final String? initialShareCode;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const CreateTripView({
    super.key,
    this.editTripId,
    this.initialTitle,
    this.initialDestination,
    this.initialDestinationId,
    this.initialShareCode,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<CreateTripView> createState() => _CreateTripViewState();
}

class _CreateTripViewState extends State<CreateTripView> {
  late final TextEditingController _tripNameController;
  late final TextEditingController _destinationController;

  DateTime? _startDate;
  DateTime? _endDate;
  Destination? _selectedDestination;
  int? _originalDestinationId;
  bool _tripNameTouched = false;
  bool _destinationTouched = false;
  bool _startDateTouched = false;
  bool _endDateTouched = false;

  @override
  void initState() {
    super.initState();
    _tripNameController = TextEditingController(text: widget.initialTitle);
    _destinationController = TextEditingController(
      text: widget.initialDestination,
    );
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _originalDestinationId = widget.initialDestinationId;
    if (widget.editTripId != null) {
      _tripNameTouched = true;
      _destinationTouched = true;
      _startDateTouched = true;
      _endDateTouched = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDestinations());
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.editTripId != null;

  Future<void> _loadDestinations() async {
    final provider = context.read<DestinationProvider>();
    await provider.fetchDestinations();
    if (!mounted || _selectedDestination != null) {
      return;
    }

    final initialId = widget.initialDestinationId;
    if (initialId != null) {
      for (final destination in provider.destinations) {
        if (destination.id == initialId) {
          setState(() {
            _selectedDestination = destination;
            _destinationController.text = destination.name;
          });
          return;
        }
      }
    }

    final initialName = widget.initialDestination?.trim().toLowerCase();
    if (initialName == null || initialName.isEmpty) {
      return;
    }

    for (final destination in provider.destinations) {
      if (destination.name.trim().toLowerCase() == initialName) {
        setState(() {
          _selectedDestination = destination;
          _destinationController.text = destination.name;
        });
        break;
      }
    }
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _laterDate(DateTime first, DateTime second) {
    return first.isBefore(second) ? second : first;
  }

  String? get _tripNameValidation {
    if (_tripNameController.text.trim().isEmpty) {
      return 'Nhap ten chuyen di';
    }
    return null;
  }

  String? get _destinationValidation {
    if (_selectedDestination == null) {
      return 'Chon diem den';
    }
    return null;
  }

  String? get _startDateValidation {
    if (_startDate == null) {
      return 'Chon ngay di';
    }
    if (_startDate!.isBefore(_today)) {
      return 'Ngay di khong duoc o qua khu';
    }
    return null;
  }

  String? get _endDateValidation {
    if (_endDate == null) {
      return 'Chon ngay ve';
    }
    if (_endDate!.isBefore(_today)) {
      return 'Ngay ve khong duoc o qua khu';
    }
    if (_startDate == null) {
      return 'Chon ngay di truoc';
    }
    if (_endDate!.isBefore(_startDate!)) {
      return 'Ngay ve khong duoc nho hon ngay di';
    }
    if (_endDate!.difference(_startDate!).inDays > 30) {
      return 'Ngay ve khong duoc lon hon ngay di qua 30 ngay';
    }
    return null;
  }

  String? get _tripNameError => _tripNameTouched ? _tripNameValidation : null;
  String? get _destinationError =>
      _destinationTouched ? _destinationValidation : null;
  String? get _startDateError =>
      _startDateTouched ? _startDateValidation : null;
  String? get _endDateError => _endDateTouched ? _endDateValidation : null;

  bool get _isFormValid {
    return _tripNameValidation == null &&
        _destinationValidation == null &&
        _startDateValidation == null &&
        _endDateValidation == null;
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final today = _today;
    final preferredInitialDate = isStartDate
        ? _startDate ?? today
        : _endDate ?? _startDate ?? today;
    final firstDate = isStartDate
        ? today
        : _laterDate(_startDate ?? today, today);
    final allowedLastDate = isStartDate
        ? DateTime(today.year + 5, today.month, today.day)
        : (_startDate?.add(const Duration(days: 30)) ??
              DateTime(today.year + 5, today.month, today.day));
    final lastDate = allowedLastDate.isBefore(firstDate)
        ? firstDate
        : allowedLastDate;
    final initialDate = preferredInitialDate.isBefore(firstDate)
        ? firstDate
        : (preferredInitialDate.isAfter(lastDate)
              ? lastDate
              : preferredInitialDate);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: TripUiColors.primaryGreen,
              secondary: TripUiColors.accentGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      if (isStartDate) {
        _startDateTouched = true;
        _startDate = pickedDate;
        if (_endDate != null &&
            (_endDate!.isBefore(pickedDate) ||
                _endDate!.difference(pickedDate).inDays > 30)) {
          _endDate = null;
          _endDateTouched = true;
        }
      } else {
        _endDateTouched = true;
        _endDate = pickedDate;
      }
    });
  }

  bool get _destinationChangedInEdit {
    if (!_isEditMode || _selectedDestination == null) {
      return false;
    }
    return _selectedDestination!.id != _originalDestinationId;
  }

  Future<void> _handleSave() async {
    if (!_isFormValid || _startDate == null || _endDate == null) {
      return;
    }

    if (_isEditMode && _destinationChangedInEdit) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Đổi điểm đến?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Điểm đến mới khác điểm đến cũ. Toàn bộ lịch trình hiện tại sẽ bị xóa vì các địa điểm trên bản đồ gắn với khu vực du lịch trước đó.',
            style: TextStyle(height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: TripUiColors.timelineGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đồng ý'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
    }

    final tripProvider = context.read<TripProvider>();

    if (_isEditMode) {
      final updated = await tripProvider.updateTrip(
        widget.editTripId!,
        UpdateTripRequest(
          title: _tripNameController.text.trim(),
          destinationId: _selectedDestination!.id,
          destinationName: _selectedDestination!.name,
          startDate: _startDate!,
          endDate: _endDate!,
        ),
      );

      if (!mounted) return;

      if (updated != null) {
        Navigator.of(context).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updated.itinerariesCleared
                  ? 'Đã cập nhật chuyến đi. Lịch trình cũ đã được xóa do đổi điểm đến.'
                  : 'Đã cập nhật chuyến đi.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tripProvider.error ?? 'Cập nhật thất bại.')),
        );
      }
      return;
    }

    final createdTrip = await tripProvider.createTrip(
      CreateTripRequest(
        userId: 0,
        title: _tripNameController.text.trim(),
        destinationId: _selectedDestination!.id,
        destinationName: _selectedDestination!.name,
        startDate: _startDate!,
        endDate: _endDate!,
        status: 'DRAFT',
      ),
    );

    if (!mounted) {
      return;
    }

    if (createdTrip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tripProvider.error ?? 'Khong tao duoc chuyen di.'),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TripItineraryDetailView(
          tripId: createdTrip.tripId,
          tripTitle: createdTrip.title,
          startDate: createdTrip.startDate,
          endDate: createdTrip.endDate,
          travelerInitial: createdTrip.title.isEmpty
              ? 'T'
              : createdTrip.title[0].toUpperCase(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<TripProvider>().isSubmitting;
    final destinationProvider = context.watch<DestinationProvider>();

    return Scaffold(
      backgroundColor: TripUiColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TripScreenHeader(
                title: _isEditMode
                    ? 'Chinh sua chuyen di'
                    : 'Tao chuyen di moi',
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 16),
              const CreateTripHeroCard(),
              const SizedBox(height: 16),
              const TripSectionLabel('Ten chuyen di'),
              const SizedBox(height: 8),
              CreateTripEditableInput(
                controller: _tripNameController,
                hintText: 'Nhap ten chuyen di cua ban...',
                onChanged: (_) {
                  setState(() {
                    _tripNameTouched = true;
                  });
                },
                errorText: _tripNameError,
                trailingIcon: Icons.edit_outlined,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CreateTripDateField(
                      label: 'Ngay di',
                      date: _startDate,
                      onTap: () => _pickDate(isStartDate: true),
                      errorText: _startDateError,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CreateTripDateField(
                      label: 'Ngay ve',
                      date: _endDate,
                      onTap: () => _pickDate(isStartDate: false),
                      errorText: _endDateError,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const TripSectionLabel('Diem den'),
              const SizedBox(height: 8),
              _DestinationDropdownField(
                destinations: destinationProvider.destinations,
                selectedDestination: _selectedDestination,
                isLoading: destinationProvider.isLoading,
                errorText: _destinationError ?? destinationProvider.error,
                onChanged: (destination) {
                  setState(() {
                    _destinationTouched = true;
                    _selectedDestination = destination;
                    _destinationController.text = destination?.name ?? '';
                  });
                },
              ),
              if (_isEditMode && _destinationChangedInEdit) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: const Text(
                    'Đổi điểm đến sẽ xóa toàn bộ lịch trình hiện tại.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFF6D4C00),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (_isEditMode &&
                  widget.initialShareCode != null &&
                  widget.initialShareCode!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const TripSectionLabel('Mã chuyến đi'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.initialShareCode!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: TripUiColors.timelineGreen,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const Row(
                children: [
                  Expanded(
                    child: TripOptionCard(
                      icon: Icons.group_outlined,
                      title: 'Ban dong hanh',
                      subtitle: 'Them nguoi di cung',
                      iconBackground: Color(0xFFE7FFF0),
                      iconColor: TripUiColors.primaryGreen,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TripOptionCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Ngan sach',
                      subtitle: 'Thiet lap chi tieu',
                      iconBackground: Color(0xFFE8FBFF),
                      iconColor: Color(0xFF35B4CF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isFormValid && !isSubmitting ? _handleSave : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid && !isSubmitting
                        ? TripUiColors.primaryGreen
                        : const Color(0xFFBFC7CE),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFBFC7CE),
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditMode ? 'Luu thay doi' : 'Tao chuyen di',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  label: Icon(
                    isSubmitting
                        ? Icons.hourglass_top_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationDropdownField extends StatelessWidget {
  const _DestinationDropdownField({
    required this.destinations,
    required this.selectedDestination,
    required this.isLoading,
    required this.onChanged,
    this.errorText,
  });

  final List<Destination> destinations;
  final Destination? selectedDestination;
  final bool isLoading;
  final String? errorText;
  final ValueChanged<Destination?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Destination>(
      value: selectedDestination,
      isExpanded: true,
      items: destinations.map((destination) {
        return DropdownMenuItem<Destination>(
          value: destination,
          child: Text(destination.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: isLoading ? null : onChanged,
      decoration: InputDecoration(
        hintText: isLoading ? 'Dang tai diem den...' : 'Chon diem den...',
        errorText: errorText,
        hintStyle: const TextStyle(color: Color(0xFFA0A7AF), fontSize: 13),
        prefixIcon: const Icon(
          Icons.place_outlined,
          color: TripUiColors.primaryGreen,
        ),
        suffixIcon: isLoading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
        filled: true,
        fillColor: TripUiColors.softGrey,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
