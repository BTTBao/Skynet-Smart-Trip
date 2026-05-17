import 'package:flutter/material.dart';

import '../models/explore_post.dart';

/// Trạng thái bộ lọc – không thay đổi (immutable).
class ExploreFilterState {
  final ExploreFilter sortBy;
  final Set<String> selectedCities;  // slug thành phố; rỗng = tất cả
  final double? minRating;           // null = tất cả; 3.0 | 3.5 | 4.0 | 4.5
  final Set<ExplorePriceFilter> prices; // rỗng = tất cả mức giá

  const ExploreFilterState({
    this.sortBy = ExploreFilter.newest,
    this.selectedCities = const {},
    this.minRating,
    this.prices = const {},
  });

  ExploreFilterState copyWith({
    ExploreFilter? sortBy,
    Set<String>? selectedCities,
    Object? minRating = _sentinel,
    Set<ExplorePriceFilter>? prices,
  }) {
    return ExploreFilterState(
      sortBy: sortBy ?? this.sortBy,
      selectedCities: selectedCities ?? this.selectedCities,
      minRating: minRating == _sentinel ? this.minRating : minRating as double?,
      prices: prices ?? this.prices,
    );
  }

  int get activeFilterCount {
    int count = 0;
    if (sortBy != ExploreFilter.newest) count++;
    if (selectedCities.isNotEmpty) count++;
    if (minRating != null) count++;
    if (prices.isNotEmpty) count++;
    return count;
  }

  static const _sentinel = Object();
}

class ExploreProvider with ChangeNotifier {
  List<ExplorePost> _allPosts = [];
  List<ExplorePost> _filteredPosts = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  ExploreFilterState _filterState = const ExploreFilterState();

  // ── Getters ───────────────────────────────────────────────────────────────
  List<ExplorePost> get posts => List.unmodifiable(_filteredPosts);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  ExploreFilterState get filterState => _filterState;

