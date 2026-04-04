import 'package:flutter/material.dart';

class ResortInfoSection extends StatelessWidget {
  final String name;
  final double rating;
  final int reviewsCount;
  final String location;

  const ResortInfoSection({
    Key? key,
    required this.name,
    required this.rating,
    required this.reviewsCount,
    required this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.orange, size: 20),
              const SizedBox(width: 4),
              Text(
                 rating.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              const SizedBox(width: 8),
              Text(
                '·  $reviewsCount đánh giá',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.grey, size: 20),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
