class ResortModel {
  final String id;
  final String name;
  final double rating;
  final int reviewsCount;
  final String location;
  final String description;
  final double price;
  final List<String> imageUrls;

  const ResortModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviewsCount,
    required this.location,
    required this.description,
    required this.price,
    required this.imageUrls,
  });
}

class ReviewModel {
  final String id;
  final String userName;
  final String userAvatar;
  final String date;
  final String content;
  final int rating;

  const ReviewModel({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.date,
    required this.content,
    required this.rating,
  });
}
