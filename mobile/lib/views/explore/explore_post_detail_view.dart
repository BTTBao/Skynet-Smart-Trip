import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/explore_post.dart';
import '../../providers/explore_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/app_text.dart';
import '../../utils/relative_time_formatter.dart';
import 'explore_map_sheet.dart';
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
    _heartScaleAnim =
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
        ]).animate(
          CurvedAnimation(
            parent: _heartAnimController,
            curve: Curves.easeInOut,
          ),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreProvider>().fetchPostDetail(widget.postId);
    });
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
              SliverToBoxAdapter(child: _LocationWidget(post: post)),
              SliverToBoxAdapter(
                child: _CommentsSection(
                  postId: post.id,
                  comments: post.comments,
                  controller: _commentController,
                  onSubmit: provider.addCommentReply,
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
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
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
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.share_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              post.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stackTrace) => Container(
                color: const Color(0xFF1F2937),
                child: const Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: Colors.white30,
                ),
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
        content: Text('Đã sao chép liên kết: ${post.title}'),
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
        color: ExploreColors.primary.withValues(alpha: 0.85),
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
                onBackgroundImageError: (_, exception) {},
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
            errorBuilder: (_, error, stackTrace) => Container(
              height: 160,
              color: const Color(0xFFF3F4F6),
              child: const Icon(
                Icons.image_outlined,
                size: 40,
                color: ExploreColors.textMuted,
              ),
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
  const _LocationWidget({required this.post});

  final ExplorePost post;

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
                color: ExploreColors.primary.withValues(alpha: 0.12),
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
                    post.location,
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
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ExploreMapSheet(post: post),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
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

class _CommentsSection extends StatefulWidget {
  const _CommentsSection({
    required this.postId,
    required this.comments,
    required this.controller,
    required this.onSubmit,
  });

  final int postId;
  final List<ExploreComment> comments;
  final TextEditingController controller;
  final Future<bool> Function({
    required int postId,
    required String content,
    String? imageUrl,
    int? parentCommentId,
  })
  onSubmit;

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  XFile? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _submitComment() async {
    final content = widget.controller.text.trim();
    if (content.isEmpty && _selectedImage == null) return;

    setState(() => _isUploading = true);
    String? imageUrl;

    try {
      if (_selectedImage != null) {
        imageUrl = await context.read<ExploreProvider>().uploadImage(
          _selectedImage!,
        );
      }

      final success = await widget.onSubmit(
        postId: widget.postId,
        content: content,
        imageUrl: imageUrl,
      );

      if (mounted) {
        setState(() {
          _isUploading = false;
          if (success) {
            _selectedImage = null;
            widget.controller.clear();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.trRead(
                vi: success
                    ? 'Bình luận đã được gửi!'
                    : 'Không gửi được bình luận',
                en: success ? 'Comment posted!' : 'Could not post comment',
              ),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi bình luận: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

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
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: ExploreColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr(
                  vi: 'Bình luận (${widget.comments.length})',
                  en: 'Comments (${widget.comments.length})',
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
          ...widget.comments.map(
            (c) => _CommentItem(
              postId: widget.postId,
              comment: c,
              onSubmit: widget.onSubmit,
            ),
          ),
          const SizedBox(height: 12),
          // Thumbnail Preview
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 8),
              child: Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: kIsWeb
                          ? Image.network(
                              _selectedImage!.path,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_selectedImage!.path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: _clearImage,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          // Comment input
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Builder(
                builder: (context) {
                  final profileUrl = context
                      .watch<ProfileProvider>()
                      .profileData
                      ?.avatarUrl;
                  return CircleAvatar(
                    radius: 18,
                    backgroundImage: profileUrl != null && profileUrl.isNotEmpty
                        ? NetworkImage(profileUrl)
                        : null,
                    backgroundColor: const Color(0xFFE5E7EB),
                    child: profileUrl == null || profileUrl.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            size: 20,
                            color: ExploreColors.textMuted,
                          )
                        : null,
                  );
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: ExploreColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: context.tr(
                              vi: 'Thêm bình luận...',
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
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                          color: ExploreColors.textMuted,
                          size: 20,
                        ),
                        onPressed: _isUploading ? null : _pickImage,
                        tooltip: 'Chọn ảnh',
                      ),
                      IconButton(
                        icon: _isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ExploreColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: ExploreColors.primary,
                                size: 18,
                              ),
                        onPressed: _isUploading ? null : _submitComment,
                      ),
                    ],
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

class _CommentItem extends StatefulWidget {
  const _CommentItem({
    required this.postId,
    required this.comment,
    required this.onSubmit,
  });

  final int postId;
  final ExploreComment comment;
  final Future<bool> Function({
    required int postId,
    required String content,
    String? imageUrl,
    int? parentCommentId,
  })
  onSubmit;

  @override
  State<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<_CommentItem> {
  final _replyController = TextEditingController();
  XFile? _replyImage;
  bool _isReplying = false;
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _pickReplyImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null && mounted) {
        setState(() => _replyImage = image);
      }
    } catch (e) {
      debugPrint('Error picking reply image: $e');
    }
  }

  void _clearReplyImage() {
    setState(() => _replyImage = null);
  }

  Future<void> _sendReply() async {
    final content = _replyController.text.trim();
    if ((content.isEmpty && _replyImage == null) || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    var success = false;
    try {
      String? imageUrl;
      if (_replyImage != null) {
        imageUrl = await context.read<ExploreProvider>().uploadImage(
          _replyImage!,
        );
      }

      success = await widget.onSubmit(
        postId: widget.postId,
        content: content,
        imageUrl: imageUrl,
        parentCommentId: widget.comment.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lá»—i gá»­i pháº£n há»“i: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _isSending = false;
      if (success) {
        _isReplying = false;
        _replyImage = null;
        _replyController.clear();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.trRead(
            vi: success ? 'Đã gửi phản hồi' : 'Không gửi được phản hồi',
            en: success ? 'Reply posted' : 'Could not post reply',
          ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          _CommentBubble(comment: comment),
          Padding(
            padding: const EdgeInsets.only(left: 44, top: 4),
            child: Row(
              children: [
                Text(
                  RelativeTimeFormatter.vi(comment.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: ExploreColors.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _isReplying = !_isReplying),
                  child: Text(
                    context.tr(vi: 'Trả lời', en: 'Reply'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ExploreColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 10),
              child: Column(
                children: comment.replies
                    .map((reply) => _ReplyBubble(reply: reply))
                    .toList(),
              ),
            ),
          if (_isReplying)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_replyImage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: kIsWeb
                                ? Image.network(
                                    _replyImage!.path,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_replyImage!.path),
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: _isSending ? null : _clearReplyImage,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          minLines: 1,
                          maxLines: 3,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: context.tr(
                              vi: 'Viết phản hồi...',
                              en: 'Write a reply...',
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: ExploreColors.border,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _isSending ? null : _pickReplyImage,
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                          color: ExploreColors.textMuted,
                        ),
                      ),
                      IconButton(
                        onPressed: _isSending ? null : _sendReply,
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: ExploreColors.primary,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({required this.comment});

  final ExploreComment comment;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundImage: NetworkImage(comment.authorAvatar),
          onBackgroundImageError: (_, exception) {},
          backgroundColor: const Color(0xFFE5E7EB),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
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
                if (comment.content.trim().isNotEmpty) ...[
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
                if (comment.imageUrl != null &&
                    comment.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      comment.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReplyBubble extends StatelessWidget {
  const _ReplyBubble({required this.reply});

  final ExploreComment reply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage(reply.authorAvatar),
            onBackgroundImageError: (_, exception) {},
            backgroundColor: const Color(0xFFE5E7EB),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ExploreColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply.authorName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ExploreColors.textPrimary,
                        ),
                      ),
                      if (reply.content.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          reply.content,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ExploreColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (reply.imageUrl != null &&
                          reply.imageUrl!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            reply.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 3),
                  child: Text(
                    RelativeTimeFormatter.vi(reply.createdAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: ExploreColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Floating Action Bar ──────────────────────────────────────────────────────

class _FloatingActionBar extends StatelessWidget {
  const _FloatingActionBar({required this.post, required this.provider});

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
            color: Colors.black.withValues(alpha: 0.14),
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
            color: post.isLiked
                ? ExploreColors.heartRed
                : ExploreColors.textSecondary,
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
              vi: post.isBookmarked ? 'Đã lưu' : 'Lưu',
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
            label: context.tr(vi: 'Chia sẻ', en: 'Share'),
            color: ExploreColors.textSecondary,
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.trRead(
                      vi: 'Đã sao chép liên kết',
                      en: 'Link copied',
                    ),
                  ),
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
    return Container(width: 1, height: 28, color: ExploreColors.border);
  }
}
