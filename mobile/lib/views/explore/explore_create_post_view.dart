import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/explore_post.dart';
import '../../providers/explore_provider.dart';
import '../../utils/app_text.dart';
import 'explore_ui_constants.dart';

class ExploreCreatePostView extends StatefulWidget {
  const ExploreCreatePostView({super.key});

  @override
  State<ExploreCreatePostView> createState() => _ExploreCreatePostViewState();
}

class _ExploreCreatePostViewState extends State<ExploreCreatePostView> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isBold = false;
  bool _isItalic = false;
  bool _isH1 = false;
  bool _isQuote = false;
  int _selectedCostLevel = 2;
  bool _isPosting = false;

  // Simulated selected photos
  final List<String> _selectedPhotos = [
    'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400',
  ];

  bool get _canPost =>
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty &&
      _locationController.text.trim().isNotEmpty &&
      !_isPosting;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _postPublish() async {
    if (!_canPost) return;
    HapticFeedback.lightImpact();

    setState(() => _isPosting = true);
    final success = await context.read<ExploreProvider>().createPost(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          location: _locationController.text.trim(),
          costLevel: _selectedCostLevel,
          imageUrls: _selectedPhotos,
        );
    if (!mounted) return;
    setState(() => _isPosting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(
          vi: success ? 'Bai viet da duoc dang!' : 'Khong dang duoc bai viet',
          en: success ? 'Post published!' : 'Could not publish post',
        )),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    if (success) {
      Navigator.of(context).maybePop();
    }
  }

  void _addPhoto() {
    // Simulate photo picker
    setState(() {
      _selectedPhotos.add(
        'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=400',
      );
    });
  }

  void _removePhoto(int index) {
    setState(() => _selectedPhotos.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title input
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: TextField(
                      controller: _titleController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: ExploreColors.textPrimary,
                        height: 1.3,
                        fontFamily: 'Georgia',
                      ),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: context.tr(
                          vi: 'Tieu de bai viet...',
                          en: 'Post title...',
                        ),
                        hintStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: ExploreColors.textMuted,
                          fontFamily: 'Georgia',
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const Divider(indent: 20, endIndent: 20, color: ExploreColors.border),
                  // Rich text toolbar
                  _RichTextToolbar(
                    isBold: _isBold,
                    isItalic: _isItalic,
                    isH1: _isH1,
                    isQuote: _isQuote,
                    onBold: () => setState(() => _isBold = !_isBold),
                    onItalic: () => setState(() => _isItalic = !_isItalic),
                    onH1: () => setState(() => _isH1 = !_isH1),
                    onQuote: () => setState(() => _isQuote = !_isQuote),
                    onAddImage: _addPhoto,
                  ),
                  const Divider(height: 1, color: ExploreColors.border),
                  // Content editor
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: TextField(
                      controller: _contentController,
                      onChanged: (_) => setState(() {}),
                      maxLines: null,
                      minLines: 8,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            _isBold ? FontWeight.w700 : FontWeight.normal,
                        fontStyle:
                            _isItalic ? FontStyle.italic : FontStyle.normal,
                        color: ExploreColors.textPrimary,
                        height: 1.7,
                      ),
                      decoration: InputDecoration(
                        hintText: context.tr(
                          vi: 'Chia se trai nghiem cua ban...',
                          en: 'Share your experience...',
                        ),
                        hintStyle: const TextStyle(
                          fontSize: 15,
                          color: ExploreColors.textMuted,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  // Photo grid
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _PhotoGrid(
                      photos: _selectedPhotos,
                      onAdd: _addPhoto,
                      onRemove: _removePhoto,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: ExploreColors.border),
                  // Location picker
                  _LocationPicker(
                    controller: _locationController,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _CostLevelPicker(
                    selectedLevel: _selectedCostLevel,
                    onChanged: (value) => setState(() {
                      _selectedCostLevel = value;
                    }),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: ExploreColors.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Cancel
                TextButton(
                  onPressed: () => _showCancelDialog(context),
                  child: Text(
                    context.tr(vi: 'Huy', en: 'Cancel'),
                    style: const TextStyle(
                      color: ExploreColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Title
                Expanded(
                  child: Text(
                    context.tr(vi: 'Bai viet moi', en: 'New post'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ExploreColors.textPrimary,
                    ),
                  ),
                ),
                // Publish
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _canPost ? 1.0 : 0.4,
                  child: ElevatedButton(
                    onPressed: _canPost ? _postPublish : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ExploreColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                    child: _isPosting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            context.tr(vi: 'Dang', en: 'Post'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr(vi: 'Huy bai viet?', en: 'Discard post?')),
        content: Text(
          context.tr(
            vi: 'Noi dung chua duoc luu se bi mat.',
            en: 'Unsaved content will be lost.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr(vi: 'Tiep tuc viet', en: 'Keep editing')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).maybePop();
            },
            child: Text(
              context.tr(vi: 'Huy bai viet', en: 'Discard'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _CostLevelPicker extends StatelessWidget {
  const _CostLevelPicker({
    required this.selectedLevel,
    required this.onChanged,
  });

  final int selectedLevel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(vi: 'Muc chi phi', en: 'Cost level'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ExploreColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExplorePriceFilter.values.map((filter) {
              final isSelected = selectedLevel == filter.level;
              return ChoiceChip(
                label: Text('${filter.symbol} ${filter.labelVi}'),
                selected: isSelected,
                onSelected: (_) => onChanged(filter.level),
                selectedColor: ExploreColors.chipActiveBg,
                labelStyle: TextStyle(
                  color: isSelected
                      ? ExploreColors.primary
                      : ExploreColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: isSelected ? ExploreColors.primary : ExploreColors.border,
                ),
                backgroundColor: const Color(0xFFF9FAFB),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/*
                    child: Text(
                      context.tr(vi: 'Dang', en: 'Post'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr(vi: 'Huy bai viet?', en: 'Discard post?')),
        content: Text(
          context.tr(
            vi: 'Noi dung chua duoc luu se bi mat.',
            en: 'Unsaved content will be lost.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr(vi: 'Tiep tuc viet', en: 'Keep editing')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).maybePop();
            },
            child: Text(
              context.tr(vi: 'Huy bai viet', en: 'Discard'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Rich Text Toolbar ────────────────────────────────────────────────────────

*/

class _RichTextToolbar extends StatelessWidget {
  const _RichTextToolbar({
    required this.isBold,
    required this.isItalic,
    required this.isH1,
    required this.isQuote,
    required this.onBold,
    required this.onItalic,
    required this.onH1,
    required this.onQuote,
    required this.onAddImage,
  });

  final bool isBold, isItalic, isH1, isQuote;
  final VoidCallback onBold, onItalic, onH1, onQuote, onAddImage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _ToolbarButton(
            label: 'B',
            isActive: isBold,
            onTap: onBold,
            isBold: true,
          ),
          const SizedBox(width: 4),
          _ToolbarButton(
            label: 'I',
            isActive: isItalic,
            onTap: onItalic,
            isItalic: true,
          ),
          const SizedBox(width: 4),
          _ToolbarButton(
            label: 'H1',
            isActive: isH1,
            onTap: onH1,
          ),
          const SizedBox(width: 4),
          _ToolbarIconButton(
            icon: Icons.format_quote_rounded,
            isActive: isQuote,
            onTap: onQuote,
          ),
          const SizedBox(width: 4),
          const _ToolbarDivider(),
          const SizedBox(width: 4),
          _ToolbarIconButton(
            icon: Icons.image_outlined,
            isActive: false,
            onTap: onAddImage,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isBold = false,
    this.isItalic = false,
  });

  final String label;
  final bool isActive, isBold, isItalic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? ExploreColors.chipActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? ExploreColors.primary : ExploreColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            color: isActive ? ExploreColors.primary : ExploreColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? ExploreColors.chipActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? ExploreColors.primary : ExploreColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? ExploreColors.primary : ExploreColors.textSecondary,
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: ExploreColors.border,
    );
  }
}

// ─── Photo Grid ───────────────────────────────────────────────────────────────

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anh (${photos.length})',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ExploreColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: photos.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return GestureDetector(
                onTap: onAdd,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ExploreColors.border,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: ExploreColors.textMuted,
                    size: 24,
                  ),
                ),
              );
            }
            final photoIndex = index - 1;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    photos[photoIndex],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(Icons.image_outlined,
                          color: ExploreColors.textMuted),
                    ),
                  ),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: GestureDetector(
                    onTap: () => onRemove(photoIndex),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 12),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─── Location Picker ──────────────────────────────────────────────────────────

class _LocationPicker extends StatelessWidget {
  const _LocationPicker({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(vi: 'Vi tri', en: 'Location'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ExploreColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ExploreColors.border),
            ),
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              style: const TextStyle(
                fontSize: 14,
                color: ExploreColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: context.tr(
                  vi: 'Nhap ten dia danh...',
                  en: 'Enter location name...',
                ),
                hintStyle: const TextStyle(
                  color: ExploreColors.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.place_outlined,
                  color: ExploreColors.primary,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
