import 'package:flutter/material.dart';
import '../../models/resort_model.dart';

class ResortReviews extends StatelessWidget {
  final List<ReviewModel> reviews;

  const ResortReviews({Key? key, required this.reviews}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đánh giá',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Xem tất cả',
                style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...reviews.map((review) => _buildReviewItem(review)).toList(),
        ],
      ),
    );
  }

  Widget _buildReviewItem(ReviewModel review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(review.userAvatar),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(review.date, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    color: index < review.rating ? Colors.orange : Colors.grey[300],
                    size: 16,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(review.content, style: TextStyle(color: Colors.grey[800])),
        ],
      ),
    );
  }
}
