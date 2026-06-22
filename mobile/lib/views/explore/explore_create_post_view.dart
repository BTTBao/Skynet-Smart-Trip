import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/explore_post.dart';
import '../../providers/explore_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/openstreetmap_geocoding_service.dart';
import '../../utils/app_text.dart';
import 'explore_ui_constants.dart';

class ExploreCreatePostView extends StatefulWidget {
  const ExploreCreatePostView({super.key});

  @override
  State<ExploreCreatePostView> createState() => _ExploreCreatePostViewState();
}

class _ExploreCreatePostViewState extends State<ExploreCreatePostView> {
  static const _geocoding = OpenStreetMapGeocodingService();

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final _tripCodeController = TextEditingController();
  final _picker = ImagePicker();

  final List<XFile> _selectedPhotos = [];
  final List<Uint8List> _selectedPhotoBytes = [];
  bool _isBold = false;
  bool _isItalic = false;
  bool _isH1 = false;
  bool _isQuote = false;
  int _selectedCostLevel = 2;
  bool _isPosting = false;
  bool _isResolvingLocation = false;
  String? _errorText;
  String? _progressText;
  double? _latitude;
  double? _longitude;

  bool _isValidatingTripCode = false;
  String? _validatedTripTitle;
  String? _tripCodeError;

