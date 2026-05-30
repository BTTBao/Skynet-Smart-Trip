class CatalogHomeData {
  const CatalogHomeData({
    required this.popularDestinations,
    required this.featuredHotels,
    required this.recommendedHotels,
    required this.featuredBuses,
  });

  final List<CatalogDestination> popularDestinations;
  final List<CatalogHotelCard> featuredHotels;
  final List<CatalogHotelCard> recommendedHotels;
  final List<CatalogBusCard> featuredBuses;

  factory CatalogHomeData.fromJson(Map<String, dynamic> json) {
    return CatalogHomeData(
      popularDestinations: (json['popularDestinations'] as List<dynamic>? ?? [])
          .map(
            (item) => CatalogDestination.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      featuredHotels: (json['featuredHotels'] as List<dynamic>? ?? [])
          .map(
            (item) => CatalogHotelCard.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      recommendedHotels: (json['recommendedHotels'] as List<dynamic>? ?? [])
          .map(
            (item) => CatalogHotelCard.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      featuredBuses: (json['featuredBuses'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                CatalogBusCard.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
}

class CatalogDestination {
  const CatalogDestination({
    required this.id,
    required this.name,
    required this.description,
    required this.coverImageUrl,
    required this.isHot,
  });

  final int id;
  final String name;
  final String description;
  final String coverImageUrl;
  final bool isHot;

  factory CatalogDestination.fromJson(Map<String, dynamic> json) {
    return CatalogDestination(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      isHot: json['isHot'] as bool? ?? false,
    );
  }
}

class CatalogHotelSearchResult {
  const CatalogHotelSearchResult({required this.total, required this.items});

  final int total;
  final List<CatalogHotelCard> items;

  factory CatalogHotelSearchResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return CatalogHotelSearchResult(
      total: json['total'] as int? ?? rawItems.length,
      items: rawItems
          .map(
            (item) => CatalogHotelCard.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class CatalogHotelCard {
  const CatalogHotelCard({
    required this.id,
    required this.destinationId,
    required this.name,
    required this.destinationName,
    required this.address,
    required this.description,
    required this.starRating,
    required this.pricePerNight,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.isAvailable,
    this.tag,
  });

  final int id;
  final int destinationId;
  final String name;
  final String destinationName;
  final String address;
  final String description;
  final int starRating;
  final double pricePerNight;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final bool isAvailable;
  final String? tag;

  factory CatalogHotelCard.fromJson(Map<String, dynamic> json) {
    return CatalogHotelCard(
      id: json['id'] as int? ?? 0,
      destinationId: json['destinationId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      destinationName: json['destinationName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      description: json['description'] as String? ?? '',
      starRating: json['starRating'] as int? ?? 0,
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      isAvailable: json['isAvailable'] as bool? ?? false,
      tag: json['tag'] as String?,
    );
  }
}

class CatalogHotelDetail {
  const CatalogHotelDetail({
    required this.id,
    required this.destinationId,
    required this.name,
    required this.destinationName,
    required this.address,
    required this.description,
    required this.starRating,
    required this.pricePerNight,
    required this.rating,
    required this.reviewCount,
    required this.isAvailable,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.amenities,
    required this.rooms,
    required this.reviews,
  });

  final int id;
  final int destinationId;
  final String name;
  final String destinationName;
  final String address;
  final String description;
  final int starRating;
  final double pricePerNight;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final List<String> amenities;
  final List<CatalogRoomOption> rooms;
  final List<CatalogReview> reviews;

  factory CatalogHotelDetail.fromJson(Map<String, dynamic> json) {
    return CatalogHotelDetail(
      id: json['id'] as int? ?? 0,
      destinationId: json['destinationId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      destinationName: json['destinationName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      description: json['description'] as String? ?? '',
      starRating: json['starRating'] as int? ?? 0,
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      imageUrls: (json['imageUrls'] as List<dynamic>? ?? [])
          .map((item) => item as String? ?? '')
          .where((item) => item.isNotEmpty)
          .toList(),
      amenities: (json['amenities'] as List<dynamic>? ?? [])
          .map((item) => item as String? ?? '')
          .where((item) => item.isNotEmpty)
          .toList(),
      rooms: (json['rooms'] as List<dynamic>? ?? [])
          .map(
            (item) => CatalogRoomOption.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      reviews: (json['reviews'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                CatalogReview.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
}

class CatalogRoomOption {
  const CatalogRoomOption({
    required this.id,
    required this.roomType,
    required this.capacity,
    required this.pricePerNight,
    required this.availableQty,
  });

  final int id;
  final String roomType;
  final int capacity;
  final double pricePerNight;
  final int availableQty;

  factory CatalogRoomOption.fromJson(Map<String, dynamic> json) {
    return CatalogRoomOption(
      id: json['id'] as int? ?? 0,
      roomType: json['roomType'] as String? ?? 'Standard',
      capacity: json['capacity'] as int? ?? 0,
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble() ?? 0,
      availableQty: json['availableQty'] as int? ?? 0,
    );
  }
}

class CatalogRoomAvailability {
  const CatalogRoomAvailability({
    required this.roomId,
    required this.totalQty,
    required this.remainingQty,
    required this.isAvailable,
    required this.message,
  });

  final int roomId;
  final int totalQty;
  final int remainingQty;
  final bool isAvailable;
  final String message;

  factory CatalogRoomAvailability.fromJson(Map<String, dynamic> json) {
    return CatalogRoomAvailability(
      roomId: json['roomId'] as int? ?? 0,
      totalQty: json['totalQty'] as int? ?? 0,
      remainingQty: json['remainingQty'] as int? ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}

class CatalogBusSearchResult {
  const CatalogBusSearchResult({required this.total, required this.items});

  final int total;
  final List<CatalogBusCard> items;

  factory CatalogBusSearchResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return CatalogBusSearchResult(
      total: json['total'] as int? ?? rawItems.length,
      items: rawItems
          .map(
            (item) =>
                CatalogBusCard.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
}

class CatalogBusCard {
  const CatalogBusCard({
    required this.id,
    this.companyId,
    required this.companyName,
    required this.fromDestination,
    required this.toDestination,
    this.departureTime,
    this.arrivalTime,
    required this.price,
    required this.totalSeats,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
  });

  final int id;
  final int? companyId;
  final String companyName;
  final String fromDestination;
  final String toDestination;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final double price;
  final int totalSeats;
  final double rating;
  final int reviewCount;
  final String imageUrl;

  factory CatalogBusCard.fromJson(Map<String, dynamic> json) {
    return CatalogBusCard(
      id: json['id'] as int? ?? 0,
      companyId: json['companyId'] as int?,
      companyName: json['companyName'] as String? ?? '',
      fromDestination: json['fromDestination'] as String? ?? '',
      toDestination: json['toDestination'] as String? ?? '',
      departureTime: DateTime.tryParse(json['departureTime'] as String? ?? ''),
      arrivalTime: DateTime.tryParse(json['arrivalTime'] as String? ?? ''),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      totalSeats: json['totalSeats'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }
}

class CatalogBusDetail {
  const CatalogBusDetail({
    required this.id,
    this.companyId,
    required this.companyName,
    required this.hotline,
    required this.fromDestination,
    required this.toDestination,
    this.departureTime,
    this.arrivalTime,
    required this.price,
    required this.totalSeats,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.reviews,
  });

  final int id;
  final int? companyId;
  final String companyName;
  final String hotline;
  final String fromDestination;
  final String toDestination;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final double price;
  final int totalSeats;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final List<CatalogReview> reviews;

  factory CatalogBusDetail.fromJson(Map<String, dynamic> json) {
    return CatalogBusDetail(
      id: json['id'] as int? ?? 0,
      companyId: json['companyId'] as int?,
      companyName: json['companyName'] as String? ?? '',
      hotline: json['hotline'] as String? ?? '',
      fromDestination: json['fromDestination'] as String? ?? '',
      toDestination: json['toDestination'] as String? ?? '',
      departureTime: DateTime.tryParse(json['departureTime'] as String? ?? ''),
      arrivalTime: DateTime.tryParse(json['arrivalTime'] as String? ?? ''),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      totalSeats: json['totalSeats'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      reviews: (json['reviews'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                CatalogReview.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
}

class CatalogReview {
  const CatalogReview({
    required this.userName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  final String userName;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  factory CatalogReview.fromJson(Map<String, dynamic> json) {
    return CatalogReview(
      userName: json['userName'] as String? ?? 'Khach hang',
      rating: json['rating'] as int? ?? 5,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
