import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/app_text.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../main_shell.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String password;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  String? _inlineError;

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
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

  Future<void> _handleVerify() async {
    setState(() => _inlineError = null);

    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _inlineError = 'Vui lòng nhập đủ 6 số OTP.');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(widget.email, otp);

    if (!mounted) {
      return;
    }

    if (success) {
      _showSuccessDialog();
    } else {
      setState(() => _inlineError = authProvider.errorMessage);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorders.radiusCard),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.success,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Đăng ký thành công!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textHeading,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Tài khoản của bạn đã được xác thực.\nBạn có muốn đăng nhập ngay?',
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Login now button
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  borderRadius: BorderRadius.circular(AppBorders.radiusButton),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorders.radiusButton),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleAutoLogin();
                  },
                  child: const Text('Đăng nhập vào App', style: AppTextStyles.buttonLabel),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Back to login
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text(
                'Về trang đăng nhập',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAutoLogin() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(widget.email, widget.password);

    if (!mounted) {
      return;
    }

    if (success) {
      await _applyUserSettings();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
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
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(28),
            decoration: AppDecorations.authCard,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: AppDecorations.iconBadge(),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Xác thực Email', style: AppTextStyles.heading2),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.bodyMuted.copyWith(height: 1.5),
                    children: [
                      const TextSpan(text: 'Vui lòng nhập mã gồm 6 chữ số đã được gửi đến email\n'),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                          color: AppColors.textHeading,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.bgPage,
                    border: Border.all(color: AppColors.borderDefault),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _otpController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 24,
                      color: AppColors.textHeading,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: '••••••',
                      hintStyle: TextStyle(
                        fontSize: 32,
                        letterSpacing: 24,
                        color: AppColors.borderDefault,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _inlineError = null);
                      if (val.length == 6) {
                        _focusNode.unfocus();
                        _handleVerify(); // Auto verify
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                if (_inlineError != null) ...[
                  AuthErrorBanner(message: _inlineError),
                  const SizedBox(height: 20),
                ],
                AuthPrimaryButton(
                  label: 'Xác nhận mã OTP',
                  isLoading: isLoading,
                  onPressed: _otpController.text.length == 6 ? _handleVerify : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
