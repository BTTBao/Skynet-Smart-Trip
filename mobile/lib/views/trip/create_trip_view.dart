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
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const CreateTripView({
    super.key,
    this.editTripId,
    this.initialTitle,
    this.initialDestination,
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
    // Only validate past date for NEW trips
    if (!_isEditMode && _startDate!.isBefore(_today)) {
      return 'Ngay di khong duoc o qua khu';
    }
    return null;
  }

  String? get _endDateValidation {
    if (_endDate == null) {
      return 'Chon ngay ve';
    }
    if (!_isEditMode && _endDate!.isBefore(_today)) {
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
    final initialDate = isStartDate
        ? _startDate ?? today
        : _endDate ?? _startDate ?? today;
    final firstDate = _isEditMode
        ? DateTime(2000)
        : (isStartDate ? today : (_startDate ?? today));
    final lastDate = isStartDate
        ? DateTime(today.year + 5, today.month, today.day)
        : (_startDate?.add(const Duration(days: 30)) ??
              DateTime(today.year + 5, today.month, today.day));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
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

  Future<void> _handleSave() async {
    if (!_isFormValid || _startDate == null || _endDate == null) {
      return;
    }

    final tripProvider = context.read<TripProvider>();

    if (_isEditMode) {
      final success = await tripProvider.updateTrip(
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

      if (success) {
        Navigator.of(context).maybePop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Da cap nhat chuyen di.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tripProvider.error ?? 'Cap nhat that bai.')),
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
          child: Text(
            destination.name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: isLoading ? null : onChanged,
      decoration: InputDecoration(
        hintText: isLoading ? 'Dang tai diem den...' : 'Chon diem den...',
        errorText: errorText,
        hintStyle: const TextStyle(
          color: Color(0xFFA0A7AF),
          fontSize: 13,
        ),
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
