class ExplorePost {
  final int id;
  final String title;
  final String excerpt;
  final String content;
  final String thumbnailUrl;
  final List<String> imageUrls;
  final String location;   // Tên tỉnh/thành phố hiển thị (e.g. "Hà Nội")
  final String city;       // City slug dùng để filter (e.g. "ha-noi")
  final String region;     // 'north' | 'south' | 'central'
  final String authorName;
  final String authorAvatar;
  final DateTime publishedAt;
  final int likes;
  final int views;
  final double rating;     // 0.0 – 5.0
  final int priceLevel;    // 1=Rẻ, 2=Trung bình, 3=Cao, 4=Sang trọng
  final bool isLiked;
  final bool isBookmarked;
  final List<ExploreComment> comments;
  final List<String> tags;

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
  });

  ExplorePost copyWith({
    bool? isLiked,
    bool? isBookmarked,
    int? likes,
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
      authorName: authorName,
      authorAvatar: authorAvatar,
      publishedAt: publishedAt,
      likes: likes ?? this.likes,
      views: views,
      rating: rating,
      priceLevel: priceLevel,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      comments: comments,
      tags: tags,
    );
  }
}

class ExploreComment {
  final int id;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime createdAt;
  final int likes;

  const ExploreComment({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.createdAt,
    required this.likes,
  });
}

// ─── Bộ lọc sắp xếp (radio – chỉ chọn 1) ────────────────────────────────────
enum ExploreRegionFilter {
  north,
  south,
  central,
}

// ─── Bộ lọc mức giá (multi-select) ──────────────────────────────────────────
enum ExplorePriceFilter {
  budget,   // 1 – $ Rẻ
  mid,      // 2 – $$ Trung bình
  high,     // 3 – $$$ Cao
  luxury,   // 4 – $$$$ Sang trọng
}

// ─── Danh sách tỉnh/thành phố du lịch nổi tiếng ─────────────────────────────
class ExploreCityOption {
  final String slug;
  final String name;      // Tên tiếng Việt có dấu
  final String region;    // 'north' | 'south' | 'central'

  const ExploreCityOption({
    required this.slug,
    required this.name,
    required this.region,
  });
}

const List<ExploreCityOption> kPopularCities = [
  ExploreCityOption(slug: 'ha-noi',      name: 'Hà Nội',        region: 'north'),
  ExploreCityOption(slug: 'ha-long',     name: 'Hạ Long',       region: 'north'),
  ExploreCityOption(slug: 'sapa',        name: 'Sa Pa',         region: 'north'),
  ExploreCityOption(slug: 'ninh-binh',   name: 'Ninh Bình',     region: 'north'),
  ExploreCityOption(slug: 'da-nang',     name: 'Đà Nẵng',       region: 'central'),
  ExploreCityOption(slug: 'hue',         name: 'Huế',           region: 'central'),
  ExploreCityOption(slug: 'hoi-an',      name: 'Hội An',        region: 'central'),
  ExploreCityOption(slug: 'quang-binh',  name: 'Quảng Bình',    region: 'central'),
  ExploreCityOption(slug: 'ho-chi-minh', name: 'TP. Hồ Chí Minh', region: 'south'),
  ExploreCityOption(slug: 'phu-quoc',    name: 'Phú Quốc',      region: 'south'),
  ExploreCityOption(slug: 'da-lat',      name: 'Đà Lạt',        region: 'south'),
  ExploreCityOption(slug: 'can-tho',     name: 'Cần Thơ',       region: 'south'),
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
