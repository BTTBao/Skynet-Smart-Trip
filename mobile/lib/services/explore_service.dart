import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/explore_post.dart';
import 'api_service_base.dart';

class ExplorePageResult {
  const ExplorePageResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  final List<ExplorePost> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  factory ExplorePageResult.fromJson(Map<String, dynamic> json) {
    return ExplorePageResult(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => ExplorePost.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      totalItems: json['totalItems'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}

class ExploreService extends ApiService {
  Future<ExplorePageResult> getPosts({
    String? keyword,
    String sortBy = 'newest',
    Set<String> cities = const {},
    double? minRating,
    Set<int> costLevels = const {},
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = buildUri(configuredBaseUrl, '/explore/posts').replace(
      queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
        'sortBy': sortBy,
        if (keyword != null && keyword.trim().isNotEmpty)
          'keyword': keyword.trim(),
        if (cities.isNotEmpty) 'cities': cities.join(','),
        if (minRating != null) 'minRating': '$minRating',
        if (costLevels.isNotEmpty) 'costLevels': costLevels.join(','),
      },
    );

    final response = await http.get(uri, headers: await getHeaders());
    final data = Map<String, dynamic>.from(handleResponse(response));
    return ExplorePageResult.fromJson(data);
  }

  Future<ExplorePost> getPostDetail(int postId) async {
    final response = await getWithFallback('/explore/posts/$postId');
    final data = Map<String, dynamic>.from(handleResponse(response));
    return ExplorePost.fromJson(data);
  }

  Future<ExplorePost> createPost({
    required String title,
    required String content,
    required String location,
    required int costLevel,
    List<String> imageUrls = const [],
    String? city,
    String? region,
    List<String> tags = const [],
  }) async {
    final response = await postWithFallback(
      '/explore/posts',
      requireAuth: true,
      body: jsonEncode({
        'title': title,
        'content': content,
        'location': location,
        'city': city,
        'region': region,
        'costLevel': costLevel,
        'imageUrls': imageUrls,
        'tags': tags,
      }),
    );

    final data = Map<String, dynamic>.from(handleResponse(response));
    return ExplorePost.fromJson(data);
  }

  Future<({bool isLiked, int likeCount})> toggleLike(int postId) async {
    final response = await postWithFallback(
      '/explore/posts/$postId/like',
      requireAuth: true,
    );
    final data = Map<String, dynamic>.from(handleResponse(response));
    return (
      isLiked: data['isLiked'] as bool? ?? false,
      likeCount: data['likeCount'] as int? ?? 0,
    );
  }

  Future<({bool isSaved, int saveCount})> toggleSave(int postId) async {
    final response = await postWithFallback(
      '/explore/posts/$postId/save',
      requireAuth: true,
    );
    final data = Map<String, dynamic>.from(handleResponse(response));
    return (
      isSaved: data['isSaved'] as bool? ?? false,
      saveCount: data['saveCount'] as int? ?? 0,
    );
  }

  Future<ExploreComment> addComment(int postId, String content) async {
    final response = await postWithFallback(
      '/explore/posts/$postId/comments',
      requireAuth: true,
      body: jsonEncode({'content': content}),
    );
    final data = Map<String, dynamic>.from(handleResponse(response));
    return ExploreComment.fromJson(data);
  }
}
