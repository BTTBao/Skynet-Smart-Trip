import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/explore_post.dart';
import '../../providers/explore_provider.dart';
import '../../utils/app_text.dart';
import 'explore_ui_constants.dart';
import 'widgets/explore_filter_chips.dart';
import 'widgets/explore_post_card.dart';
import 'explore_create_post_view.dart';
import 'explore_filter_view.dart';
import 'explore_post_detail_view.dart';

class ExploreView extends StatefulWidget {
  const ExploreView({super.key});

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreProvider>().fetchPosts();
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
      MaterialPageRoute(
        builder: (_) => ExplorePostDetailView(postId: post.id),
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExploreColors.background,
      body: SafeArea(
        child: Consumer<ExploreProvider>(
          builder: (context, provider, _) {
            return RefreshIndicator(
              color: ExploreColors.primary,
              onRefresh: () => provider.fetchPosts(forceRefresh: true),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _ExploreHeader(
                      searchController: _searchController,
                      isFocused: _searchFocused,
                      onFocusChange: (v) => setState(() => _searchFocused = v),
                      onSearch: provider.setSearchQuery,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _FilterBar(
                      filterState: provider.filterState,
                      activeFilters: provider.activeFilters,
                      onToggle: provider.toggleFilter,
                      onOpenFilter: _openFilterSheet,
                    ),
                  ),
                  if (provider.isLoading)
                    const SliverFillRemaining(
                      child: _LoadingState(),
                    )
                  else if (provider.error != null && provider.posts.isEmpty)
                    SliverFillRemaining(
                      child: _ErrorState(
                        message: provider.error!,
                        onRetry: () => provider.fetchPosts(forceRefresh: true),
                      ),
                    )
                  else if (provider.posts.isEmpty)
                    SliverFillRemaining(
                      child: _EmptyState(
                        query: provider.searchQuery,
                        onReset: provider.resetFilters,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = provider.posts[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: ExplorePostCard(
                                post: post,
                                onTap: () => _openPostDetail(post),
                                onLike: () => provider.toggleLike(post.id),
                              ),
                            );
                          },
                          childCount: provider.posts.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: _CreatePostFab(),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _ExploreHeader extends StatelessWidget {
  const _ExploreHeader({
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
                        vi: 'Những điểm đến tuyệt vời dành cho bạn.',
                        en: 'Amazing destinations for you.',
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: ExploreColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Skynet compass icon badge
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
          // Search bar
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
                    color: Colors.black.withOpacity(0.05),
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
                    vi: 'Tìm địa danh, điểm đến...',
                    en: 'Search destinations...',
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

// ─── Filter Bar ──────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filterState,
    required this.activeFilters,
    required this.onToggle,
    required this.onOpenFilter,
  });

  final ExploreFilterState filterState;
  final Set<ExploreFilter> activeFilters;
  final ValueChanged<ExploreFilter> onToggle;
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
          _FilterIconButton(onTap: onOpenFilter, hasActiveExtra: _hasExtraFilter()),
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
        ],
      ),
    );
  }

  bool _hasExtraFilter() {
    // Badge đỏ khi có city, price hoặc rating đang active
    return filterState.selectedCities.isNotEmpty ||
        filterState.prices.isNotEmpty ||
        filterState.minRating != null;
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
              color: hasActiveExtra
                  ? ExploreColors.chipActiveBg
                  : Colors.white,
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

// ─── States ──────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: ExploreColors.primary),
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
            const Icon(Icons.wifi_off_rounded, size: 52, color: ExploreColors.textMuted),
            const SizedBox(height: 16),
            Text(
              context.tr(vi: 'Không tải được bài viết', en: 'Could not load posts'),
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
            const Icon(Icons.search_off_rounded, size: 52, color: ExploreColors.textMuted),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? context.tr(vi: 'Chưa có bài viết nào', en: 'No posts yet')
                  : context.tr(vi: 'Không tìm thấy kết quả', en: 'No results found'),
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
              label: Text(context.tr(vi: 'Đặt lại bộ lọc', en: 'Reset filters')),
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


