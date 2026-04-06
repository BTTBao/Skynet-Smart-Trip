import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/profile_provider.dart';
import '../../widgets/auth/auth_widgets.dart';
import 'profile_session_helper.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _inlineError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _inlineError = null);

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() => _inlineError = 'Vui lòng nhập đầy đủ thông tin.');
      return;
    }

    if (newPassword.length < 8) {
      setState(() => _inlineError = 'Mật khẩu mới phải có ít nhất 8 ký tự.');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _inlineError = 'Xác nhận mật khẩu mới không khớp.');
      return;
    }

    final provider = context.read<ProfileProvider>();
    final success = await provider.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmNewPassword: confirmPassword,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      await showSessionExpiredDialog(
        context,
        message: 'Đổi mật khẩu thành công. Vui lòng đăng nhập lại.',
      );
      return;
    }

    if (provider.hasSessionExpired) {
      await showSessionExpiredDialog(context, message: provider.error);
      return;
    }

    setState(() => _inlineError = provider.error ?? 'Đổi mật khẩu thất bại.');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ProfileProvider>().isChangingPassword;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _PasswordField(
              controller: _currentPasswordController,
              label: 'Mật khẩu hiện tại',
              obscureText: !_showCurrentPassword,
              onToggle: () => setState(
                () => _showCurrentPassword = !_showCurrentPassword,
              ),
            ),
            const SizedBox(height: 16),
            _PasswordField(
              controller: _newPasswordController,
              label: 'Mật khẩu mới',
              obscureText: !_showNewPassword,
              onToggle: () =>
                  setState(() => _showNewPassword = !_showNewPassword),
            ),
            const SizedBox(height: 16),
            _PasswordField(
              controller: _confirmPasswordController,
              label: 'Xác nhận mật khẩu mới',
              obscureText: !_showConfirmPassword,
              onToggle: () => setState(
                () => _showConfirmPassword = !_showConfirmPassword,
              ),
            ),
            if (_inlineError != null) ...[
              const SizedBox(height: 16),
              AuthErrorBanner(message: _inlineError),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading ? null : _submit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cập nhật mật khẩu'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggle,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
        ),
      ),
    );
  }
}
