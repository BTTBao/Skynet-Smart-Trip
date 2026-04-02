import 'package:flutter/material.dart';

import '../../views/trip/trip_ui_constants.dart';

class CreateTripEditableInput extends StatelessWidget {
  const CreateTripEditableInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.errorText,
    this.leadingIcon,
    this.trailingIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        hintStyle: const TextStyle(
          color: Color(0xFFA0A7AF),
          fontSize: 13,
        ),
        prefixIcon: leadingIcon == null
            ? null
            : Icon(
                leadingIcon,
                color: TripUiColors.primaryGreen,
              ),
        suffixIcon: trailingIcon == null
            ? null
            : Icon(
                trailingIcon,
                color: const Color(0xFF97A0A8),
                size: 18,
              ),
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
