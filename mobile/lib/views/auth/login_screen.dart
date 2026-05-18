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

    if (email.isEmpty) {
      return context.trRead(
        vi: 'Vui long nhap email.',
        en: 'Please enter your email.',
      );
    }
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.[a-z]{2,}$').hasMatch(email)) {
      return context.trRead(
        vi: 'Email khong hop le.',
        en: 'Invalid email address.',
      );
    }
    if (password.isEmpty) {
      return context.trRead(
        vi: 'Vui long nhap mat khau.',
        en: 'Please enter your password.',
      );
    }
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
      _emailController.text.trim(),
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
                Text(
                  context.tr(vi: 'Chao mung tro lai!', en: 'Welcome back!'),
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    vi: 'Bat dau hanh trinh kham pha the gioi cua ban',
                    en: 'Continue planning your next adventure',
                  ),
                  style: AppTextStyles.bodyMuted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
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
                AuthTextField(
                  controller: _passwordController,
                  label: context.tr(vi: 'Mat khau', en: 'Password'),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  focusNode: _passwordFocus,
                  onToggleObscure: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      context.tr(
                        vi: 'Quen mat khau?',
                        en: 'Forgot password?',
                      ),
                    ),
                  ),
                ),
                if (_inlineError != null) ...[
                  AuthErrorBanner(message: _inlineError),
                  const SizedBox(height: 16),
                ],
                AuthPrimaryButton(
                  label: context.tr(vi: 'Dang nhap', en: 'Sign in'),
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
                        context.tr(vi: 'hoac', en: 'or'),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppBorders.radiusButton,
                      ),
                    ),
                    side: const BorderSide(color: AppColors.borderDefault),
                    foregroundColor: AppColors.textBody,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.trRead(
                            vi: 'Google Sign-In se duoc trien khai som.',
                            en: 'Google Sign-In will be available soon.',
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.g_mobiledata,
                    size: 28,
                    color: Colors.blue,
                  ),
                  label: Text(
                    context.tr(
                      vi: 'Tiep tuc voi Google',
                      en: 'Continue with Google',
                    ),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr(
                        vi: 'Ban chua co tai khoan? ',
                        en: 'Do not have an account? ',
                      ),
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
                      child: Text(
                        context.tr(
                          vi: 'Dang ky ngay',
                          en: 'Create account',
                        ),
                        style: AppTextStyles.linkPrimary,
                      ),
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
