import 'package:flutter/material.dart';

import '../../models/edit_itinerary_favorite.dart';
import '../../views/trip/trip_ui_constants.dart';

class EditItineraryFavoriteCard extends StatelessWidget {
  const EditItineraryFavoriteCard({
    super.key,
    required this.favorite,
  });

  final EditItineraryFavorite favorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 74,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: favorite.imageGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white70,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            favorite.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: TripUiColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            favorite.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: TripUiColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
