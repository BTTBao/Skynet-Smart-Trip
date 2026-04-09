import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/app_text.dart';
import '../auth/login_screen.dart';

Future<void> showSessionExpiredDialog(
  BuildContext context, {
  String? message,
}) async {
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
              Navigator.of(dialogContext, rootNavigator: true).pop();
              await context.read<AuthProvider>().logout();
              context.read<ChatProvider>().resetForSignedOutUser();
              context.read<ProfileProvider>().logout();
              if (!context.mounted) {
                return;
              }
              rootNavigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(
              context.tr(
                vi: 'Dang nhap lai',
                en: 'Sign in again',
              ),
            ),
          ),
        ],
      );
    },
  );
}