  /// Getter dùng bởi quick chip bar (chỉ sort).
  Set<ExploreFilter> get activeFilters => {_filterState.sortBy};

  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<void> fetchPosts({bool forceRefresh = false}) async {
    if (_allPosts.isNotEmpty && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      _allPosts = _generateMockPosts();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // ── Toggle sort từ quick chip bar ─────────────────────────────────────────
  void toggleFilter(ExploreFilter filter) {
    final sortFilters = {
      ExploreFilter.newest,
      ExploreFilter.mostViewed,
      ExploreFilter.topRated,
    };
    if (sortFilters.contains(filter)) {
      _filterState = _filterState.copyWith(sortBy: filter);
      _applyFilters();
      notifyListeners();
    }
  }

  // ── Áp dụng toàn bộ state từ filter sheet ────────────────────────────────
  void applyFilterState(ExploreFilterState state) {
    _filterState = state;
    _applyFilters();
    notifyListeners();
  }

  void resetFilters() {
    _filterState = const ExploreFilterState();
    _applyFilters();
    notifyListeners();
  }

  // ── Interactions ──────────────────────────────────────────────────────────
  void toggleLike(int postId) {
    final index = _allPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = _allPosts[index];
    _allPosts[index] = post.copyWith(
      isLiked: !post.isLiked,
      likes: post.isLiked ? post.likes - 1 : post.likes + 1,
    );
    _applyFilters();
    notifyListeners();
  }

  void toggleBookmark(int postId) {
    final index = _allPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = _allPosts[index];
    _allPosts[index] = post.copyWith(isBookmarked: !post.isBookmarked);
    _applyFilters();
    notifyListeners();
  }

  ExplorePost? getPostById(int id) {
    try {
      return _allPosts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Logic lọc ─────────────────────────────────────────────────────────────
  void _applyFilters() {
    var result = List<ExplorePost>.from(_allPosts);

    // 1. Tìm kiếm
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) {
        return p.title.toLowerCase().contains(q) ||
            p.location.toLowerCase().contains(q) ||
            p.city.toLowerCase().contains(q) ||
            p.excerpt.toLowerCase().contains(q) ||
            p.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    // 2. Tỉnh/thành phố
    if (_filterState.selectedCities.isNotEmpty) {
      result = result
          .where((p) => _filterState.selectedCities.contains(p.city))
          .toList();
    }

    // 3. Đánh giá tối thiểu
    if (_filterState.minRating != null) {
      result =
          result.where((p) => p.rating >= _filterState.minRating!).toList();
    }

    // 4. Mức giá
    if (_filterState.prices.isNotEmpty) {
      final levels = _filterState.prices.map((f) => f.level).toSet();
      result = result.where((p) => levels.contains(p.priceLevel)).toList();
    }

    // 5. Sắp xếp
    switch (_filterState.sortBy) {
      case ExploreFilter.mostViewed:
        result.sort((a, b) => b.views.compareTo(a.views));
        break;
      case ExploreFilter.topRated:
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        result.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    }

    _filteredPosts = result;
  }

  // ── Dữ liệu mẫu ──────────────────────────────────────────────────────────
  List<ExplorePost> _generateMockPosts() {
    final now = DateTime.now();
    return [
      ExplorePost(
        id: 1,
        title: 'Khám phá Vịnh Hạ Long – Kỳ quan thiên nhiên thế giới',
        excerpt:
            'Vịnh Hạ Long với hàng nghìn hòn đảo đá vôi – một trong những di sản thiên nhiên đẹp nhất thế giới mà bạn nhất định phải ghé.',
        content:
            'Hạ Long Bay là một trong những di sản thiên nhiên thế giới được UNESCO công nhận. Với hơn 1.600 hòn đảo đá vôi như những trường thành tự nhiên, Hạ Long mang đến những bức tranh thiên nhiên hùng vĩ.\n\n[image:https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800]\n\nDu khách đến Hạ Long thường trải nghiệm du thuyền qua đêm, tham quan các động thạch như Đầu Gỗ, Sửng Sốt.',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=800',
        imageUrls: [
          'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=800',
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
        ],
        location: 'Quảng Ninh',
        city: 'ha-long',
        region: 'north',
        authorName: 'Nguyễn Anh Dũ',
        authorAvatar: 'https://i.pravatar.cc/150?img=1',
        publishedAt: now.subtract(const Duration(days: 1)),
        likes: 234,
        views: 1820,
        rating: 4.7,
        priceLevel: 3,
        isLiked: false,
        isBookmarked: false,
        comments: _buildMockComments(now),
        tags: ['biển', 'đảo', 'du-lịch-biển', 'hạ-long'],
      ),
      ExplorePost(
        id: 2,
        title: 'Sa Pa – Thành phố trong sương huyền ảo giữa dãy Hoàng Liên Sơn',
        excerpt:
            'Với nhiệt độ mát mẻ quanh năm và những thung lũng lúa bậc thang tuyệt đẹp, Sa Pa là điểm đến lý tưởng cho người yêu thiên nhiên.',
        content:
            'Sa Pa là thị xã miền núi thuộc tỉnh Lào Cai ở độ cao khoảng 1.600m. Đây là nơi sinh sống của nhiều dân tộc thiểu số như H\'Mông, Dao, Tày...\n\n[image:https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800]\n\nKhông nên bỏ qua: Thung lũng Mường Hoa với ruộng bậc thang, đỉnh Fansipan cao 3.143m.',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1627476435344-22c3ae9a02c4?w=800',
        imageUrls: [
          'https://images.unsplash.com/photo-1627476435344-22c3ae9a02c4?w=800',
        ],
        location: 'Lào Cai',
        city: 'sapa',
        region: 'north',
        authorName: 'Trần Mai Linh',
        authorAvatar: 'https://i.pravatar.cc/150?img=5',
        publishedAt: now.subtract(const Duration(days: 3)),
        likes: 412,
        views: 3240,
        rating: 4.5,
        priceLevel: 2,
        isLiked: true,
        isBookmarked: false,
        comments: _buildMockComments(now),
        tags: ['núi', 'miền-bắc', 'sapa', 'bản-làng'],
      ),
      ExplorePost(
        id: 3,
        title: 'Hội An – Phố cổ nghìn tuổi lung linh ánh đèn',
        excerpt:
            'Hội An về đêm lung linh với những chiếc đèn lồng, bất ngờ với sự hòa trộn của kiến trúc Nhật-Trung-Việt độc đáo.',
        content:
            'Phố cổ Hội An là một trong những di sản văn hóa thế giới được bảo tồn tốt nhất châu Á.\n\n[image:https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800]\n\nĐặc sản: Cao lầu, cơm gà Hội An, bánh mì, mì Quảng.',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
        imageUrls: [
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
        ],
        location: 'Quảng Nam',
        city: 'hoi-an',
        region: 'central',
        authorName: 'Lê Bảo Trân',
        authorAvatar: 'https://i.pravatar.cc/150?img=9',
        publishedAt: now.subtract(const Duration(days: 5)),
        likes: 681,
        views: 5120,
        rating: 4.8,
        priceLevel: 2,
        isLiked: false,
        isBookmarked: true,
        comments: _buildMockComments(now),
        tags: ['thành-phố', 'di-sản', 'miền-trung', 'hội-an'],
      ),
      ExplorePost(
        id: 4,
        title: 'Phú Quốc – Hòn đảo ngọc của Việt Nam',
        excerpt:
            'Bãi biển cát trắng mịn, nước biển xanh như pha lê và hoàng hôn rực rỡ – Phú Quốc là thiên đường nghỉ dưỡng lý tưởng.',
        content:
            'Phú Quốc là hòn đảo lớn nhất Việt Nam và là một trong những điểm du lịch biển nổi tiếng nhất Đông Nam Á.\n\n[image:https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800]\n\nẨm thực: Hải sản tươi sống, nước mắm Phú Quốc, hàm tiền cá rạ.',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800',
        imageUrls: [
          'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800',
        ],
        location: 'Kiên Giang',
        city: 'phu-quoc',
        region: 'south',
        authorName: 'Phạm Thị Hoa',
        authorAvatar: 'https://i.pravatar.cc/150?img=20',
        publishedAt: now.subtract(const Duration(days: 7)),
        likes: 893,
        views: 7650,
        rating: 4.6,
        priceLevel: 3,
        isLiked: false,
        isBookmarked: false,
        comments: _buildMockComments(now),
        tags: ['biển', 'đảo', 'miền-nam', 'phú-quốc'],
      ),
      ExplorePost(
        id: 5,
        title: 'Đà Lạt – Thành phố ngàn hoa trong sương mù',
        excerpt:
            'Khí hậu mát mẻ, vườn hoa khắp nơi, những ngôi biệt thự Pháp cổ kính – Đà Lạt là "Tiểu Paris" của Việt Nam.',
        content:
            'Đà Lạt là thành phố tọa lạc trên cao nguyên Lâm Viên, ở độ cao 1.500m.\n\n[image:https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800]\n\nĐặc sản: Đậu hũ đất Đỏ, Bánh căn, Dâu tây tươi, Rượu vang Đà Lạt.',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800',
        imageUrls: [
          'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800',
        ],
        location: 'Lâm Đồng',
        city: 'da-lat',
        region: 'south',
        authorName: 'Nguyễn Minh Khoa',
        authorAvatar: 'https://i.pravatar.cc/150?img=33',
        publishedAt: now.subtract(const Duration(days: 2)),
        likes: 547,
        views: 4320,
        rating: 4.4,
        priceLevel: 2,
        isLiked: true,
        isBookmarked: true,
        comments: _buildMockComments(now),
        tags: ['núi', 'thành-phố', 'miền-nam', 'đà-lạt'],
      ),
      ExplorePost(
        id: 6,
        title: 'Phong Nha – Kẻ Bàng: Hệ thống hang động vĩ đại nhất hành tinh',
        excerpt:
            'Hang động lớn nhất thế giới Sơn Đoòng và hệ thống hang động phong phú nhất hành tinh nằm ở Quảng Bình.',
        content:
            'Vườn quốc gia Phong Nha – Kẻ Bàng được UNESCO công nhận là di sản thiên nhiên 2003.\n\n[image:https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800]\n\nTour Sơn Đoòng chỉ có thể đặt trước 12-18 tháng, tối đa 1.000 người/năm, giá từ 3.000 USD.',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1504701954957-2010ec3bcec1?w=800',
        imageUrls: [
          'https://images.unsplash.com/photo-1504701954957-2010ec3bcec1?w=800',
        ],
        location: 'Quảng Bình',
        city: 'quang-binh',
        region: 'central',
        authorName: 'Võ Thị Lan',
        authorAvatar: 'https://i.pravatar.cc/150?img=47',
        publishedAt: now.subtract(const Duration(days: 10)),
        likes: 1032,
        views: 9870,
        rating: 4.9,
        priceLevel: 4,
        isLiked: false,
        isBookmarked: false,
        comments: _buildMockComments(now),
        tags: ['núi', 'di-sản', 'miền-trung', 'phong-nha'],
      ),
      ExplorePost(
        id: 7,
        title: 'Hà Nội – Thủ đô ngàn năm văn hiến đầy sức sống',
        excerpt:
            'Hà Nội với 36 phố phường cổ kính, hồ Hoàn Kiếm, chén trà trứng cà phê phố – trải nghiệm khó quên của người Bắc.',
        content:
            'Hà Nội là thủ đô của Việt Nam với lịch sử hơn 1.000 năm tuổi.\n\n[image:https://images.unsplash.com/photo-1547046464-a83a1bc15a02?w=800]\n\nKhông nên bỏ qua: Hồ Hoàn Kiếm, Văn Miếu, Ba Đình, Phố cổ 36 đường...\n\nẨm thực Hà Nội: Phở bò, Bún chả, Chả cá Lã Vọng, Bánh cuốn.',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1547046464-a83a1bc15a02?w=800',
        imageUrls: [
          'https://images.unsplash.com/photo-1547046464-a83a1bc15a02?w=800',
        ],
        location: 'Hà Nội',
        city: 'ha-noi',
        region: 'north',
        authorName: 'Bùi Thanh Hải',
        authorAvatar: 'https://i.pravatar.cc/150?img=55',
        publishedAt: now.subtract(const Duration(days: 4)),
        likes: 765,
        views: 6430,
        rating: 4.3,
        priceLevel: 1,
        isLiked: false,
        isBookmarked: false,
        comments: _buildMockComments(now),
        tags: ['thành-phố', 'di-sản', 'miền-bắc', 'hà-nội'],
      ),
      ExplorePost(
        id: 8,
        title: 'Đà Nẵng – Thành phố đáng sống nhất Việt Nam',
        excerpt:
            'Bãi biển Mỹ Khê, cầu Rồng phun lửa, núi Thần Tài, Bà Nà Hills – Đà Nẵng là toàn diện nhất cho mọi loại du khách.',
        content:
            'Đà Nẵng là trung tâm kinh tế của miền Trung và là một trong những thành phố phát triển nhanh nhất Việt Nam.\n\n[image:https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=800]\n\nĐiểm tham quan nổi bật: Cầu Rồng, Bà Nà Hills, bãi biển Mỹ Khê, núi Sơn Trà.',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=800',
        imageUrls: [
          'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=800',
        ],
        location: 'Đà Nẵng',
        city: 'da-nang',
        region: 'central',
        authorName: 'Nguyễn Thị Ngọc',
        authorAvatar: 'https://i.pravatar.cc/150?img=60',
        publishedAt: now.subtract(const Duration(days: 6)),
        likes: 598,
        views: 5870,
        rating: 4.6,
        priceLevel: 2,
        isLiked: false,
        isBookmarked: false,
        comments: _buildMockComments(now),
        tags: ['biển', 'thành-phố', 'miền-trung', 'đà-nẵng'],
      ),
    ];
  }

  static List<ExploreComment> _buildMockComments(DateTime now) {
    return [
      ExploreComment(
        id: 1,
        authorName: 'Minh Tú',
        authorAvatar: 'https://i.pravatar.cc/150?img=12',
        content: 'Bài viết rất hay và chi tiết! Mình sẽ lưu lại để đi thôi.',
        createdAt: now.subtract(const Duration(days: 1)),
        likes: 8,
      ),
      ExploreComment(
        id: 2,
        authorName: 'Hà Vy',
        authorAvatar: 'https://i.pravatar.cc/150?img=30',
        content: 'Đã đi rồi, thật sự đẹp như trong bài viết. Recommend cho tất cả mọi người!',
        createdAt: now.subtract(const Duration(days: 2)),
        likes: 15,
      ),
      ExploreComment(
        id: 3,
        authorName: 'Tuấn Anh',
        authorAvatar: 'https://i.pravatar.cc/150?img=65',
        content: 'Phần ẩm thực chi tiết hơn được không? Mình muốn biết giá cả thêm.',
        createdAt: now.subtract(const Duration(days: 3)),
        likes: 3,
      ),
    ];
  }
}
