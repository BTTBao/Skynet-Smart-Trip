import 'package:flutter/material.dart';

import 'trip_ui_constants.dart';
import 'trip_itinerary_detail_view.dart';
import '../../widgets/trip/widgets.dart';

class CreateTripView extends StatefulWidget {
  const CreateTripView({super.key});

  @override
  State<CreateTripView> createState() => _CreateTripViewState();
}

class _CreateTripViewState extends State<CreateTripView> {
  final _tripNameController = TextEditingController();
  final _destinationController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _tripNameTouched = false;
  bool _destinationTouched = false;
  bool _startDateTouched = false;
  bool _endDateTouched = false;

  @override
  void dispose() {
    _tripNameController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String? get _tripNameValidation {
    if (_tripNameController.text.trim().isEmpty) {
      return 'Nhập tên chuyến đi';
    }
    return null;
  }

  String? get _destinationValidation {
    if (_destinationController.text.trim().isEmpty) {
      return 'Nhập địa điểm';
    }
    return null;
  }

  String? get _startDateValidation {
    if (_startDate == null) {
      return 'Chọn ngày đi';
    }
    if (_startDate!.isBefore(_today)) {
      return 'Ngày đi không được ở quá khứ';
    }
    return null;
  }

  String? get _endDateValidation {
    if (_endDate == null) {
      return 'Chọn ngày về';
    }
    if (_endDate!.isBefore(_today)) {
      return 'Ngày về không được ở quá khứ';
    }
    if (_startDate == null) {
      return 'Chọn ngày đi trước';
    }
    if (_endDate!.isBefore(_startDate!)) {
      return 'Ngày về không được nhỏ hơn ngày đi';
    }
    if (_endDate!.difference(_startDate!).inDays > 30) {
      return 'Ngày về không được lớn hơn ngày đi quá 30 ngày';
    }
    return null;
  }

  String? get _tripNameError => _tripNameTouched ? _tripNameValidation : null;

  String? get _destinationError => _destinationTouched ? _destinationValidation : null;

  String? get _startDateError => _startDateTouched ? _startDateValidation : null;

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
    final firstDate = isStartDate ? today : (_startDate ?? today);
    final lastDate = isStartDate
        ? DateTime(today.year + 5, today.month, today.day)
        : (_startDate?.add(const Duration(days: 30)) ??
            DateTime(today.year + 5, today.month, today.day));

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

  void _openTripDetail() {
    if (!_isFormValid || _startDate == null || _endDate == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripItineraryDetailView(
          tripTitle: _tripNameController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          travelerInitial: _tripNameController.text.trim()[0].toUpperCase(),
        ),
      ),
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
                title: 'Tạo chuyến đi mới',
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 16),
              const CreateTripHeroCard(),
              const SizedBox(height: 16),
              const TripSectionLabel('Tên chuyến đi'),
              const SizedBox(height: 8),
              CreateTripEditableInput(
                controller: _tripNameController,
                hintText: 'Nhập tên chuyến đi của bạn...',
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
                      label: 'Ngày đi',
                      date: _startDate,
                      onTap: () => _pickDate(isStartDate: true),
                      errorText: _startDateError,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CreateTripDateField(
                      label: 'Ngày về',
                      date: _endDate,
                      onTap: () => _pickDate(isStartDate: false),
                      errorText: _endDateError,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const TripSectionLabel('Điểm đến'),
              const SizedBox(height: 8),
              CreateTripEditableInput(
                controller: _destinationController,
                hintText: 'Nhập địa điểm...',
                onChanged: (_) {
                  setState(() {
                    _destinationTouched = true;
                  });
                },
                errorText: _destinationError,
                leadingIcon: Icons.place_outlined,
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Expanded(
                    child: TripOptionCard(
                      icon: Icons.group_outlined,
                      title: 'Bạn đồng hành',
                      subtitle: 'Thêm người đi cùng',
                      iconBackground: Color(0xFFE7FFF0),
                      iconColor: TripUiColors.primaryGreen,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TripOptionCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Ngân sách',
                      subtitle: 'Thiết lập chi tiêu',
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
                  onPressed: _isFormValid ? _openTripDetail : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid
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
                  icon: const Text(
                    'Tạo chuyến đi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  label: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