  bool get _canPost =>
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty &&
      _locationController.text.trim().isNotEmpty &&
      !_isPosting &&
      !_isValidatingTripCode;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _tripCodeController.dispose();
    super.dispose();
  }

  Future<void> _validateTripCode(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) {
      setState(() {
        _validatedTripTitle = null;
        _tripCodeError = null;
      });
      return;
    }

    setState(() {
      _isValidatingTripCode = true;
      _tripCodeError = null;
      _validatedTripTitle = null;
    });

    try {
      final tripProvider = context.read<TripProvider>();
      final trip = await tripProvider.fetchSharedTripDetail(cleanCode);
      if (!mounted) return;
      if (trip != null) {
        setState(() {
          _validatedTripTitle = trip.title;
          _tripCodeError = null;
        });
      } else {
        setState(() {
          _tripCodeError = 'Mã lịch trình không hợp lệ hoặc không tồn tại.';
          _validatedTripTitle = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tripCodeError = 'Mã lịch trình không hợp lệ hoặc không tồn tại.';
          _validatedTripTitle = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isValidatingTripCode = false;
        });
      }
    }
  }

  Future<void> _pickPhotos() async {
    try {
      final images = await _picker.pickMultiImage(
        maxWidth: 1600,
        imageQuality: 86,
      );
      if (images.isEmpty || !mounted) {
        return;
      }

      final remainingSlots = 10 - _selectedPhotos.length;
      final addedImages = images.take(remainingSlots).toList();
      
      final List<Uint8List> addedBytes = [];
      for (final img in addedImages) {
        final bytes = await img.readAsBytes();
        addedBytes.add(bytes);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedPhotos.addAll(addedImages);
        _selectedPhotoBytes.addAll(addedBytes);
        _errorText = images.length > remainingSlots
            ? context.trRead(
                vi: 'Mỗi bài viết tối đa 10 ảnh.',
                en: 'Each post can contain up to 10 photos.',
              )
            : null;
      });
    } catch (error) {
      _showError('Không mở được thư viện ảnh: $error');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
      _selectedPhotoBytes.removeAt(index);
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isResolvingLocation = true;
      _errorText = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _showError('GPS đang tắt. Bạn vẫn có thể nhập vị trí thủ công.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showError('Bạn chưa cấp quyền vị trí. Hãy nhập vị trí thủ công.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final latLng = LatLng(position.latitude, position.longitude);
      final label = await _geocoding.reverseGeocode(latLng);
      if (!mounted) {
        return;
      }

      setState(() {
        _latitude = latLng.latitude;
        _longitude = latLng.longitude;
        _locationController.text = label ?? 'Vị trí hiện tại';
        _errorText = null;
      });
    } catch (error) {
      _showError('Không lấy được vị trí hiện tại. Hãy nhập thủ công.');
    } finally {
      if (mounted) {
        setState(() => _isResolvingLocation = false);
      }
    }
  }

  Future<void> _postPublish() async {
    final validationError = _validate();
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _isPosting = true;
      _errorText = null;
      _progressText = context.trRead(
        vi: 'Đang chuẩn bị bài viết...',
        en: 'Preparing post...',
      );
    });

    try {
      final provider = context.read<ExploreProvider>();
      final imageUrls = <String>[];

      for (var i = 0; i < _selectedPhotos.length; i++) {
        if (!mounted) {
          return;
        }

        setState(() {
          _progressText = 'Đang tải ảnh ${i + 1}/${_selectedPhotos.length}...';
        });
        imageUrls.add(await provider.uploadImage(_selectedPhotos[i]));
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _progressText = context.trRead(vi: 'Đang đăng bài...', en: 'Publishing...');
      });

      final success = await provider.createPost(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        location: _locationController.text.trim(),
        costLevel: _selectedCostLevel,
        imageUrls: imageUrls,
        latitude: _latitude,
        longitude: _longitude,
        linkedTripCode: _tripCodeController.text.trim().isNotEmpty && _validatedTripTitle != null
            ? _tripCodeController.text.trim()
            : null,
      );

      if (!mounted) {
        return;
      }

      if (!success) {
        _showError(provider.error ?? 'Không đăng được bài viết.');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.trRead(vi: 'Bài viết đã được đăng!', en: 'Post published!'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).maybePop();
    } catch (error) {
      if (mounted) {
        _showError(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
          _progressText = null;
        });
      }
    }
  }

  String? _validate() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final location = _locationController.text.trim();
    final tripCode = _tripCodeController.text.trim();

    if (title.length < 5) {
      return 'Tiêu đề cần ít nhất 5 ký tự.';
    }

    if (content.length < 10) {
      return 'Nội dung cần ít nhất 10 ký tự.';
    }

    if (location.length < 2) {
      return 'Vui lòng nhập vị trí hoặc dùng vị trí hiện tại.';
    }

    if (tripCode.isNotEmpty && _validatedTripTitle == null) {
      return 'Mã lịch trình chưa được xác thực hoặc không hợp lệ. Vui lòng kiểm tra lại hoặc xóa mã.';
    }

    return null;
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _errorText = message;
      _isResolvingLocation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          if (_errorText != null)
            _InlineNotice(text: _errorText!, isError: true)
          else if (_progressText != null)
            _InlineNotice(text: _progressText!, isError: false),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          vi: 'Tiêu đề bài viết...',
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
                  const Divider(
                    indent: 20,
                    endIndent: 20,
                    color: ExploreColors.border,
                  ),
                  _RichTextToolbar(
                    isBold: _isBold,
                    isItalic: _isItalic,
                    isH1: _isH1,
                    isQuote: _isQuote,
                    onBold: () => setState(() => _isBold = !_isBold),
                    onItalic: () => setState(() => _isItalic = !_isItalic),
                    onH1: () => setState(() => _isH1 = !_isH1),
                    onQuote: () => setState(() => _isQuote = !_isQuote),
                    onAddImage: _pickPhotos,
                  ),
                  const Divider(height: 1, color: ExploreColors.border),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: TextField(
                      controller: _contentController,
                      onChanged: (_) => setState(() {}),
                      maxLines: null,
                      minLines: 8,
                      style: TextStyle(
                        fontSize: _isH1 ? 18 : 15,
                        fontWeight: _isBold || _isH1
                            ? FontWeight.w700
                            : FontWeight.normal,
                        fontStyle: _isItalic
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: ExploreColors.textPrimary,
                        height: 1.7,
                      ),
                      decoration: InputDecoration(
                        hintText: context.tr(
                          vi: 'Chia sẻ trải nghiệm của bạn...',
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _PhotoGrid(
                      photos: _selectedPhotos,
                      photoBytes: _selectedPhotoBytes,
                      onAdd: _pickPhotos,
                      onRemove: _removePhoto,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: ExploreColors.border),
                  _LocationPicker(
                    controller: _locationController,
                    isResolving: _isResolvingLocation,
                    hasGps: _latitude != null && _longitude != null,
                    onChanged: () => setState(() {
                      _latitude = null;
                      _longitude = null;
                    }),
                    onUseCurrentLocation: _useCurrentLocation,
                  ),
                  const SizedBox(height: 16),
                  _CostLevelPicker(
                    selectedLevel: _selectedCostLevel,
                    onChanged: (value) => setState(() {
                      _selectedCostLevel = value;
                    }),
                  ),
                  const SizedBox(height: 16),
                  _TripCodeField(
                    controller: _tripCodeController,
                    isValidating: _isValidatingTripCode,
                    validatedTitle: _validatedTripTitle,
                    errorText: _tripCodeError,
                    onChanged: (val) {
                      if (val.trim().isEmpty) {
                        setState(() {
                          _validatedTripTitle = null;
                          _tripCodeError = null;
                        });
                      }
                    },
                    onValidate: () => _validateTripCode(_tripCodeController.text),
                  ),
                  const SizedBox(height: 28),
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
                TextButton(
                  onPressed: _isPosting
                      ? null
                      : () => _showCancelDialog(context),
                  child: Text(
                    context.tr(vi: 'Hủy', en: 'Cancel'),
                    style: const TextStyle(
                      color: ExploreColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    context.tr(vi: 'Bài viết mới', en: 'New post'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ExploreColors.textPrimary,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _canPost ? 1.0 : 0.45,
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
                            context.tr(vi: 'Đăng', en: 'Post'),
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
        title: Text(ctx.trRead(vi: 'Hủy bài viết?', en: 'Discard post?')),
        content: Text(
          ctx.trRead(
            vi: 'Nội dung chưa được lưu sẽ bị mất.',
            en: 'Unsaved content will be lost.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.trRead(vi: 'Tiếp tục viết', en: 'Keep editing')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).maybePop();
            },
            child: Text(
              ctx.trRead(vi: 'Hủy bài viết', en: 'Discard'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red.shade700 : ExploreColors.primary;
    final bg = isError ? Colors.red.shade50 : const Color(0xFFF0FDF4);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.cloud_upload_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
          _ToolbarButton(label: 'B', isActive: isBold, onTap: onBold),
          const SizedBox(width: 4),
          _ToolbarButton(label: 'I', isActive: isItalic, onTap: onItalic),
          const SizedBox(width: 4),
          _ToolbarButton(label: 'H1', isActive: isH1, onTap: onH1),
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
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ToolbarShell(
      isActive: isActive,
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: isActive ? ExploreColors.primary : ExploreColors.textSecondary,
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
    return _ToolbarShell(
      isActive: isActive,
      onTap: onTap,
      child: Icon(
        icon,
        size: 18,
        color: isActive ? ExploreColors.primary : ExploreColors.textSecondary,
      ),
    );
  }
}

class _ToolbarShell extends StatelessWidget {
  const _ToolbarShell({
    required this.isActive,
    required this.onTap,
    required this.child,
  });

  final bool isActive;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? ExploreColors.chipActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? ExploreColors.primary : ExploreColors.border,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 24, color: ExploreColors.border);
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.photos,
    required this.photoBytes,
    required this.onAdd,
    required this.onRemove,
  });

  final List<XFile> photos;
  final List<Uint8List> photoBytes;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ảnh (${photos.length})',
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
                    border: Border.all(color: ExploreColors.border),
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
                  child: Image.memory(
                    photoBytes[photoIndex],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
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
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
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

class _LocationPicker extends StatelessWidget {
  const _LocationPicker({
    required this.controller,
    required this.isResolving,
    required this.hasGps,
    required this.onChanged,
    required this.onUseCurrentLocation,
  });

  final TextEditingController controller;
  final bool isResolving;
  final bool hasGps;
  final VoidCallback onChanged;
  final VoidCallback onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.tr(vi: 'Vị trí', en: 'Location'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ExploreColors.textSecondary,
                ),
              ),
              if (hasGps) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 15,
                  color: ExploreColors.primary,
                ),
              ],
            ],
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
                  vi: 'Nhập tên địa danh...',
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
                suffixIcon: TextButton.icon(
                  onPressed: isResolving ? null : onUseCurrentLocation,
                  icon: isResolving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded, size: 16),
                  label: Text(context.tr(vi: 'GPS', en: 'GPS')),
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
            context.tr(vi: 'Mức chi phí', en: 'Cost level'),
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
                  color: isSelected
                      ? ExploreColors.primary
                      : ExploreColors.border,
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

class _TripCodeField extends StatelessWidget {
  const _TripCodeField({
    required this.controller,
    required this.isValidating,
    required this.validatedTitle,
    required this.errorText,
    required this.onChanged,
    required this.onValidate,
  });

  final TextEditingController controller;
  final bool isValidating;
  final String? validatedTitle;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(vi: 'Gắn mã lịch trình (Tùy chọn)', en: 'Link Trip Itinerary (Optional)'),
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
              border: Border.all(
                color: errorText != null
                    ? Colors.red.shade300
                    : (validatedTitle != null ? ExploreColors.primary : ExploreColors.border),
              ),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 14,
                color: ExploreColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: context.tr(
                  vi: 'Nhập mã chuyến đi (Ví dụ: TRIP-XXXX)...',
                  en: 'Enter trip code (e.g. TRIP-XXXX)...',
                ),
                hintStyle: const TextStyle(
                  color: ExploreColors.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.map_outlined,
                  color: validatedTitle != null ? ExploreColors.primary : ExploreColors.textMuted,
                  size: 20,
                ),
                suffixIcon: TextButton(
                  onPressed: isValidating ? null : onValidate,
                  child: isValidating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: ExploreColors.primary),
                        )
                      : Text(
                          context.tr(vi: 'Kiểm tra', en: 'Verify'),
                          style: const TextStyle(
                            color: ExploreColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                errorText!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ] else if (validatedTitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: ExploreColors.primary,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      context.tr(
                        vi: 'Liên kết thành công: $validatedTitle',
                        en: 'Linked successfully: $validatedTitle',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: ExploreColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
