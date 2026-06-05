import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/profile_provider.dart';
import '../../utils/app_text.dart';
import '../../widgets/widgets.dart';
import 'profile_session_helper.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key, this.requiredForBooking = false});

  final bool requiredForBooking;

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _identityController;
  bool _handledSessionExpired = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileProvider>().profileData;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _birthDateController = TextEditingController(text: user?.birthDate ?? '');
    _identityController = TextEditingController(
      text: user?.identityNumber ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _identityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        _handleSessionExpired(provider);

        return WillPopScope(
          onWillPop: () => _confirmLeaveIfNeeded(provider),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleBackNavigation(provider),
              ),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text(
                context.tr(vi: 'Chỉnh sửa hồ sơ', en: 'Edit profile'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                TextButton(
                  onPressed: provider.isUpdating ? null : _saveProfile,
                  child: provider.isUpdating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr(vi: 'Lưu', en: 'Save')),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.requiredForBooking) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7EF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF0D6B42).withOpacity(0.2),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: Color(0xFF0D6B42),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Hoàn tất ngày sinh, CCCD và ảnh mặt trước CCCD để tiếp tục đặt phòng.',
                                style: TextStyle(
                                  color: Color(0xFF0D6B42),
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Center(
                      child: ProfileAvatar(
                        avatarUrl: provider.profileData?.avatarUrl ?? '',
                        isEditing: true,
                        onCameraTap: _showImagePicker,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        context.tr(vi: 'Ảnh đại diện', en: 'Profile photo'),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    CustomTextField(
                      label: context.tr(vi: 'Họ và tên', en: 'Full name'),
                      icon: Icons.person_outline,
                      controller: _nameController,
                      hintText: context.tr(
                        vi: 'Nhập họ và tên',
                        en: 'Enter your full name',
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return context.trRead(
                            vi: 'Vui lòng nhập họ và tên.',
                            en: 'Please enter your full name.',
                          );
                        }
                        if (text.length < 2) {
                          return context.trRead(
                            vi: 'Họ và tên quá ngắn.',
                            en: 'Full name is too short.',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: context.tr(vi: 'Email', en: 'Email'),
                      icon: Icons.mail_outline,
                      controller: _emailController,
                      hintText: context.tr(
                        vi: 'Email dang ky',
                        en: 'Registered email',
                      ),
                      readOnly: true,
                      enabled: false,
                      suffixIcon: Icon(
                        provider.profileData?.isEmailVerified == true
                            ? Icons.verified_outlined
                            : Icons.error_outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        vi: 'Email được khóa để giữ nguyên thông tin xác thực tài khoản.',
                        en: 'Email is locked to preserve account verification.',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: context.tr(vi: 'Số điện thoại', en: 'Phone'),
                      icon: Icons.phone_outlined,
                      controller: _phoneController,
                      hintText: context.tr(
                        vi: 'Nhập số điện thoại',
                        en: 'Enter your phone',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        final raw = (value ?? '').replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        );
                        if (raw.isEmpty) {
                          return context.trRead(
                            vi: 'Vui lòng nhập số điện thoại.',
                            en: 'Please enter your phone number.',
                          );
                        }
                        if (raw.length < 10 || raw.length > 11) {
                          return context.trRead(
                            vi: 'Số điện thoại không hợp lệ.',
                            en: 'Invalid phone number.',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: context.tr(vi: 'Ngày sinh', en: 'Birth date'),
                      icon: Icons.calendar_today_outlined,
                      controller: _birthDateController,
                      hintText: 'YYYY-MM-DD',
                      readOnly: true,
                      onTap: _pickBirthDate,
                      suffixIcon: const Icon(Icons.expand_more),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) {
                          return context.trRead(
                            vi: 'Vui lòng chọn ngày sinh.',
                            en: 'Please select your birth date.',
                          );
                        }
                        final birthDate = _parseBirthDate(text);
                        if (birthDate == null ||
                            !birthDate.isBefore(DateTime.now())) {
                          return context.trRead(
                            vi: 'Ngày sinh không hợp lệ.',
                            en: 'Invalid birth date.',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: context.tr(
                        vi: 'Số CCCD / CMND',
                        en: 'ID Card Number',
                      ),
                      icon: Icons.credit_card_outlined,
                      controller: _identityController,
                      hintText: context.tr(
                        vi: 'Nhập số CCCD hoặc CMND',
                        en: 'Enter your ID card number',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) {
                          return context.trRead(
                            vi: 'Vui lòng nhập số CCCD/CMND.',
                            en: 'Please enter your ID number.',
                          );
                        }
                        if (text.isNotEmpty &&
                            !RegExp(r'^\d+$').hasMatch(text)) {
                          return context.trRead(
                            vi: 'Số CCCD/CMND chỉ được gồm các chữ số.',
                            en: 'ID number must contain digits only.',
                          );
                        }
                        if (text.isNotEmpty &&
                            text.length != 9 &&
                            text.length != 12) {
                          return context.trRead(
                            vi: 'Số CCCD/CMND không hợp lệ (9 hoặc 12 số).',
                            en: 'ID number must be 9 or 12 digits.',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        context.tr(
                          vi: 'Ảnh mặt trước CCCD / CMND',
                          en: 'Front Side of Identity Card',
                        ),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: provider.isUploadingIdentityPhoto
                          ? null
                          : _showIdentityCardPhotoPicker,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF0D6B42).withOpacity(0.3),
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: provider.isUploadingIdentityPhoto
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF0D6B42),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text('Đang tải ảnh lên...'),
                                  ],
                                ),
                              )
                            : (provider.profileData?.identityCardPhotoUrl !=
                                      null &&
                                  provider
                                      .profileData!
                                      .identityCardPhotoUrl!
                                      .isNotEmpty)
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    provider.profileData!.identityCardPhotoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.broken_image_outlined,
                                              color: Colors.redAccent,
                                              size: 40,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              context.tr(
                                              vi: 'Không thể tải ảnh. Chạm để thử lại.',
                                              en: 'Failed to load image. Tap to retry.',
                                              ),
                                              style: const TextStyle(
                                                color: Colors.redAccent,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    right: 10,
                                    bottom: 10,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF0D6B42),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      color: const Color(
                                        0xFF0D6B42,
                                      ).withOpacity(0.8),
                                      size: 40,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      context.tr(
                                      vi: 'Bấm để chụp hoặc chọn ảnh CCCD',
                                        en: 'Tap to take or choose ID card photo',
                                      ),
                                      style: TextStyle(
                                        color: const Color(
                                          0xFF0D6B42,
                                        ).withOpacity(0.8),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      context.tr(
                                        vi: 'Hình ảnh cần rõ ràng, không bị mờ',
                                        en: 'Image must be clear and readable',
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
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
      },
    );
  }

  Future<void> _pickBirthDate() async {
    final initialDate =
        _parseBirthDate(_birthDateController.text) ??
        DateTime(DateTime.now().year - 18, 1, 1);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null) {
      return;
    }

    _birthDateController.text =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseBirthDate(String value) {
    if (value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 75);
    if (image == null) {
      return;
    }

    final provider = context.read<ProfileProvider>();
    final success = await provider.uploadAvatar(image);
    if (!mounted) {
      return;
    }

    if (provider.hasSessionExpired) {
      await _handleSessionExpired(provider);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? context.trRead(
              vi: 'Đã cập nhật ảnh đại diện.',
                  en: 'Profile photo updated.',
                )
              : (provider.error ??
                    context.trRead(
                      vi: 'Không thể tải ảnh lên.',
                      en: 'Unable to upload image.',
                    )),
        ),
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  context.trRead(
                    vi: 'Chọn từ thư viện',
                    en: 'Choose from gallery',
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(
                  context.trRead(vi: 'Chụp ảnh mới', en: 'Take a new photo'),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadIdentityCardPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 75);
    if (image == null) {
      return;
    }

    final provider = context.read<ProfileProvider>();
    final success = await provider.uploadIdentityCardPhoto(image);
    if (!mounted) {
      return;
    }

    if (provider.hasSessionExpired) {
      await _handleSessionExpired(provider);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? context.trRead(
              vi: 'Đã cập nhật ảnh CCCD / CMND.',
                  en: 'Identity card photo updated.',
                )
              : (provider.error ??
                    context.trRead(
                      vi: 'Không thể tải ảnh lên.',
                      en: 'Unable to upload image.',
                    )),
        ),
      ),
    );
  }

  void _showIdentityCardPhotoPicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  context.trRead(
                    vi: 'Chọn từ thư viện',
                    en: 'Choose from gallery',
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUploadIdentityCardPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(
                  context.trRead(vi: 'Chụp ảnh mới', en: 'Take a new photo'),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUploadIdentityCardPhoto(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _hasUnsavedChanges(ProfileProvider provider) {
    final user = provider.profileData;
    if (user == null) {
      return false;
    }

    return _nameController.text.trim() != user.name.trim() ||
        _phoneController.text.trim() != user.phone.trim() ||
        _birthDateController.text.trim() != user.birthDate.trim() ||
        _identityController.text.trim() != (user.identityNumber ?? '').trim();
  }

  Future<void> _handleBackNavigation(ProfileProvider provider) async {
    final shouldPop = await _confirmLeaveIfNeeded(provider);
    if (!mounted || !shouldPop) {
      return;
    }

    Navigator.of(context).pop();
  }

  Future<bool> _confirmLeaveIfNeeded(ProfileProvider provider) async {
    if (provider.isUpdating || !_hasUnsavedChanges(provider)) {
      return true;
    }

    final action = await showDialog<_LeaveAction>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            context.tr(vi: 'Bạn muốn lưu thay đổi?', en: 'Save your changes?'),
          ),
          content: Text(
            context.tr(
              vi: 'Thông tin hồ sơ của bạn đã thay đổi. Bạn muốn lưu trước khi thoát không?',
              en: 'Your profile has unsaved changes. Do you want to save before leaving?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_LeaveAction.cancel);
              },
              child: Text(context.trRead(vi: 'Ở lại', en: 'Stay')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_LeaveAction.discard);
              },
              child: Text(context.trRead(vi: 'Không lưu', en: 'Discard')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_LeaveAction.save);
              },
              child: Text(context.trRead(vi: 'Lưu', en: 'Save')),
            ),
          ],
        );
      },
    );

    switch (action) {
      case _LeaveAction.save:
        await _saveProfile(closeAfterSave: true);
        return false;
      case _LeaveAction.discard:
        return true;
      case _LeaveAction.cancel:
      case null:
        return false;
    }
  }

  Future<void> _saveProfile({bool closeAfterSave = true}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<ProfileProvider>();
    final currentUser = provider.profileData;
    if (currentUser == null) {
      return;
    }

    final updatedUser = currentUser.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      birthDate: _birthDateController.text.trim(),
      identityNumber: _identityController.text.trim().isEmpty
          ? null
          : _identityController.text.trim(),
    );

    final success = await provider.updateProfile(updatedUser);
    if (!mounted) {
      return;
    }

    if (provider.hasSessionExpired) {
      await _handleSessionExpired(provider);
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ??
                context.trRead(
                  vi: 'Không thể cập nhật hồ sơ.',
                  en: 'Unable to update profile.',
                ),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.trRead(vi: 'Đã cập nhật hồ sơ.', en: 'Profile updated.'),
        ),
      ),
    );
    if (closeAfterSave) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _handleSessionExpired(ProfileProvider provider) async {
    if (_handledSessionExpired || !provider.hasSessionExpired || !mounted) {
      return;
    }

    _handledSessionExpired = true;
    await showSessionExpiredDialog(context, message: provider.error);
  }
}

enum _LeaveAction { save, discard, cancel }
