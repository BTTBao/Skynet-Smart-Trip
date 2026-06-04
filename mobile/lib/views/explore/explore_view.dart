import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/explore_post.dart';
import '../../providers/destination_provider.dart';
import '../../providers/explore_provider.dart';
import '../../utils/app_text.dart';
import '../main_shell.dart';
import '../resort_search/resort_search_screen.dart';
import '../catalog/search_view.dart';
import 'explore_create_post_view.dart';
import 'explore_filter_view.dart';
import 'explore_post_detail_view.dart';
import 'explore_ui_constants.dart';
import 'widgets/explore_filter_chips.dart';
import 'widgets/explore_post_card.dart';

// ─── Category model (local) ───────────────────────────────────────────────────

class _CategoryItem {
  final String name;
  final IconData icon;
  const _CategoryItem(this.name, this.icon);
}

// ─── ExploreView (Unified Screen) ────────────────────────────────────────────

class ExploreView extends StatefulWidget {
  const ExploreView({super.key, this.initialCitySlug, this.initialCityName});

  final String? initialCitySlug;
  final String? initialCityName;

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _searchFocused = false;
  String _searchQuery = '';
  String? _selectedCategory;
  int _postsLimit = 5;

  static const _categories = [
    _CategoryItem('Biển đảo', Icons.beach_access_rounded),
    _CategoryItem('Nghỉ dưỡng', Icons.spa_rounded),
    _CategoryItem('Cắm trại', Icons.terrain_rounded),
    _CategoryItem('Di tích', Icons.museum_rounded),
    _CategoryItem('Ẩm thực', Icons.restaurant_rounded),
    _CategoryItem('Thành phố', Icons.location_city_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final exploreProvider = context.read<ExploreProvider>();
      final citySlug = widget.initialCitySlug;
      if (citySlug != null && citySlug.isNotEmpty) {
        exploreProvider.applyCityFilter(citySlug);
        Future.delayed(const Duration(milliseconds: 350), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              620.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });
      } else {
        exploreProvider.fetchPosts();
      }
      context.read<DestinationProvider>().fetchDestinations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openPostDetail(ExplorePost post) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExplorePostDetailView(postId: post.id)),
    );
  }

  void _openFilterSheet() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ExploreFilterView(),
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _postsLimit = 5;
    });
    context.read<ExploreProvider>().setSearchQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExploreColors.background,
      body: SafeArea(
        child: Consumer2<ExploreProvider, DestinationProvider>(
          builder: (context, exploreProvider, destProvider, _) {
            return RefreshIndicator(
              color: ExploreColors.primary,
              onRefresh: () async {
                await exploreProvider.fetchPosts(forceRefresh: true);
                await destProvider.fetchDestinations(forceRefresh: true);
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Unified Header + Search Bar ───────────────────────────
                  SliverToBoxAdapter(
                    child: _UnifiedHeader(
                      searchController: _searchController,
                      isFocused: _searchFocused,
                      onFocusChange: (v) => setState(() => _searchFocused = v),
                      onSearch: _onSearchChanged,
                    ),
                  ),

                  // ── Danh mục trải nghiệm ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: _CategorySection(
                      categories: _categories,
                      selectedCategory: _selectedCategory,
                      onCategoryTap: (cat) {
                        setState(() {
                          _selectedCategory = _selectedCategory == cat
                              ? null
                              : cat;
                          _postsLimit = 5;
                        });
                      },
                    ),
                  ),

                  // ── Slider ưu đãi ─────────────────────────────────────────
                  const SliverToBoxAdapter(child: _PromotionSection()),

                  // ── Điểm đến phổ biến ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _DestinationsSection(
                      destProvider: destProvider,
                      searchQuery: _searchQuery,
                      selectedCategory: _selectedCategory,
                      onDestinationTap: (name, id) =>
                          _showActionSheet(context, name, id),
                    ),
                  ),

                  // ── Cẩm nang & Bài viết ───────────────────────────────────
                  // const SliverToBoxAdapter(child: _ArticlesSection()),

                  // ── Phân cách cộng đồng ───────────────────────────────────
                  const SliverToBoxAdapter(child: _CommunityDivider()),

                  // ── Filter chips cộng đồng ───────────────────────────────
                  SliverToBoxAdapter(
                    child: _FilterBar(
                      filterState: exploreProvider.filterState,
                      activeFilters: exploreProvider.activeFilters,
                      onToggle: (f) {
                        exploreProvider.toggleFilter(f);
                        setState(() => _postsLimit = 5);
                      },
                      onRemoveCity: (slug) {
                        exploreProvider.removeCityFilter(slug);
                        setState(() => _postsLimit = 5);
                      },
                      onOpenFilter: _openFilterSheet,
                    ),
                  ),

                  // ── Feed bài viết cộng đồng ──────────────────────────────
                  if (exploreProvider.isLoading)
                    const SliverToBoxAdapter(child: _LoadingState())
                  else if (exploreProvider.error != null &&
                      exploreProvider.posts.isEmpty)
                    SliverToBoxAdapter(
                      child: _ErrorState(
                        message: exploreProvider.error!,
                        onRetry: () =>
                            exploreProvider.fetchPosts(forceRefresh: true),
                      ),
                    )
                  else if (exploreProvider.posts.isEmpty)
                    SliverToBoxAdapter(
                      child: _EmptyState(
                        query: exploreProvider.searchQuery,
                        onReset: exploreProvider.resetFilters,
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = exploreProvider.posts[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: ExplorePostCard(
                                post: post,
                                onTap: () => _openPostDetail(post),
                                onLike: () =>
                                    exploreProvider.toggleLike(post.id),
                              ),
                            );
                          },
                          childCount: exploreProvider.posts.length > _postsLimit
                              ? _postsLimit
                              : exploreProvider.posts.length,
                        ),
                      ),
                    ),
                    if (exploreProvider.posts.length > _postsLimit)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          child: Center(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _postsLimit += 5;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ExploreColors.primary,
                                side: const BorderSide(
                                  color: ExploreColors.primary,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                              label: const Text(
                                'Hiển thị thêm bài viết',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: _CreatePostFab(),
    );
  }

  // ─── Action sheet khi nhấn điểm đến ────────────────────────────────────────

  void _showActionSheet(
    BuildContext context,
    String destination,
    int destinationId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Khám phá $destination',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Chọn loại hình dịch vụ bạn muốn trải nghiệm.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),
                _buildOptionCard(
                  sheetContext,
                  icon: Icons.hotel_rounded,
                  color: const Color(0xFF0D6B42),
                  label: 'LƯU TRÚ',
                  description: 'Tìm Khách sạn / Resort sang trọng',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResortSearchScreen(
                          destinationId: destinationId,
                          destinationName: destination,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionCard(
                  sheetContext,
                  icon: Icons.directions_bus_rounded,
                  color: const Color(0xFF1B5E20),
                  label: 'DI CHUYỂN',
                  description: 'Đặt vé xe Limousine chất lượng cao',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SearchView(
                          initialMode: SearchMode.bus,
                          initialDestinationId: destinationId,
                          initialQuery: destination,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {
                      final citySlug = _resolveExploreCitySlug(destination);
                      Navigator.pop(sheetContext);

                      final shell =
                          MainShell.maybeOf(context) ??
                          MainShell.maybeOf(sheetContext);
                      if (shell != null) {
                        shell.openExplore(
                          citySlug: citySlug,
                          cityName: destination,
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExploreView(
                            initialCitySlug: citySlug,
                            initialCityName: destination,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          color: Colors.green[800],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Đọc cẩm nang chi tiết về $destination',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _resolveExploreCitySlug(String destination) {
    final normalized = _normalize(destination);
    for (final city in kPopularCities) {
      if (_normalize(city.name) == normalized || city.slug == normalized) {
        return city.slug;
      }
    }
    return null;
  }

  String _normalize(String value) {
    const replacements = {
      'đ': 'd',
      'Đ': 'd',
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

// ─── Unified Header ───────────────────────────────────────────────────────────

class _UnifiedHeader extends StatelessWidget {
  const _UnifiedHeader({
    required this.searchController,
    required this.isFocused,
    required this.onFocusChange,
    required this.onSearch,
  });

  final TextEditingController searchController;
  final bool isFocused;
  final ValueChanged<bool> onFocusChange;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(vi: 'Khám Phá', en: 'Explore'),
                      style: ExploreTextStyles.sectionHeading,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(
                        vi: 'Điểm đến, trải nghiệm & cộng đồng.',
                        en: 'Destinations, experiences & community.',
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: ExploreColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF80ED99), Color(0xFF18A558)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Unified search bar
          Focus(
            onFocusChange: onFocusChange,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFocused
                      ? ExploreColors.primary
                      : ExploreColors.border,
                  width: isFocused ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearch,
                style: const TextStyle(
                  fontSize: 14,
                  color: ExploreColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: context.tr(
                    vi: 'Tìm điểm đến, bài viết cộng đồng...',
                    en: 'Search destinations, community posts...',
                  ),
                  hintStyle: const TextStyle(
                    color: ExploreColors.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: ExploreColors.textMuted,
                    size: 20,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            searchController.clear();
                            onSearch('');
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            color: ExploreColors.textMuted,
                            size: 18,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Section ─────────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  final List<_CategoryItem> categories;
  final String? selectedCategory;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bạn muốn trải nghiệm gì?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 92,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = selectedCategory == cat.name;

                return Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: GestureDetector(
                    onTap: () => onCategoryTap(cat.name),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? ExploreColors.primary
                                : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? ExploreColors.primary.withValues(
                                        alpha: 0.3,
                                      )
                                    : Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: isSelected
                                  ? ExploreColors.primary
                                  : Colors.grey[100]!,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            cat.icon,
                            color: isSelected
                                ? Colors.white
                                : ExploreColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected
                                ? ExploreColors.primary
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Promotion Section ────────────────────────────────────────────────────────

class _PromotionSection extends StatelessWidget {
  const _PromotionSection();

  @override
  Widget build(BuildContext context) {
    final promos = [
      {
        'title': 'Mùa Hè Rực Rỡ',
        'subtitle': 'Giảm ngay 15% đặt phòng khách sạn',
        'code': 'SUMMER15',
        'gradient': const LinearGradient(
          colors: [Color(0xFF0D6B42), Color(0xFF1E8D5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        'title': 'Đặt Xe Limousine',
        'subtitle': 'Ưu đãi đặt sớm giảm 30k chuyến đi',
        'code': 'LIMOSMART',
        'gradient': const LinearGradient(
          colors: [Color(0xFF1F4E3D), Color(0xFF0D6B42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 0, 28),
      child: SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: promos.length,
          itemBuilder: (context, index) {
            final promo = promos[index];
            final gradient = promo['gradient'] as LinearGradient;
            return Container(
              width: 280,
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        promo['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        promo['subtitle'] as String,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Code: ${promo['code']}',
                          style: TextStyle(
                            color: gradient.colors.first,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: -10,
                    bottom: -10,
                    child: Icon(
                      Icons.card_giftcard,
                      color: Colors.white.withValues(alpha: 0.12),
                      size: 80,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Destinations Section ─────────────────────────────────────────────────────

class _DestinationsSection extends StatefulWidget {
  const _DestinationsSection({
    required this.destProvider,
    required this.searchQuery,
    required this.selectedCategory,
    required this.onDestinationTap,
  });

  final DestinationProvider destProvider;
  final String searchQuery;
  final String? selectedCategory;
  final void Function(String name, int id) onDestinationTap;

  @override
  State<_DestinationsSection> createState() => _DestinationsSectionState();
}

class _DestinationsSectionState extends State<_DestinationsSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Điểm đến nổi bật',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.destProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ExploreColors.primary),
          ),
        ),
      );
    }

    if (widget.destProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                widget.destProvider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    widget.destProvider.fetchDestinations(forceRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ExploreColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = widget.destProvider.destinations.where((dest) {
      if (widget.searchQuery.isNotEmpty) {
        final match =
            dest.name.toLowerCase().contains(
              widget.searchQuery.toLowerCase(),
            ) ||
            dest.description.toLowerCase().contains(
              widget.searchQuery.toLowerCase(),
            );
        if (!match) return false;
      }

      if (widget.selectedCategory != null) {
        final cat = widget.selectedCategory!.toLowerCase();
        final name = dest.name.toLowerCase();
        final desc = dest.description.toLowerCase();

        if (cat.contains('biển')) {
          return name.contains('nha trang') ||
              name.contains('đà nẵng') ||
              name.contains('hạ long') ||
              desc.contains('biển') ||
              desc.contains('vịnh') ||
              desc.contains('đảo');
        } else if (cat.contains('nghỉ dưỡng')) {
          return name.contains('đà lạt') ||
              name.contains('nha trang') ||
              desc.contains('nghỉ dưỡng') ||
              desc.contains('resort') ||
              desc.contains('spa');
        } else if (cat.contains('cắm trại')) {
          return name.contains('đà lạt') ||
              desc.contains('cắm trại') ||
              desc.contains('núi') ||
              desc.contains('hồ') ||
              desc.contains('rừng');
        } else if (cat.contains('di tích')) {
          return name.contains('huế') ||
              name.contains('hội an') ||
              desc.contains('cổ') ||
              desc.contains('di tích') ||
              desc.contains('lịch sử') ||
              desc.contains('chùa');
        } else if (cat.contains('ẩm thực')) {
          return name.contains('hội an') ||
              name.contains('đà nẵng') ||
              desc.contains('ẩm thực') ||
              desc.contains('ăn') ||
              desc.contains('món');
        } else if (cat.contains('thành phố')) {
          return name.contains('đà nẵng') ||
              desc.contains('thành phố') ||
              desc.contains('phố');
        }
      }

      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Không tìm thấy điểm đến nào phù hợp.',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    // Sort destinations: Hot ones first
    filtered.sort((a, b) {
      if (a.isHot && !b.isHot) return -1;
      if (!a.isHot && b.isHot) return 1;
      return 0;
    });

    final totalCount = filtered.length;
    final displayedDestinations = _showAll
        ? filtered
        : filtered.take(4).toList();

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: displayedDestinations.length,
          itemBuilder: (context, index) {
            final destination = displayedDestinations[index];

            String imageUrl = destination.coverImageUrl.trim();
            if (imageUrl.isEmpty ||
                !imageUrl.startsWith('http') ||
                imageUrl.contains('example.com')) {
              final lowerName = destination.name.toLowerCase();
              if (lowerName.contains('da nang') ||
                  lowerName.contains('đà nẵng')) {
                imageUrl =
                    'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
              } else if (lowerName.contains('hoi an') ||
                  lowerName.contains('hội an')) {
                imageUrl =
                    'https://images.unsplash.com/photo-1588001400947-6385aef4ab0e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
              } else if (lowerName.contains('hue') ||
                  lowerName.contains('huế')) {
                imageUrl =
                    'https://images.unsplash.com/photo-1570710891163-6d3b5c47248b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
              } else if (lowerName.contains('da lat') ||
                  lowerName.contains('đà lạt')) {
                imageUrl =
                    'https://images.unsplash.com/photo-1589308078059-be1415eab4c3?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
              } else if (lowerName.contains('nha trang')) {
                imageUrl =
                    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
              } else if (lowerName.contains('ha long') ||
                  lowerName.contains('hạ long')) {
                imageUrl =
                    'https://images.unsplash.com/photo-1524230507669-e29f7363618d?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
              } else {
                imageUrl =
                    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
              }
            }

            return _DestinationCard(
              title: destination.name,
              imageUrl: imageUrl,
              isHot: destination.isHot,
              onTap: () =>
                  widget.onDestinationTap(destination.name, destination.id),
            );
          },
        ),
        if (totalCount > 4) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _showAll = !_showAll;
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: ExploreColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              icon: Icon(
                _showAll
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
              ),
              label: Text(
                _showAll ? 'Thu gọn' : 'Hiển thị thêm điểm đến',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.title,
    required this.imageUrl,
    required this.isHot,
    required this.onTap,
  });

  final String title;
  final String imageUrl;
  final bool isHot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey,
                    size: 32,
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ExploreColors.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Glassmorphic Bottom Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.explore_outlined,
                                color: Color(0xFF80ED99),
                                size: 14,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Khám phá ngay',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isHot)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFF416C,
                          ).withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'HOT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Community Divider ────────────────────────────────────────────────────────

class _CommunityDivider extends StatelessWidget {
  const _CommunityDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: ExploreColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_alt_rounded,
                  size: 14,
                  color: ExploreColors.primary,
                ),
                SizedBox(width: 6),
                Text(
                  'Cộng đồng chia sẻ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ExploreColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
        ],
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filterState,
    required this.activeFilters,
    required this.onToggle,
    required this.onRemoveCity,
    required this.onOpenFilter,
  });

  final ExploreFilterState filterState;
  final Set<ExploreFilter> activeFilters;
  final ValueChanged<ExploreFilter> onToggle;
  final ValueChanged<String> onRemoveCity;
  final VoidCallback onOpenFilter;

  static const _quickFilters = [
    ExploreFilter.newest,
    ExploreFilter.mostViewed,
    ExploreFilter.topRated,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterIconButton(
            onTap: onOpenFilter,
            hasActiveExtra: _hasExtraFilter(),
          ),
          const SizedBox(width: 8),
          ..._quickFilters.map((f) {
            final isActive = activeFilters.contains(f);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ExploreFilterChip(
                label: context.tr(vi: f.labelVi, en: f.labelEn),
                isActive: isActive,
                onTap: () => onToggle(f),
              ),
            );
          }),
          ...filterState.selectedCities.map((slug) {
            final cityName = _cityName(slug);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ActiveCityChip(
                label: cityName,
                onRemove: () => onRemoveCity(slug),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _cityName(String slug) {
    for (final city in kPopularCities) {
      if (city.slug == slug) return city.name;
    }
    return slug;
  }

  bool _hasExtraFilter() {
    return filterState.selectedCities.isNotEmpty ||
        filterState.prices.isNotEmpty ||
        filterState.minRating != null;
  }
}

class _ActiveCityChip extends StatelessWidget {
  const _ActiveCityChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.only(left: 12, right: 6),
      decoration: BoxDecoration(
        color: ExploreColors.primary,
        borderRadius: BorderRadius.circular(ExploreSpacing.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  const _FilterIconButton({required this.onTap, required this.hasActiveExtra});

  final VoidCallback onTap;
  final bool hasActiveExtra;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: hasActiveExtra ? ExploreColors.chipActiveBg : Colors.white,
              borderRadius: BorderRadius.circular(ExploreSpacing.chipRadius),
              border: Border.all(
                color: hasActiveExtra
                    ? ExploreColors.chipActive
                    : ExploreColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: hasActiveExtra
                      ? ExploreColors.chipActive
                      : ExploreColors.chipInactive,
                ),
                const SizedBox(width: 6),
                Text(
                  'Lọc',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasActiveExtra
                        ? ExploreColors.chipActive
                        : ExploreColors.chipInactive,
                  ),
                ),
              ],
            ),
          ),
          if (hasActiveExtra)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ExploreColors.heartRed,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── States ───────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: CircularProgressIndicator(color: ExploreColors.primary),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 52,
              color: ExploreColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr(
                vi: 'Không tải được bài viết',
                en: 'Could not load posts',
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ExploreColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ExploreColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: ExploreColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr(vi: 'Thử lại', en: 'Try again')),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query, required this.onReset});

  final String query;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 52,
              color: ExploreColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? context.tr(vi: 'Chưa có bài viết nào', en: 'No posts yet')
                  : context.tr(
                      vi: 'Không tìm thấy kết quả',
                      en: 'No results found',
                    ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ExploreColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(
                vi: 'Thử đặt lại bộ lọc hoặc từ khoá khác.',
                en: 'Try resetting filters or a different keyword.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: ExploreColors.textSecondary),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                context.tr(vi: 'Đặt lại bộ lọc', en: 'Reset filters'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ExploreColors.primary,
                side: const BorderSide(color: ExploreColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FAB ─────────────────────────────────────────────────────────────────────

class _CreatePostFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const ExploreCreatePostView(),
          ),
        );
      },
      backgroundColor: ExploreColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.edit_rounded, size: 20),
      label: const Text(
        'Viết bài',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}
