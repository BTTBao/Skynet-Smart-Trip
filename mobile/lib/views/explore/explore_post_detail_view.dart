import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/explore_post.dart';
import '../../providers/explore_provider.dart';
import '../../utils/app_text.dart';
import 'explore_ui_constants.dart';

class ExplorePostDetailView extends StatefulWidget {
  const ExplorePostDetailView({super.key, required this.postId});

  final int postId;

  @override
  State<ExplorePostDetailView> createState() => _ExplorePostDetailViewState();
}

class _ExplorePostDetailViewState extends State<ExplorePostDetailView>
    with SingleTickerProviderStateMixin {
  final _commentController = TextEditingController();
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnim;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heartScaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _heartAnimController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _commentController.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  void _handleDoubleTapLike(ExplorePost post) {
    if (!post.isLiked) {
      context.read<ExploreProvider>().toggleLike(post.id);
    }
    setState(() => _showHeart = true);
    _heartAnimController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, _) {
        final post = provider.getPostById(widget.postId);
        if (post == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildContent(context, post, provider);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ExplorePost post,
    ExploreProvider provider,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            slivers: [
              _DetailSliverAppBar(post: post),
              SliverToBoxAdapter(
                child: GestureDetector(
                  onDoubleTap: () => _handleDoubleTapLike(post),
                  child: _PostBody(post: post),
                ),
              ),
              SliverToBoxAdapter(
                child: _LocationWidget(location: post.location),
              ),
              SliverToBoxAdapter(
                child: _CommentsSection(
                  comments: post.comments,
                  controller: _commentController,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          // Double-tap heart animation
          if (_showHeart)
            Center(
              child: ScaleTransition(
                scale: _heartScaleAnim,
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 100,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black38, blurRadius: 20)],
                ),
              ),
            ),
          // Floating action row (like, bookmark, share)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _FloatingActionBar(post: post, provider: provider),
          ),
        ],
      ),
    );
  }
}

// ─── Sliver App Bar ──────────────────────────────────────────────────────────

class _DetailSliverAppBar extends StatelessWidget {
  const _DetailSliverAppBar({required this.post});

  final ExplorePost post;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.black,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => _sharePost(context, post),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.share_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              post.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF1F2937),
                child: const Icon(Icons.image_outlined,
                    size: 48, color: Colors.white30),
              ),
            ),
            // Gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x55000000), Color(0xDD000000)],
                  stops: [0.3, 1.0],
                ),
              ),
            ),
            // Title overlay
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LocationChip(location: post.location),
                  const SizedBox(height: 8),
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.25,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sharePost(BuildContext context, ExplorePost post) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Da sao chep lien ket: ${post.title}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ExploreColors.primary.withOpacity(0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.place_rounded, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            location,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Post Body (rich text) ────────────────────────────────────────────────────

class _PostBody extends StatelessWidget {
  const _PostBody({required this.post});

  final ExplorePost post;

  @override
  Widget build(BuildContext context) {
    final blocks = _parseContent(post.content);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(post.authorAvatar),
                onBackgroundImageError: (_, __) {},
                backgroundColor: const Color(0xFFE5E7EB),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ExploreColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatDate(post.publishedAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: ExploreColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: ExploreColors.border, height: 1),
          const SizedBox(height: 20),
          // Render content blocks
          ...blocks.map((block) => _buildBlock(block)),
        ],
      ),
    );
  }

  Widget _buildBlock(_ContentBlock block) {
    if (block.isImage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            block.content,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 160,
              color: const Color(0xFFF3F4F6),
              child: const Icon(Icons.image_outlined,
                  size: 40, color: ExploreColors.textMuted),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        block.content,
        style: const TextStyle(
          fontSize: 15,
          color: ExploreColors.textPrimary,
          height: 1.7,
        ),
      ),
    );
  }

  List<_ContentBlock> _parseContent(String content) {
    final lines = content.split('\n');
    final blocks = <_ContentBlock>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('[image:') && trimmed.endsWith(']')) {
        final url = trimmed.substring(7, trimmed.length - 1);
        blocks.add(_ContentBlock(content: url, isImage: true));
      } else {
        blocks.add(_ContentBlock(content: trimmed, isImage: false));
      }
    }
    return blocks;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ContentBlock {
  final String content;
  final bool isImage;

  const _ContentBlock({required this.content, required this.isImage});
}

