import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/create_trip_itinerary_request.dart';
import '../../models/trip_service_option.dart';
import '../../providers/trip_provider.dart';
import '../../views/trip/trip_ui_constants.dart';

class AddTripServiceSheet extends StatefulWidget {
  const AddTripServiceSheet({
    super.key,
    required this.dayNumber,
    required this.initialServiceDate,
    this.destinationId,
    this.tripStartDate,
    this.tripEndDate,
  });

  final int dayNumber;
  final DateTime initialServiceDate;
  final int? destinationId;
  final DateTime? tripStartDate;
  final DateTime? tripEndDate;

  @override
  State<AddTripServiceSheet> createState() => _AddTripServiceSheetState();
}

class _AddTripServiceSheetState extends State<AddTripServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedServiceType = 'BUS';
  TripServiceOption? _selectedOption;
  late Future<List<TripServiceOption>> _optionsFuture;
  late DateTime _selectedServiceDate;
  TimeOfDay? _selectedDepartureTime;

  @override
  void initState() {
    super.initState();
    _selectedServiceDate = DateTime(
      widget.initialServiceDate.year,
      widget.initialServiceDate.month,
      widget.initialServiceDate.day,
    );
    _optionsFuture = _loadOptions();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<List<TripServiceOption>> _loadOptions() {
    return context.read<TripProvider>().getServiceOptions(
          serviceType: _selectedServiceType,
          destinationId: widget.destinationId,
        );
  }

  void _onServiceTypeChanged(String serviceType) {
    setState(() {
      _selectedServiceType = serviceType;
      _selectedOption = null;
      _priceController.clear();
      _optionsFuture = _loadOptions();
    });
  }

  Future<void> _pickServiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedServiceDate,
      firstDate: widget.tripStartDate ?? DateTime(2020, 1, 1),
      lastDate: widget.tripEndDate ?? DateTime(2100, 12, 31),
      helpText: 'Chon ngay di',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedServiceDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickDepartureTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedDepartureTime ?? TimeOfDay.now(),
      helpText: 'Chon gio khoi hanh',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDepartureTime = picked;
    });
  }

  int _resolveDayNumber() {
    final startDate = widget.tripStartDate;
    if (startDate == null) {
      return widget.dayNumber;
    }

    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final dayOffset = _selectedServiceDate.difference(normalizedStart).inDays;
    return dayOffset + 1;
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _selectedOption == null) {
      return;
    }

    if (_selectedDepartureTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui long chon gio khoi hanh.')),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
    final price = double.tryParse(
      _priceController.text.trim().replaceAll(',', ''),
    );
    final departure = _selectedDepartureTime!;
    final departureText =
        '${departure.hour.toString().padLeft(2, '0')}:${departure.minute.toString().padLeft(2, '0')}:00';

    Navigator.of(context).pop(
      CreateTripItineraryRequest(
        dayNumber: _resolveDayNumber(),
        serviceType: _selectedOption!.serviceType,
        serviceId: _selectedOption!.serviceId,
        quantity: quantity,
        bookedPrice: price,
        bookedCommissionRate: _selectedOption!.defaultCommissionRate,
        serviceDate: _selectedServiceDate,
        departureTime: departureText,
        serviceAddress: _addressController.text.trim(),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _timeLabel(TimeOfDay? time) {
    if (time == null) {
      return 'Chon gio khoi hanh';
    }
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
                'Them dich vu cho ngay ${widget.dayNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: TripUiColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bo sung ngay, gio va dia chi de toi uu hien thi lo trinh tren ban do.',
                style: TextStyle(
                  fontSize: 13,
                  color: TripUiColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              const _SheetLabel('Loai dich vu'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTypeChip(label: 'Di chuyen', value: 'BUS'),
                  _buildTypeChip(label: 'Luu tru', value: 'HOTEL'),
                ],
              ),
              const SizedBox(height: 16),
              const _SheetLabel('Danh sach dich vu'),
              const SizedBox(height: 10),
              FutureBuilder<List<TripServiceOption>>(
                future: _optionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return const _SheetNotice(
                      text:
                          'Khong tai duoc danh sach dich vu. Thu dong lai sheet de thu lai.',
                    );
                  }

                  final options = snapshot.data ?? const <TripServiceOption>[];
                  if (options.isEmpty) {
                    return const _SheetNotice(
                      text: 'Khong co dich vu phu hop cho diem den nay.',
                    );
                  }

                  return DropdownButtonFormField<TripServiceOption>(
                    value: _selectedOption,
                    items: options.map((option) {
                      return DropdownMenuItem<TripServiceOption>(
                        value: option,
                        child: Text(option.title),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedOption = value;
                        _priceController.text =
                            value?.defaultPrice?.toStringAsFixed(0) ?? '';
                      });
                    },
                    validator: (value) => value == null ? 'Chon mot dich vu' : null,
                    decoration: InputDecoration(
                      hintText: 'Chon dich vu',
                      filled: true,
                      fillColor: const Color(0xFFF1F4F6),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  );
                },
              ),
              if (_selectedOption != null) ...[
                const SizedBox(height: 12),
                _SheetNotice(
                  text: _selectedOption!.subtitle ?? 'Khong co mo ta them.',
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SheetLabel('Ngay di'),
                        const SizedBox(height: 10),
                        _SelectFieldButton(
                          icon: Icons.calendar_month_rounded,
                          label: _dateLabel(_selectedServiceDate),
                          onTap: _pickServiceDate,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SheetLabel('Gio khoi hanh'),
                        const SizedBox(height: 10),
                        _SelectFieldButton(
                          icon: Icons.access_time_rounded,
                          label: _timeLabel(_selectedDepartureTime),
                          onTap: _pickDepartureTime,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _SheetLabel('Dia chi dich vu (khong bat buoc)'),
              const SizedBox(height: 8),
              const Text(
                'Nen nhap de su dung tinh nang map va ve lo trinh chinh xac hon.',
                style: TextStyle(
                  fontSize: 12,
                  color: TripUiColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _SheetTextField(
                controller: _addressController,
                hintText: 'Vi du: 45 Le Loi, Quan 1, TP.HCM',
                validator: (_) => null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SheetLabel('So luong'),
                        const SizedBox(height: 10),
                        _SheetTextField(
                          controller: _quantityController,
                          hintText: '1',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final quantity = int.tryParse((value ?? '').trim());
                            if (quantity == null || quantity <= 0) {
                              return 'Nhap so hop le';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SheetLabel('Gia dat'),
                        const SizedBox(height: 10),
                        _SheetTextField(
                          controller: _priceController,
                          hintText: 'Nhap gia',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Nhap gia';
                            }
                            final parsed =
                                double.tryParse(value!.trim().replaceAll(',', ''));
                            if (parsed == null || parsed < 0) {
                              return 'Gia khong hop le';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TripUiColors.timelineGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Them vao lich trinh',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
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

  Widget _buildTypeChip({
    required String label,
    required String value,
  }) {
    final isSelected = _selectedServiceType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : TripUiColors.textPrimary,
      ),
      backgroundColor: const Color(0xFFF1F4F6),
      selectedColor: TripUiColors.timelineGreen,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      onSelected: (_) => _onServiceTypeChanged(value),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: TripUiColors.textPrimary,
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.controller,
    required this.hintText,
    required this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF1F4F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SheetNotice extends StatelessWidget {
  const _SheetNotice({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: TripUiColors.textSecondary,
        ),
      ),
    );
  }
}

class _SelectFieldButton extends StatelessWidget {
  const _SelectFieldButton({
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
        width: double.infinity,
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
