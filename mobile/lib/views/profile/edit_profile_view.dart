import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/profile_provider.dart';
import '../../utils/app_text.dart';
import '../../widgets/widgets.dart';
import 'profile_session_helper.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthDateController;
  bool _handledSessionExpired = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileProvider>().profileData;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _birthDateController = TextEditingController(text: user?.birthDate ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
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
                context.tr(vi: 'Chinh sua ho so', en: 'Edit profile'),
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
                      : Text(context.tr(vi: 'Luu', en: 'Save')),
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
                        context.tr(vi: 'Anh dai dien', en: 'Profile photo'),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    CustomTextField(
                      label: context.tr(vi: 'Ho va ten', en: 'Full name'),
                      icon: Icons.person_outline,
                      controller: _nameController,
                      hintText: context.tr(vi: 'Nhap ho va ten', en: 'Enter your full name'),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return context.trRead(
                            vi: 'Vui long nhap ho va ten.',
                            en: 'Please enter your full name.',
                          );
                        }
                        if (text.length < 2) {
                          return context.trRead(
                            vi: 'Ho va ten qua ngan.',
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
                      hintText: context.tr(vi: 'Email dang ky', en: 'Registered email'),
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
                        vi: 'Email duoc khoa de giu nguyen thong tin xac thuc tai khoan.',
                        en: 'Email is locked to preserve account verification.',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: context.tr(vi: 'So dien thoai', en: 'Phone'),
                      icon: Icons.phone_outlined,
                      controller: _phoneController,
                      hintText: context.tr(vi: 'Nhap so dien thoai', en: 'Enter your phone'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        final raw = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                        if (raw.isEmpty) {
                          return context.trRead(
                            vi: 'Vui long nhap so dien thoai.',
                            en: 'Please enter your phone number.',
                          );
                        }
                        if (raw.length < 10 || raw.length > 11) {
                          return context.trRead(
                            vi: 'So dien thoai khong hop le.',
                            en: 'Invalid phone number.',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: context.tr(vi: 'Ngay sinh', en: 'Birth date'),
                      icon: Icons.calendar_today_outlined,
                      controller: _birthDateController,
                      hintText: 'YYYY-MM-DD',
                      readOnly: true,
                      onTap: _pickBirthDate,
                      suffixIcon: const Icon(Icons.expand_more),
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
    final initialDate = _parseBirthDate(_birthDateController.text) ??
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
    final success = await provider.uploadAvatar(image.path);
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
                  vi: 'Da cap nhat anh dai dien.',
                  en: 'Profile photo updated.',
                )
              : (provider.error ??
                  context.trRead(
                    vi: 'Khong the tai anh len.',
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
                title: Text(context.trRead(vi: 'Chon tu thu vien', en: 'Choose from gallery')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(context.trRead(vi: 'Chup anh moi', en: 'Take a new photo')),
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

  bool _hasUnsavedChanges(ProfileProvider provider) {
    final user = provider.profileData;
    if (user == null) {
      return false;
    }

    return _nameController.text.trim() != user.name.trim() ||
        _phoneController.text.trim() != user.phone.trim() ||
        _birthDateController.text.trim() != (user.birthDate ?? '').trim();
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
            context.tr(
              vi: 'Ban muon luu thay doi?',
              en: 'Save your changes?',
            ),
          ),
          content: Text(
            context.tr(
              vi: 'Thong tin ho so cua ban da thay doi. Ban muon luu truoc khi thoat khong?',
              en: 'Your profile has unsaved changes. Do you want to save before leaving?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_LeaveAction.cancel);
              },
              child: Text(context.trRead(vi: 'O lai', en: 'Stay')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_LeaveAction.discard);
              },
              child: Text(context.trRead(vi: 'Khong luu', en: 'Discard')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_LeaveAction.save);
              },
              child: Text(context.trRead(vi: 'Luu', en: 'Save')),
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
                  vi: 'Khong the cap nhat ho so.',
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
          context.trRead(vi: 'Da cap nhat ho so.', en: 'Profile updated.'),
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