// ─── Location Widget ──────────────────────────────────────────────────────────

class _LocationWidget extends StatelessWidget {
  const _LocationWidget({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ExploreColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.map_outlined,
                color: ExploreColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(vi: 'Vi tri', en: 'Location'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: ExploreColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ExploreColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr(vi: 'Dang mo ban do...', en: 'Opening map...'),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: ExploreColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  context.tr(vi: 'Xem ban do', en: 'View map'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Comments Section ─────────────────────────────────────────────────────────

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.comments,
    required this.controller,
  });

  final List<ExploreComment> comments;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: ExploreColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 18, color: ExploreColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                context.tr(
                  vi: 'Binh luan (${comments.length})',
                  en: 'Comments (${comments.length})',
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ExploreColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...comments.map((c) => _CommentItem(comment: c)),
          const SizedBox(height: 12),
          // Comment input
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFE5E7EB),
                child: Icon(Icons.person_rounded,
                    size: 20, color: ExploreColors.textMuted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: ExploreColors.border),
                  ),
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: context.tr(
                        vi: 'Them binh luan...',
                        en: 'Add a comment...',
                      ),
                      hintStyle: const TextStyle(
                        color: ExploreColors.textMuted,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded,
                            color: ExploreColors.primary, size: 18),
                        onPressed: () {
                          if (controller.text.trim().isEmpty) return;
                          controller.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.tr(
                                vi: 'Binh luan da duoc gui!',
                                en: 'Comment posted!',
                              )),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  const _CommentItem({required this.comment});

  final ExploreComment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundImage: NetworkImage(comment.authorAvatar),
            onBackgroundImageError: (_, __) {},
            backgroundColor: const Color(0xFFE5E7EB),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.authorName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ExploreColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.content,
                        style: const TextStyle(
                          fontSize: 13,
                          color: ExploreColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Row(
                    children: [
                      Text(
                        _formatDate(comment.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: ExploreColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Icon(Icons.favorite_border_rounded,
                              size: 12, color: ExploreColors.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            '${comment.likes}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: ExploreColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 1) return '${diff.inMinutes} phut truoc';
    if (diff.inDays == 0) return '${diff.inHours} gio truoc';
    if (diff.inDays == 1) return 'Hom qua';
    return '${diff.inDays} ngay truoc';
  }
}

// ─── Floating Action Bar ──────────────────────────────────────────────────────

class _FloatingActionBar extends StatelessWidget {
  const _FloatingActionBar({
    required this.post,
    required this.provider,
  });

  final ExplorePost post;
  final ExploreProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Like button
          _ActionButton(
            icon: post.isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: '${post.likes}',
            color: post.isLiked ? ExploreColors.heartRed : ExploreColors.textSecondary,
            onTap: () {
              HapticFeedback.lightImpact();
              provider.toggleLike(post.id);
            },
          ),
          const _Divider(),
          // View count
          _ActionButton(
            icon: Icons.visibility_rounded,
            label: _formatCount(post.views),
            color: ExploreColors.textSecondary,
            onTap: null,
          ),
          const _Divider(),
          // Bookmark
          _ActionButton(
            icon: post.isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: context.tr(
              vi: post.isBookmarked ? 'Da luu' : 'Luu',
              en: post.isBookmarked ? 'Saved' : 'Save',
            ),
            color: post.isBookmarked
                ? const Color(0xFFFBBF24)
                : ExploreColors.textSecondary,
            onTap: () {
              HapticFeedback.lightImpact();
              provider.toggleBookmark(post.id);
            },
          ),
          const _Divider(),
          // Share
          _ActionButton(
            icon: Icons.share_rounded,
            label: context.tr(vi: 'Chia se', en: 'Share'),
            color: ExploreColors.textSecondary,
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr(
                    vi: 'Da sao chep lien ket',
                    en: 'Link copied',
                  )),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: ExploreColors.border,
    );
  }
}
