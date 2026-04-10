import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/app_text.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../main_shell.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  String? _inlineError;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? _validate() {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty) return 'Vui lòng nhập Email hoặc Tên đăng nhập.';
    if (password.isEmpty) return 'Vui lòng nhập mật khẩu.';
    return null;
  }

  Future<void> _applyUserSettings() async {
    final profileProvider = context.read<ProfileProvider>();
    await profileProvider.loadSettings(forceRefresh: true);
    final settings = profileProvider.settings;
    if (!mounted || settings == null) {
      return;
    }

    await context.read<AppSettingsProvider>().applyUserSettings(settings);
  }

  Future<void> _handleLogin() async {
    setState(() => _inlineError = null);

    final validationError = _validate();
    if (validationError != null) {
      setState(() => _inlineError = validationError);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _identifierController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      await _applyUserSettings();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
      return;
    }

    setState(() => _inlineError = authProvider.errorMessage);
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _inlineError = null);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithGoogle();

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else if (authProvider.errorMessage != null) {
      // Chỉ hiện lỗi nếu có error (người dùng huỷ thì không có lỗi)
      setState(() => _inlineError = authProvider.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32),
            decoration: AppDecorations.authCard,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: AppDecorations.iconBadge(),
                  child: const Icon(
                    Icons.flight_takeoff_rounded,
                    color: AppColors.success,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Chào mừng trở lại!', style: AppTextStyles.heading2),
                const SizedBox(height: 8),
                const Text(
                  'Bắt đầu hành trình khám phá thế giới của bạn',
                  style: AppTextStyles.bodyMuted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Email
                AuthTextField(
                  controller: _identifierController,
                  label: 'Email hoặc Tên đăng nhập',
                  hint: 'example@email.com hoặc skynet_user',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  focusNode: _identifierFocus,
                  nextFocusNode: _passwordFocus,
                  onChanged: (_) => setState(() => _inlineError = null),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  focusNode: _passwordFocus,
                  onToggleObscure: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onChanged: (_) => setState(() => _inlineError = null),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    ),
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                if (_inlineError != null) ...[
                  AuthErrorBanner(message: _inlineError),
                  const SizedBox(height: 16),
                ],
                AuthPrimaryButton(
                  label: 'Đăng nhập',
                  isLoading: isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'hoặc',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Google SSO (placeholder)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorders.radiusButton),
                    ),
                    side: const BorderSide(color: AppColors.borderDefault),
                    foregroundColor: AppColors.textBody,
                  ),
                  onPressed: isLoading ? null : _handleGoogleLogin,
                  icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.blue),
                  label: const Text('Tiếp tục với Google', style: TextStyle(fontSize: 15)),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Bạn chưa có tài khoản? ',
                      style: AppTextStyles.bodyMuted,
                    ),
                    GestureDetector(
                      onTap: isLoading
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              ),
                      child: const Text('Đăng ký ngay', style: AppTextStyles.linkPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
