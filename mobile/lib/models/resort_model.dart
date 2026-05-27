class ResortModel {
  final int id;
  final String name;
  final String address;
  final int starRating;
  final String description;
  final double avgRating;
  final int reviewCount;
  final double minPricePerNight;
  final String coverImageUrl;
  final List<String> imageUrls;
  final List<AmenityModel> amenities;
  final List<RoomModel> rooms;
  final List<ReviewModel> reviews;

  const ResortModel({
    required this.id,
    required this.name,
    required this.address,
    required this.starRating,
    required this.description,
    required this.avgRating,
    required this.reviewCount,
    required this.minPricePerNight,
    required this.coverImageUrl,
    required this.imageUrls,
    required this.amenities,
    required this.rooms,
    this.reviews = const [],
  });

  // Tên alias cho các widget cũ dùng `price`
  double get price => minPricePerNight;
  // Tên alias cho các widget cũ dùng `rating`
  double get rating => avgRating;
  int get reviewsCount => reviewCount;
  String get location => address;

  factory ResortModel.fromJson(Map<String, dynamic> json) {
    return ResortModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      starRating: json['starRating'] ?? 0,
      description: json['description'] ?? '',
      avgRating: (json['avgRating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      minPricePerNight: (json['minPricePerNight'] ?? 0.0).toDouble(),
      coverImageUrl: json['coverImageUrl'] ?? '',
      imageUrls: (json['imageUrls'] as List? ?? []).map((e) => e.toString()).toList(),
      amenities: (json['amenities'] as List? ?? [])
          .map((e) => AmenityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      rooms: (json['rooms'] as List? ?? [])
          .map((e) => RoomModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      reviews: (json['reviews'] as List? ?? [])
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AmenityModel {
  final String name;
  final String iconUrl;

  const AmenityModel({required this.name, required this.iconUrl});

  factory AmenityModel.fromJson(Map<String, dynamic> json) {
    return AmenityModel(
      name: json['name'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
    );
  }
}

class RoomModel {
  final int id;
  final String roomType;
  final int capacity;
  final double pricePerNight;
  final int availableQty;

  const RoomModel({
    required this.id,
    required this.roomType,
    required this.capacity,
    required this.pricePerNight,
    required this.availableQty,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] ?? 0,
      roomType: json['roomType'] ?? '',
      capacity: json['capacity'] ?? 0,
      pricePerNight: (json['pricePerNight'] ?? 0.0).toDouble(),
      availableQty: json['availableQty'] ?? 0,
    );
  }
}

class ReviewModel {
  final int id;
  final String userName;
  final String? userAvatar;
  final int rating;
  final String? comment;
  final String? createdAt;

  const ReviewModel({
    required this.id,
    required this.userName,
    this.userAvatar,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? 0,
      userName: json['userName'] ?? 'Khách',
      userAvatar: json['userAvatar'],
      rating: json['rating'] ?? 5,
      comment: json['comment'],
      createdAt: json['createdAt'],
    );
  }

  // Alias cũ cho widget
  String get content => comment ?? '';
  String get date => _formatDate(createdAt);

  static String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'HÔM NAY';
      if (diff.inDays == 1) return 'HÔM QUA';
      if (diff.inDays < 7) return '${diff.inDays} NGÀY TRƯỚC';
      if (diff.inDays < 30) return '${(diff.inDays / 7).round()} TUẦN TRƯỚC';
      return '${(diff.inDays / 30).round()} THÁNG TRƯỚC';
    } catch (_) {
      return '';
    }
  }
}

class HotelCalendarDay {
  final String date;
  final double price;
  final bool available;
  final int availableRooms;
  final bool isWeekend;
  final bool isHoliday;

  const HotelCalendarDay({
    required this.date,
    required this.price,
    required this.available,
    required this.availableRooms,
    required this.isWeekend,
    required this.isHoliday,
  });

  factory HotelCalendarDay.fromJson(Map<String, dynamic> json) {
    return HotelCalendarDay(
      date: json['date'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      available: json['available'] ?? true,
      availableRooms: json['availableRooms'] ?? 0,
      isWeekend: json['isWeekend'] ?? false,
      isHoliday: json['isHoliday'] ?? false,
    );
  }

  DateTime get dateTime => DateTime.parse(date);
  int get day => dateTime.day;
}
