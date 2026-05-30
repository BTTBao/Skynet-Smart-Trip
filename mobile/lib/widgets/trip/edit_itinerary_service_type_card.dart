import 'package:flutter/material.dart';

import '../../models/edit_itinerary_service_type.dart';
import '../../views/trip/trip_ui_constants.dart';

class EditItineraryServiceTypeCard extends StatelessWidget {
  const EditItineraryServiceTypeCard({
    super.key,
    required this.serviceType,
    required this.onTap,
  });

  final EditItineraryServiceType serviceType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          decoration: BoxDecoration(
            color: serviceType.backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF76D8A2),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  serviceType.icon,
                  color: serviceType.iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                serviceType.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TripUiColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
