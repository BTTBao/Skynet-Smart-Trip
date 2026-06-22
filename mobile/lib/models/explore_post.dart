class ExplorePost {
  final int id;
  final String title;
  final String excerpt;
  final String content;
  final String thumbnailUrl;
  final List<String> imageUrls;
  final String location; // Tên tỉnh/thành phố hiển thị (e.g. "Hà Nội")
  final String city; // City slug dùng để filter (e.g. "ha-noi")
  final String region; // 'north' | 'south' | 'central'
  final double? latitude;
  final double? longitude;
  final String authorName;
  final String authorAvatar;
  final DateTime publishedAt;
  final int likes;
  final int views;
  final double rating; // 0.0 – 5.0
  final int priceLevel; // 1=Rẻ, 2=Trung bình, 3=Cao, 4=Sang trọng
  final bool isLiked;
  final bool isBookmarked;
  final List<ExploreComment> comments;
  final List<String> tags;
  final String? linkedTripCode;

  const ExplorePost({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.thumbnailUrl,
    required this.imageUrls,
    required this.location,
    required this.city,
    required this.region,
    this.latitude,
    this.longitude,
    required this.authorName,
    required this.authorAvatar,
    required this.publishedAt,
    required this.likes,
    required this.views,
    required this.rating,
    required this.priceLevel,
    required this.isLiked,
    required this.isBookmarked,
    required this.comments,
    required this.tags,
    this.linkedTripCode,
  });

  factory ExplorePost.fromJson(Map<String, dynamic> json) {
    return ExplorePost(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      content: json['content'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      imageUrls: (json['imageUrls'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      location:
          json['location'] as String? ?? json['province'] as String? ?? '',
      city: json['city'] as String? ?? json['citySlug'] as String? ?? '',
      region: json['region'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      authorName: json['authorName'] as String? ?? '',
      authorAvatar: json['authorAvatar'] as String? ?? '',
      publishedAt:
          DateTime.tryParse(json['publishedAt']?.toString() ?? '') ??
          DateTime.now(),
      likes: json['likes'] as int? ?? json['likeCount'] as int? ?? 0,
      views: json['views'] as int? ?? json['viewCount'] as int? ?? 0,
      rating:
          (json['rating'] as num?)?.toDouble() ??
          (json['averageRating'] as num?)?.toDouble() ??
          0,
      priceLevel: json['priceLevel'] as int? ?? json['costLevel'] as int? ?? 2,
      isLiked: json['isLiked'] as bool? ?? false,
      isBookmarked:
          json['isBookmarked'] as bool? ?? json['isSaved'] as bool? ?? false,
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map(
            (item) => ExploreComment.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      linkedTripCode: json['linkedTripCode'] as String?,
    );
  }

  ExplorePost copyWith({
    bool? isLiked,
    bool? isBookmarked,
    int? likes,
    int? views,
    List<ExploreComment>? comments,
  }) {
    return ExplorePost(
      id: id,
      title: title,
      excerpt: excerpt,
      content: content,
      thumbnailUrl: thumbnailUrl,
      imageUrls: imageUrls,
      location: location,
      city: city,
      region: region,
      latitude: latitude,
      longitude: longitude,
      authorName: authorName,
      authorAvatar: authorAvatar,
      publishedAt: publishedAt,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      rating: rating,
      priceLevel: priceLevel,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      comments: comments ?? this.comments,
      tags: tags,
      linkedTripCode: linkedTripCode,
    );
  }
}

class ExploreComment {
  final int id;
  final int? parentCommentId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final int likes;
  final List<ExploreComment> replies;

  const ExploreComment({
    required this.id,
    this.parentCommentId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.likes,
    this.replies = const [],
  });

  factory ExploreComment.fromJson(Map<String, dynamic> json) {
    return ExploreComment(
      id: json['id'] as int? ?? 0,
      parentCommentId: json['parentCommentId'] as int?,
      authorName: json['authorName'] as String? ?? '',
      authorAvatar: json['authorAvatar'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      likes: json['likes'] as int? ?? json['likeCount'] as int? ?? 0,
      replies: (json['replies'] as List<dynamic>? ?? [])
          .map(
            (item) => ExploreComment.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  ExploreComment copyWith({List<ExploreComment>? replies, String? imageUrl}) {
    return ExploreComment(
      id: id,
      parentCommentId: parentCommentId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      content: content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      likes: likes,
      replies: replies ?? this.replies,
    );
  }
}

// ─── Bộ lọc sắp xếp (radio – chỉ chọn 1) ────────────────────────────────────
enum ExploreRegionFilter { north, south, central }

// ─── Bộ lọc mức giá (multi-select) ──────────────────────────────────────────
enum ExplorePriceFilter {
  budget, // 1 – $ Rẻ
  mid, // 2 – $$ Trung bình
  high, // 3 – $$$ Cao
  luxury, // 4 – $$$$ Sang trọng
}

// ─── Danh sách tỉnh/thành phố du lịch nổi tiếng ─────────────────────────────
class ExploreCityOption {
  final String slug;
  final String name; // Tên tiếng Việt có dấu
  final String region; // 'north' | 'south' | 'central'

  const ExploreCityOption({
    required this.slug,
    required this.name,
    required this.region,
  });
}

const List<ExploreCityOption> kPopularCities = [
  ExploreCityOption(slug: 'ha-noi', name: 'Hà Nội', region: 'north'),
  ExploreCityOption(slug: 'ha-long', name: 'Hạ Long', region: 'north'),
  ExploreCityOption(slug: 'sapa', name: 'Sa Pa', region: 'north'),
  ExploreCityOption(slug: 'ninh-binh', name: 'Ninh Bình', region: 'north'),
  ExploreCityOption(slug: 'da-nang', name: 'Đà Nẵng', region: 'central'),
  ExploreCityOption(slug: 'hue', name: 'Huế', region: 'central'),
  ExploreCityOption(slug: 'hoi-an', name: 'Hội An', region: 'central'),
  ExploreCityOption(slug: 'quang-binh', name: 'Quảng Bình', region: 'central'),
  ExploreCityOption(
    slug: 'ho-chi-minh',
    name: 'TP. Hồ Chí Minh',
    region: 'south',
  ),
  ExploreCityOption(slug: 'phu-quoc', name: 'Phú Quốc', region: 'south'),
  ExploreCityOption(slug: 'da-lat', name: 'Đà Lạt', region: 'south'),
  ExploreCityOption(slug: 'can-tho', name: 'Cần Thơ', region: 'south'),
];

// ─── Enum sắp xếp (dùng cho chip bar + filter view) ─────────────────────────
enum ExploreFilter {
  newest,
  mostViewed,
  topRated,
  // Giữ lại để backward-compat nhưng không dùng trong filter view nữa
  north,
  south,
  central,
  beach,
  mountain,
  city,
}

extension ExploreFilterLabel on ExploreFilter {
  String get labelVi {
    switch (this) {
      case ExploreFilter.newest:
        return 'Mới nhất';
      case ExploreFilter.mostViewed:
        return 'Xem nhiều';
      case ExploreFilter.topRated:
        return 'Đánh giá cao';
      case ExploreFilter.north:
        return 'Miền Bắc';
      case ExploreFilter.south:
        return 'Miền Nam';
      case ExploreFilter.central:
        return 'Miền Trung';
      case ExploreFilter.beach:
        return 'Biển đảo';
      case ExploreFilter.mountain:
        return 'Núi rừng';
      case ExploreFilter.city:
        return 'Thành phố';
    }
  }

  String get labelEn {
    switch (this) {
      case ExploreFilter.newest:
        return 'Newest';
      case ExploreFilter.mostViewed:
        return 'Most viewed';
      case ExploreFilter.topRated:
        return 'Top rated';
      case ExploreFilter.north:
        return 'North';
      case ExploreFilter.south:
        return 'South';
      case ExploreFilter.central:
        return 'Central';
      case ExploreFilter.beach:
        return 'Beaches';
      case ExploreFilter.mountain:
        return 'Mountains';
      case ExploreFilter.city:
        return 'Cities';
    }
  }
}

extension ExplorePriceLabel on ExplorePriceFilter {
  String get symbol {
    switch (this) {
      case ExplorePriceFilter.budget:
        return '\$';
      case ExplorePriceFilter.mid:
        return '\$\$';
      case ExplorePriceFilter.high:
        return '\$\$\$';
      case ExplorePriceFilter.luxury:
        return '\$\$\$\$';
    }
  }

  String get labelVi {
    switch (this) {
      case ExplorePriceFilter.budget:
        return 'Tiết kiệm (dưới 500k)';
      case ExplorePriceFilter.mid:
        return 'Trung bình (500k – 2 triệu)';
      case ExplorePriceFilter.high:
        return 'Cao cấp (2 triệu – 5 triệu)';
      case ExplorePriceFilter.luxury:
        return 'Sang trọng (trên 5 triệu)';
    }
  }

  int get level {
    switch (this) {
      case ExplorePriceFilter.budget:
        return 1;
      case ExplorePriceFilter.mid:
        return 2;
      case ExplorePriceFilter.high:
        return 3;
      case ExplorePriceFilter.luxury:
        return 4;
    }
  }
}
