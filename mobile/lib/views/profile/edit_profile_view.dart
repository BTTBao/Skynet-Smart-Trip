import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/widgets.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<ProfileProvider>(context, listen: false).profileData;
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

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70, // Nén ảnh xuống 70% để tiết kiệm băng thông
    );

    if (image != null) {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      final success = await provider.uploadAvatar(image.path);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tải ảnh đại diện thành công!'),
            backgroundColor: Color(0xFF80ed99),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${provider.error ?? "Không thể tải ảnh lên"}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Thay đổi ảnh đại diện',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      
      final currentUser = provider.profileData;
      if (currentUser == null) return;

      final updatedUser = currentUser.copyWith(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        birthDate: _birthDateController.text,
      );

      final success = await provider.updateProfile(updatedUser);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật hồ sơ thành công! (SQL Server)'),
            backgroundColor: Color(0xFF80ed99),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${provider.error ?? "Không thể lưu hồ sơ"}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF80ed99);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Consumer<ProfileProvider>(
            builder: (context, provider, _) {
              if (provider.isUpdating) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                );
              }
              return TextButton(
                onPressed: _saveProfile,
                child: const Text(
                  'Lưu',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ProfileAvatar(
                avatarUrl: Provider.of<ProfileProvider>(context).profileData?.avatarUrl ?? '',
                isEditing: true,
                onCameraTap: _showImagePicker,
              ),
              const SizedBox(height: 32),
              CustomTextField(
                label: 'Họ tên',
                icon: Icons.person_outline,
                controller: _nameController,
                hintText: 'Nhập họ tên của bạn',
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập họ tên';
                  if (value.length < 2) return 'Tên quá ngắn';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Email',
                icon: Icons.mail_outline,
                controller: _emailController,
                hintText: 'example@email.com',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập email';
                  if (!value.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Số điện thoại',
                icon: Icons.phone_android_outlined,
                controller: _phoneController,
                hintText: '0987 654 321',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập số điện thoại';
                  if (value.length < 10) return 'Số điện thoại không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Ngày sinh',
                icon: Icons.calendar_today_outlined,
                controller: _birthDateController,
                hintText: '15/08/1995',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
