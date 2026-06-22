import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/explore_post.dart';
import '../services/explore_service.dart';

class ExploreFilterState {
  final ExploreFilter sortBy;
  final Set<String> selectedCities;
  final double? minRating;
  final Set<ExplorePriceFilter> prices;

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
    var count = 0;
    if (sortBy != ExploreFilter.newest) count++;
    if (selectedCities.isNotEmpty) count++;
    if (minRating != null) count++;
    if (prices.isNotEmpty) count++;
    return count;
  }

  static const _sentinel = Object();
}

class ExploreProvider with ChangeNotifier {
  final ExploreService _service = ExploreService();

  List<ExplorePost> _allPosts = [];
  List<ExplorePost> _filteredPosts = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  ExploreFilterState _filterState = const ExploreFilterState();
  int _page = 1;

  List<ExplorePost> get posts => List.unmodifiable(_filteredPosts);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  ExploreFilterState get filterState => _filterState;
  Set<ExploreFilter> get activeFilters => {_filterState.sortBy};

  Future<void> fetchPosts({bool forceRefresh = false}) async {
    if (_allPosts.isNotEmpty && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getPosts(
        keyword: _searchQuery,
        sortBy: _sortValue(_filterState.sortBy),
        cities: _filterState.selectedCities,
        minRating: _filterState.minRating,
        costLevels: _filterState.prices.map((price) => price.level).toSet(),
        page: _page,
        pageSize: 30,
      );

      _allPosts = result.items;
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _page = 1;
    fetchPosts(forceRefresh: true);
    notifyListeners();
  }

  void toggleFilter(ExploreFilter filter) {
    const sortFilters = {
      ExploreFilter.newest,
      ExploreFilter.mostViewed,
      ExploreFilter.topRated,
    };

    if (!sortFilters.contains(filter)) return;

    _filterState = _filterState.copyWith(sortBy: filter);
    _page = 1;
    fetchPosts(forceRefresh: true);
    notifyListeners();
  }

  void applyFilterState(ExploreFilterState state) {
    _filterState = state;
    _page = 1;
    fetchPosts(forceRefresh: true);
    notifyListeners();
  }

  void resetFilters() {
    _filterState = const ExploreFilterState();
    _searchQuery = '';
    _page = 1;
    fetchPosts(forceRefresh: true);
    notifyListeners();
  }

  Future<void> toggleLike(int postId) async {
    final index = _allPosts.indexWhere((post) => post.id == postId);
    if (index == -1) return;

    try {
      final result = await _service.toggleLike(postId);
      _allPosts[index] = _allPosts[index].copyWith(
        isLiked: result.isLiked,
        likes: result.likeCount,
      );
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleBookmark(int postId) async {
    final index = _allPosts.indexWhere((post) => post.id == postId);
    if (index == -1) return;

    try {
      final result = await _service.toggleSave(postId);
      _allPosts[index] = _allPosts[index].copyWith(
        isBookmarked: result.isSaved,
      );
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchPostDetail(int postId) async {
    try {
      final post = await _service.getPostDetail(postId);
      final index = _allPosts.indexWhere((item) => item.id == postId);
      if (index == -1) {
        _allPosts.add(post);
      } else {
        _allPosts[index] = post;
      }
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createPost({
    required String title,
    required String content,
    required String location,
    required int costLevel,
    required List<String> imageUrls,
    double? latitude,
    double? longitude,
    String? linkedTripCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final city = _resolveCitySlug(location);
      final created = await _service.createPost(
        title: title,
        content: content,
        location: location,
        costLevel: costLevel,
        imageUrls: imageUrls,
        city: city,
        latitude: latitude,
        longitude: longitude,
        region: city == null
            ? null
            : kPopularCities.firstWhere((item) => item.slug == city).region,
        linkedTripCode: linkedTripCode,
      );

      _allPosts = [created, ..._allPosts];
      _applyFilters();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addComment(
    int postId,
    String content, {
    String? imageUrl,
  }) async {
    return addCommentReply(
      postId: postId,
      content: content,
      imageUrl: imageUrl,
    );
  }

  Future<bool> addCommentReply({
    required int postId,
    required String content,
    String? imageUrl,
    int? parentCommentId,
  }) async {
    final trimmed = content.trim();
    final trimmedImageUrl = imageUrl?.trim();
    if (trimmed.isEmpty &&
        (trimmedImageUrl == null || trimmedImageUrl.isEmpty)) {
      return false;
    }

    try {
      final comment = await _service.addCommentReply(
        postId: postId,
        content: trimmed,
        imageUrl: trimmedImageUrl,
        parentCommentId: parentCommentId,
      );
      final index = _allPosts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        final post = _allPosts[index];
        final updatedComments = parentCommentId == null
            ? [comment, ...post.comments]
            : post.comments.map((item) {
                if (item.id != parentCommentId) {
                  return item;
                }

                return item.copyWith(replies: [...item.replies, comment]);
              }).toList();
        _allPosts[index] = post.copyWith(comments: updatedComments);
        _applyFilters();
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String> uploadImage(XFile image) => _service.uploadPostImage(image);

  void applyCityFilter(String citySlug) {
    final updated = Set<String>.from(_filterState.selectedCities)
      ..add(citySlug);
    _filterState = _filterState.copyWith(selectedCities: updated);
    _page = 1;
    fetchPosts(forceRefresh: true);
    notifyListeners();
  }

  void removeCityFilter(String citySlug) {
    final updated = Set<String>.from(_filterState.selectedCities)
      ..remove(citySlug);
    _filterState = _filterState.copyWith(selectedCities: updated);
    _page = 1;
    fetchPosts(forceRefresh: true);
    notifyListeners();
  }

  ExplorePost? getPostById(int id) {
    try {
      return _allPosts.firstWhere((post) => post.id == id);
    } catch (_) {
      return null;
    }
  }

  void _applyFilters() {
    var result = List<ExplorePost>.from(_allPosts);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();

      // Resolve city name matches from kPopularCities (e.g. searching "đà" matches "da-nang" and "da-lat")
      final matchedCities = kPopularCities.where((city) {
        final cityName = city.name.toLowerCase();
        final cityNameNoAccent = _normalize(city.name);
        final queryNoAccent = _normalize(query);
        return query.length >= 2 &&
            (cityName.contains(query) ||
                cityNameNoAccent.contains(queryNoAccent));
      }).toList();

      if (matchedCities.isNotEmpty) {
        final matchedSlugs = matchedCities.map((c) => c.slug).toSet();
        result = result
            .where((post) => matchedSlugs.contains(post.city))
            .toList();
      } else {
        // General search: strict accent-sensitive matching if query has accents, avoiding false positives like "đà" matching "đảo"
        final accentRegex = RegExp(
          r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]',
        );
        final hasAcc = accentRegex.hasMatch(query);

        result = result.where((post) {
          if (hasAcc) {
            return post.title.toLowerCase().contains(query) ||
                post.location.toLowerCase().contains(query) ||
                post.city.toLowerCase().contains(query) ||
                post.excerpt.toLowerCase().contains(query) ||
                post.tags.any((tag) => tag.toLowerCase().contains(query));
          } else {
            final queryNorm = _normalize(query);
            return _normalize(post.title).contains(queryNorm) ||
                _normalize(post.location).contains(queryNorm) ||
                _normalize(post.city).contains(queryNorm) ||
                _normalize(post.excerpt).contains(queryNorm) ||
                post.tags.any((tag) => _normalize(tag).contains(queryNorm));
          }
        }).toList();
      }
    }

    if (_filterState.selectedCities.isNotEmpty) {
      result = result
          .where((post) => _filterState.selectedCities.contains(post.city))
          .toList();
    }

    if (_filterState.minRating != null) {
      result = result
          .where((post) => post.rating >= _filterState.minRating!)
          .toList();
    }

    if (_filterState.prices.isNotEmpty) {
      final levels = _filterState.prices.map((filter) => filter.level).toSet();
      result = result
          .where((post) => levels.contains(post.priceLevel))
          .toList();
    }

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

  static String _sortValue(ExploreFilter filter) {
    switch (filter) {
      case ExploreFilter.mostViewed:
        return 'mostViewed';
      case ExploreFilter.topRated:
        return 'topRated';
      default:
        return 'newest';
    }
  }

  static String? _resolveCitySlug(String location) {
    final normalized = _normalize(location);
    for (final city in kPopularCities) {
      if (_normalize(city.name) == normalized || city.slug == normalized) {
        return city.slug;
      }
    }

    return null;
  }

  static String _normalize(String value) {
    const replacements = {
      'đ': 'd',
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
    };

    var result = value.trim().toLowerCase().replaceAll(' ', '-');
    replacements.forEach((source, target) {
      result = result.replaceAll(source, target);
    });
    return result;
  }
}
