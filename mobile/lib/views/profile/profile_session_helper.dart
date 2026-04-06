import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../auth/login_screen.dart';

Future<void> showSessionExpiredDialog(
  BuildContext context, {
  String? message,
}) async {
  if (!context.mounted) {
    return;
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Phiên đăng nhập đã hết hạn'),
        content: Text(
          message ??
              'Vui lòng đăng nhập lại để tiếp tục sử dụng các tính năng hồ sơ.',
        ),
        actions: [
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await context.read<AuthProvider>().logout();
              context.read<ProfileProvider>().logout();
              if (!context.mounted) {
                return;
              }
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Đăng nhập lại'),
          ),
        ],
      );
    },
  );
}
