import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../views/trip/trip_ui_constants.dart';
import 'trip_section_label.dart';

class CreateTripDateField extends StatelessWidget {
  const CreateTripDateField({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final text = date == null ? '-- / -- / ----' : DateFormat('dd / MM / yyyy').format(date!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TripSectionLabel(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              color: TripUiColors.softGrey,
              borderRadius: BorderRadius.circular(14),
              border: errorText == null
                  ? null
                  : Border.all(
                      color: const Color(0xFFD94C4C),
                    ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: TripUiColors.primaryGreen,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9DA4AA),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFD94C4C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
