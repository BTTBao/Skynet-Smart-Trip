import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
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

  Future<void> _handleVerify() async {
    setState(() => _inlineError = null);

    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _inlineError = 'Vui lòng nhập đủ 6 số OTP.');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(widget.email, otp);

    if (!mounted) return;

    if (success) {
      await _handleAutoLogin();
    } else {
      setState(() => _inlineError = authProvider.errorMessage);
    }
  }


  Future<void> _handleAutoLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(widget.email, widget.password);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } else {
      // Khoong dang nhap auto duoc thi quay lai dang nhap thu cong
      Navigator.of(context).popUntil((route) => route.isFirst);
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
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(28),
            decoration: AppDecorations.authCard,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
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

                // OTP Input
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

                // Inline error
                if (_inlineError != null) ...[
                  AuthErrorBanner(message: _inlineError),
                  const SizedBox(height: 20),
                ],

                // Verify button
                AuthPrimaryButton(
                  label: 'Xác nhận mã OTP',
                  isLoading: isLoading,
                  onPressed: _otpController.text.length == 6 ? _handleVerify : null,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
