import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_widgets.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  String? _inlineError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  String? _validate() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.isEmpty) return 'Vui lòng nhập họ tên.';
    if (fullName.length < 2) return 'Họ tên phải có ít nhất 2 ký tự.';
    if (email.isEmpty) return 'Vui lòng nhập địa chỉ email.';
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.[a-z]{2,}$').hasMatch(email)) {
      return 'Địa chỉ email không hợp lệ.';
    }
    if (phone.isEmpty) return 'Vui lòng nhập số điện thoại.';
    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      return 'Số điện thoại không hợp lệ (gồm 10 số, bắt đầu bằng 0).';
    }
    if (password.isEmpty) return 'Vui lòng nhập mật khẩu.';
    if (password.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự.';
    if (confirmPassword != password) return 'Mật khẩu xác nhận không khớp.';
    if (!_agreedToTerms) return 'Vui lòng đồng ý với điều khoản dịch vụ.';
    return null;
  }

  Future<void> _handleRegister() async {
    setState(() => _inlineError = null);

    final validationError = _validate();
    if (validationError != null) {
      setState(() => _inlineError = validationError);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      _fullNameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _navigateToOtp();
    } else {
      setState(() => _inlineError = authProvider.errorMessage);
    }
  }

  void _navigateToOtp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      ),
    );
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
        title: const Text(
          'Tạo tài khoản',
          style: TextStyle(color: AppColors.textHeading, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(28),
            decoration: AppDecorations.authCard,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: AppDecorations.iconBadge(),
                        child: const Icon(
                          Icons.travel_explore_rounded,
                          color: AppColors.success,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Bắt đầu hành trình', style: AppTextStyles.heading2),
                      const SizedBox(height: 8),
                      const Text(
                        'Khám phá những điểm đến tuyệt vời cùng Skynet.',
                        style: AppTextStyles.bodyMuted,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Full name
                AuthTextField(
                  controller: _fullNameController,
                  label: 'Họ và tên',
                  hint: 'Nguyễn Văn A',
                  textInputAction: TextInputAction.next,
                  focusNode: _fullNameFocus,
                  nextFocusNode: _emailFocus,
                  onChanged: (_) => setState(() => _inlineError = null),
                ),
                const SizedBox(height: 16),

                // Email
                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'example@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  focusNode: _emailFocus,
                  nextFocusNode: _phoneFocus,
                  onChanged: (_) => setState(() => _inlineError = null),
                ),
                const SizedBox(height: 16),

                // Phone
                AuthTextField(
                  controller: _phoneController,
                  label: 'Số điện thoại',
                  hint: '0912345678',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  focusNode: _phoneFocus,
                  nextFocusNode: _passwordFocus,
                  onChanged: (_) => setState(() => _inlineError = null),
                ),
                const SizedBox(height: 16),

                // Password
                AuthTextField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  focusNode: _passwordFocus,
                  nextFocusNode: _confirmPasswordFocus,
                  onToggleObscure: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onChanged: (_) => setState(() => _inlineError = null),
                ),
                const SizedBox(height: 16),

                // Confirm password
                AuthTextField(
                  controller: _confirmPasswordController,
                  label: 'Xác nhận mật khẩu',
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  focusNode: _confirmPasswordFocus,
                  onToggleObscure: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  onChanged: (_) => setState(() => _inlineError = null),
                ),
                const SizedBox(height: 16),

                // Terms checkbox
                GestureDetector(
                  onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) =>
                              setState(() => _agreedToTerms = val ?? false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Tôi đồng ý với Điều khoản dịch vụ và Chính sách bảo mật của Skynet Smart Trip.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textBody,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Inline error
                if (_inlineError != null) ...[
                  AuthErrorBanner(message: _inlineError),
                  const SizedBox(height: 16),
                ],

                // Register button
                AuthPrimaryButton(
                  label: 'Đăng ký ngay',
                  isLoading: isLoading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 20),

                // Login link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Đã có tài khoản? ',
                        style: AppTextStyles.bodyMuted,
                      ),
                      GestureDetector(
                        onTap: isLoading ? null : () => Navigator.pop(context),
                        child: const Text('Đăng nhập', style: AppTextStyles.linkPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
