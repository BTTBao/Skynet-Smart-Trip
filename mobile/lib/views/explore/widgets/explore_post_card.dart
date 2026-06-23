import 'package:flutter/material.dart';

import '../../../models/explore_post.dart';
import '../../../widgets/app_network_image.dart';
import '../explore_ui_constants.dart';

class ExplorePostCard extends StatelessWidget {
  const ExplorePostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onLike,
  });

  final ExplorePost post;
  final VoidCallback onTap;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ExploreColors.cardSurface,
          borderRadius: BorderRadius.circular(ExploreSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ThumbnailSection(post: post, onLike: onLike),
            _MetaSection(post: post),
          ],
        ),
      ),
    );
  }
}

// ─── Thumbnail with gradient overlay ─────────────────────────────────────────

class _ThumbnailSection extends StatelessWidget {
  const _ThumbnailSection({required this.post, required this.onLike});

  final ExplorePost post;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Thumbnail image
        SizedBox(
          height: 220,
          width: double.infinity,
          child: AppNetworkImage(
            imageUrl: post.thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFE5E7EB),
              child: const Icon(
                Icons.image_outlined,
                size: 48,
                color: ExploreColors.textMuted,
              ),
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                color: const Color(0xFFF3F4F6),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: ExploreColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          ),
        ),
        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 130,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xEE000000), Colors.transparent],
                stops: [0, 1],
              ),
            ),
          ),
        ),
        // Location tag
        Positioned(
          top: 12,
          left: 12,
          child: _LocationTag(location: post.location),
        ),
        // Bookmark button
        Positioned(
          top: 8,
          right: 8,
          child: _BookmarkBadge(isBookmarked: post.isBookmarked),
        ),
        // Title overlay at bottom
        Positioned(
          bottom: 12,
          left: 14,
          right: 14,
          child: Text(
            post.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ExploreTextStyles.postTitle,
          ),
        ),
      ],
    );
  }
}

class _LocationTag extends StatelessWidget {
  const _LocationTag({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ExploreColors.primary.withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.place_rounded,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(location, style: ExploreTextStyles.locationTag),
        ],
      ),
    );
  }
}

class _BookmarkBadge extends StatelessWidget {
  const _BookmarkBadge({required this.isBookmarked});

  final bool isBookmarked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
        color: isBookmarked ? const Color(0xFFFBBF24) : Colors.white,
        size: 18,
      ),
    );
  }
}

// ─── Meta section ─────────────────────────────────────────────────────────────

class _MetaSection extends StatelessWidget {
  const _MetaSection({required this.post});

  final ExplorePost post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.excerpt,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: ExploreColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Author avatar
              CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(post.authorAvatar),
                onBackgroundImageError: (_, __) {},
                backgroundColor: const Color(0xFFE5E7EB),
              ),
              const SizedBox(width: 8),
              // Author name + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ExploreColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatDate(post.publishedAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: ExploreColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Like count
              _StatBadge(
                icon: Icons.favorite_rounded,
                count: post.likes,
                isActive: post.isLiked,
                activeColor: ExploreColors.heartRed,
              ),
              const SizedBox(width: 10),
              // View count
              _StatBadge(
                icon: Icons.visibility_rounded,
                count: post.views,
                isActive: false,
                activeColor: ExploreColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Hom nay';
    if (diff.inDays == 1) return 'Hom qua';
    if (diff.inDays < 7) return '${diff.inDays} ngay truoc';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuan truoc';
    return '${(diff.inDays / 30).floor()} thang truoc';
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.count,
    required this.isActive,
    required this.activeColor,
  });

  final IconData icon;
  final int count;
  final bool isActive;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isActive ? activeColor : ExploreColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          _formatCount(count),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? activeColor : ExploreColors.textMuted,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}
