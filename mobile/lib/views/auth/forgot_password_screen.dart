import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _submitted = false; // true khi gửi email thành công
  String? _inlineError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validate() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return 'Vui lòng nhập địa chỉ email.';
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.[a-z]{2,}$').hasMatch(email)) {
      return 'Địa chỉ email không hợp lệ.';
    }
    return null;
  }

  Future<void> _handleForgotPassword() async {
    setState(() => _inlineError = null);

    final validationError = _validate();
    if (validationError != null) {
      setState(() => _inlineError = validationError);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.forgotPassword(_emailController.text.trim());

    if (!mounted) return;
    if (success) {
      setState(() => _submitted = true); // hiển thị success state
    } else {
      setState(() => _inlineError = authProvider.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textHeading),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32.0),
            decoration: AppDecorations.authCard,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _submitted ? _buildSuccessState() : _buildFormState(isLoading),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Form state ──────────────────────────────────────────────────────────

  Widget _buildFormState(bool isLoading) {
    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: AppDecorations.iconBadge(),
          child: const Icon(Icons.lock_reset_rounded, color: AppColors.success, size: 36),
        ),
        const SizedBox(height: 24),
        const Text('Quên mật khẩu?', style: AppTextStyles.heading2),
        const SizedBox(height: 12),
        const Text(
          'Nhập email đã đăng ký. Chúng tôi sẽ gửi một liên kết đặt lại mật khẩu đến hòm thư của bạn.',
          style: AppTextStyles.bodyMuted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        AuthTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'example@email.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _inlineError = null),
        ),
        if (_inlineError != null) ...[
          const SizedBox(height: 16),
          AuthErrorBanner(message: _inlineError),
        ],
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: 'Gửi hướng dẫn',
          isLoading: isLoading,
          onPressed: _handleForgotPassword,
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 4),
                Text('Quay lại đăng nhập', style: AppTextStyles.linkPrimary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Success state ────────────────────────────────────────────────────────

  Widget _buildSuccessState() {
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.successBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: AppColors.success,
            size: 42,
          ),
        ),
        const SizedBox(height: 24),
        const Text('Email đã được gửi!', style: AppTextStyles.heading2),
        const SizedBox(height: 12),
        Text(
          'Chúng tôi đã gửi hướng dẫn đặt lại mật khẩu đến\n${_emailController.text.trim()}\n\nVui lòng kiểm tra hòm thư của bạn (kể cả thư mục spam).',
          style: AppTextStyles.bodyMuted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorders.radiusButton),
              ),
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
            ),
            onPressed: () => setState(() {
              _submitted = false;
              _emailController.clear();
            }),
            child: const Text(
              'Gửi lại email',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AuthPrimaryButton(
          label: 'Về trang đăng nhập',
          isLoading: false,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
