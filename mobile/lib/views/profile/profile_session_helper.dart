import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/app_text.dart';
import '../auth/login_screen.dart';

Future<void> showSessionExpiredDialog(
  BuildContext context, {
  String? message,
}) async {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!context.mounted) {
      return;
    }

    final rootNavigator = Navigator.of(context, rootNavigator: true);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            context.tr(
              vi: 'Phien dang nhap da het han',
              en: 'Your session has expired',
            ),
          ),
          content: Text(
            message ??
                context.trRead(
                  vi: 'Vui long dang nhap lai de tiep tuc su dung cac tinh nang ho so.',
                  en: 'Please sign in again to continue using profile features.',
                ),
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                final authProvider = context.read<AuthProvider>();
                final chatProvider = context.read<ChatProvider>();
                final notificationProvider = context
                    .read<NotificationProvider>();
                final profileProvider = context.read<ProfileProvider>();

                Navigator.of(dialogContext, rootNavigator: true).pop();
                await authProvider.logout();
                chatProvider.resetForSignedOutUser();
                notificationProvider.reset();
                profileProvider.logout();
                if (!rootNavigator.mounted) {
                  return;
                }

                rootNavigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: Text(context.tr(vi: 'Đăng nhập lại', en: 'Sign in again')),
            ),
          ],
        );
      },
    );
  });
}
