import 'package:flutter/material.dart';

import '../../models/trip_timeline_entry.dart';
import '../../views/trip/trip_ui_constants.dart';

class AddTripServiceSheet extends StatefulWidget {
  const AddTripServiceSheet({super.key});

  @override
  State<AddTripServiceSheet> createState() => _AddTripServiceSheetState();
}

class _AddTripServiceSheetState extends State<AddTripServiceSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  _TripServiceOption _selectedOption = _tripServiceOptions.first;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: TripUiColors.timelineGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final entry = TripTimelineEntry(
      time: _formatTime(_selectedTime),
      sectionTitle: _selectedOption.sectionTitle,
      caption: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      icon: _selectedOption.icon,
      badge: _selectedOption.badge,
      badgeColor: _selectedOption.badgeColor,
      badgeTextColor: _selectedOption.badgeTextColor,
    );

    Navigator.of(context).pop(entry);
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
              const Text(
                'Thêm dịch vụ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: TripUiColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tạo nhanh một mục trong lịch trình cho ngày đang chọn.',
                style: TextStyle(
                  fontSize: 13,
                  color: TripUiColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              const _SheetLabel('Loại dịch vụ'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tripServiceOptions.map((option) {
                  final isSelected = option == _selectedOption;
                  return ChoiceChip(
                    label: Text(option.label),
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
                    onSelected: (_) {
                      setState(() {
                        _selectedOption = option;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const _SheetLabel('Thời gian'),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: TripUiColors.timelineGreen,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatTime(_selectedTime),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: TripUiColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _SheetLabel('Tên dịch vụ'),
              const SizedBox(height: 10),
              _SheetTextField(
                controller: _titleController,
                hintText: 'Ví dụ: Bay đến Đà Nẵng',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập tên dịch vụ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const _SheetLabel('Mô tả'),
              const SizedBox(height: 10),
              _SheetTextField(
                controller: _descriptionController,
                hintText: 'Thêm địa điểm, ghi chú hoặc thông tin cần nhớ...',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập mô tả';
                  }
                  return null;
                },
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
                    'Thêm vào lịch trình',
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?) validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
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

class _TripServiceOption {
  const _TripServiceOption({
    required this.label,
    required this.sectionTitle,
    required this.icon,
    this.badge,
    this.badgeColor,
    this.badgeTextColor,
  });

  final String label;
  final String sectionTitle;
  final IconData icon;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeTextColor;
}

const _tripServiceOptions = [
  _TripServiceOption(
    label: 'Di chuyển',
    sectionTitle: 'Di chuyển',
    icon: Icons.directions_car_filled_rounded,
    badge: 'TRANSPORT',
    badgeColor: Color(0xFFE4FFF0),
    badgeTextColor: TripUiColors.timelineGreen,
  ),
  _TripServiceOption(
    label: 'Lưu trú',
    sectionTitle: 'Lưu trú',
    icon: Icons.hotel_rounded,
    badge: 'HOTEL',
    badgeColor: Color(0xFFEAF4FF),
    badgeTextColor: Color(0xFF2A6FD6),
  ),
  _TripServiceOption(
    label: 'Ăn uống',
    sectionTitle: 'Ăn uống',
    icon: Icons.restaurant_rounded,
    badge: 'FOOD',
    badgeColor: Color(0xFFFFF1E5),
    badgeTextColor: Color(0xFFE57A00),
  ),
  _TripServiceOption(
    label: 'Tham quan',
    sectionTitle: 'Tham quan',
    icon: Icons.place_rounded,
    badge: 'PLACE',
    badgeColor: Color(0xFFF0ECFF),
    badgeTextColor: Color(0xFF6C4FD3),
  ),
];
