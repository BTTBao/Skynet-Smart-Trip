import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/profile_provider.dart';
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

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'Chinh sua ho so',
              style: TextStyle(fontWeight: FontWeight.bold),
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
                    : const Text('Luu'),
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
                      'Anh dai dien',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  CustomTextField(
                    label: 'Ho va ten',
                    icon: Icons.person_outline,
                    controller: _nameController,
                    hintText: 'Nhap ho va ten',
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'Vui long nhap ho va ten.';
                      }
                      if (text.length < 2) {
                        return 'Ho va ten qua ngan.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Email',
                    icon: Icons.mail_outline,
                    controller: _emailController,
                    hintText: 'Email dang ky',
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
                    'Email duoc khoa de giu nguyen thong tin xac thuc tai khoan.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'So dien thoai',
                    icon: Icons.phone_outlined,
                    controller: _phoneController,
                    hintText: 'Nhap so dien thoai',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      final raw = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                      if (raw.isEmpty) {
                        return 'Vui long nhap so dien thoai.';
                      }
                      if (raw.length < 10 || raw.length > 11) {
                        return 'So dien thoai khong hop le.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Ngay sinh',
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
              ? 'Da cap nhat anh dai dien.'
              : (provider.error ?? 'Khong the tai anh len.'),
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
                title: const Text('Chon tu thu vien'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Chup anh moi'),
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

  Future<void> _saveProfile() async {
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
          content: Text(provider.error ?? 'Khong the cap nhat ho so.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Da cap nhat ho so.')),
    );
    Navigator.pop(context, true);
  }

  Future<void> _handleSessionExpired(ProfileProvider provider) async {
    if (_handledSessionExpired || !provider.hasSessionExpired || !mounted) {
      return;
    }

    _handledSessionExpired = true;
    await showSessionExpiredDialog(context, message: provider.error);
  }
}
