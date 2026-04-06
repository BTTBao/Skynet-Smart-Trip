import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../main_shell.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  String? _inlineError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) return 'Vui lòng nhập địa chỉ email.';
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.[a-z]{2,}$').hasMatch(email)) {
      return 'Địa chỉ email không hợp lệ.';
    }
    if (password.isEmpty) return 'Vui lòng nhập mật khẩu.';
    return null;
  }

  Future<void> _handleLogin() async {
    // Clear previous errors
    setState(() => _inlineError = null);

    final validationError = _validate();
    if (validationError != null) {
      setState(() => _inlineError = validationError);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
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
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32.0),
            decoration: AppDecorations.authCard,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brand icon
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
                  controller: _emailController,
                  label: 'Email',
                  hint: 'example@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  focusNode: _emailFocus,
                  nextFocusNode: _passwordFocus,
                  onChanged: (_) => setState(() => _inlineError = null),
                ),
                const SizedBox(height: 16),

                // Password
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

                // Forgot password link
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

                // Inline error
                if (_inlineError != null) ...[
                  AuthErrorBanner(message: _inlineError),
                  const SizedBox(height: 16),
                ],

                // Login button
                AuthPrimaryButton(
                  label: 'Đăng nhập',
                  isLoading: isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 28),

                // Divider
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Google Sign-In sẽ được triển khai sớm.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.blue),
                  label: const Text('Tiếp tục với Google', style: TextStyle(fontSize: 15)),
                ),
                const SizedBox(height: 28),

                // Sign up link
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
