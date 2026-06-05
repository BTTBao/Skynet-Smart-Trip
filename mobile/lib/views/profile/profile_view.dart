import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/app_text.dart';
import '../../widgets/widgets.dart';
import '../auth/login_screen.dart';
import 'activity_history_view.dart';
import 'change_password_view.dart';
import 'edit_profile_view.dart';
import 'favorites_view.dart';
import 'notifications_view.dart';
import 'profile_session_helper.dart';
import 'settings_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  static const primaryColor = Color(0xFF80ED99);
  bool _handledSessionExpired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile(forceRefresh: false);
      context.read<NotificationProvider>().fetchUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<ProfileProvider>(
          builder: (context, provider, _) {
            _handleSessionExpired(provider);

            if (provider.isLoading && provider.profileData == null) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            if (provider.error != null &&
                provider.profileData == null &&
                !provider.hasSessionExpired) {
              return _ErrorState(
                message: provider.error!,
                onRetry: () => provider.fetchProfile(forceRefresh: true),
              );
            }

            final user = provider.profileData;
            if (user == null) {
              return _ErrorState(
                message: 'Không thể tải thông tin hồ sơ.',
                onRetry: () => provider.fetchProfile(forceRefresh: true),
              );
            }

            return RefreshIndicator(
              color: primaryColor,
              onRefresh: () => provider.fetchProfile(forceRefresh: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr(vi: 'Hồ sơ', en: 'Profile'),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EditProfileView(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: context.tr(
                          vi: 'Chỉnh sửa hồ sơ',
                          en: 'Edit profile',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ProfileHero(user: user),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      StatCard(
                        value: '${user.tripsCount}',
                        label: context.tr(vi: 'Chuyến đi', en: 'Trips'),
                        color: primaryColor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ActivityHistoryView(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      StatCard(
                        value: '${user.coins}',
                        label: context.tr(vi: 'Xu', en: 'Coins'),
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      StatCard(
                        value: '${user.vouchers}',
                        label: context.tr(vi: 'Voucher', en: 'Vouchers'),
                        color: Colors.pink,
                        onTap: () =>
                            _showVouchersBottomSheet(context, provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: context.tr(
                      vi: 'Thông tin tài khoản',
                      en: 'Account info',
                    ),
                  ),
                  _CardSection(
                    children: [
                      _InfoTile(
                        icon: Icons.mail_outline,
                        title: context.tr(vi: 'Email', en: 'Email'),
                        subtitle: user.email,
                        trailingText: user.isEmailVerified
                            ? context.tr(vi: 'Đã xác thực', en: 'Verified')
                            : context.tr(
                                vi: 'Chưa xác thực',
                                en: 'Not verified',
                              ),
                      ),
                      const Divider(height: 1),
                      _InfoTile(
                        icon: Icons.phone_outlined,
                        title: context.tr(vi: 'Số điện thoại', en: 'Phone'),
                        subtitle: user.phone.isEmpty
                            ? context.tr(vi: 'Chưa cập nhật', en: 'Not updated')
                            : user.phone,
                      ),
                      const Divider(height: 1),
                      _InfoTile(
                        icon: Icons.cake_outlined,
                        title: context.tr(vi: 'Ngày sinh', en: 'Birth date'),
                        subtitle: user.birthDate.isEmpty
                            ? context.tr(vi: 'Chưa cập nhật', en: 'Not updated')
                            : user.birthDate,
                      ),
                      const Divider(height: 1),
                      _InfoTile(
                        icon: Icons.credit_card_outlined,
                        title: context.tr(
                          vi: 'Số CCCD / CMND',
                          en: 'ID Card Number',
                        ),
                        subtitle:
                            (user.identityNumber == null ||
                                user.identityNumber!.isEmpty)
                            ? context.tr(vi: 'Chưa cập nhật', en: 'Not updated')
                            : user.identityNumber!,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: context.tr(vi: 'Tiện ích', en: 'Utilities'),
                  ),
                  _CardSection(
                    children: [
                      Consumer<NotificationProvider>(
                        builder: (context, notificationProvider, _) {
                          return MenuItemTile(
                            icon: Icons.notifications_outlined,
                            title: context.tr(
                              vi: 'Thông báo',
                              en: 'Notifications',
                            ),
                            color: primaryColor,
                            badgeCount: notificationProvider.unreadCount,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsView(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const MenuDivider(),
                      MenuItemTile(
                        icon: Icons.person_outline,
                        title: context.tr(
                          vi: 'Chỉnh sửa hồ sơ',
                          en: 'Edit profile',
                        ),
                        color: primaryColor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EditProfileView(),
                            ),
                          );
                        },
                      ),
                      const MenuDivider(),
                      MenuItemTile(
                        icon: Icons.lock_outline,
                        title: context.tr(
                          vi: 'Đổi mật khẩu',
                          en: 'Change password',
                        ),
                        color: primaryColor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordView(),
                            ),
                          );
                        },
                      ),
                      const MenuDivider(),
                      MenuItemTile(
                        icon: Icons.favorite_outline,
                        title: context.tr(
                          vi: 'Dịch vụ yêu thích',
                          en: 'Favorites',
                        ),
                        color: primaryColor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FavoritesView(),
                            ),
                          );
                        },
                      ),
                      const MenuDivider(),
                      MenuItemTile(
                        icon: Icons.history,
                        title: context.tr(
                          vi: 'Lịch sử hoạt động',
                          en: 'Activity history',
                        ),
                        color: primaryColor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ActivityHistoryView(),
                            ),
                          );
                        },
                      ),
                      const MenuDivider(),
                      MenuItemTile(
                        icon: Icons.settings_outlined,
                        title: context.tr(vi: 'Cài đặt', en: 'Settings'),
                        color: primaryColor,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsView(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout),
                    label: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(context.tr(vi: 'Đăng xuất', en: 'Sign out')),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade200),
                      backgroundColor: Colors.red.shade50,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(context.tr(vi: 'Đăng xuất', en: 'Sign out')),
              content: Text(
                context.tr(
                  vi: 'Bạn có chắc muốn đăng xuất khỏi tài khoản?',
                  en: 'Do you want to sign out of this account?',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(context.tr(vi: 'Hủy', en: 'Cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(context.tr(vi: 'Đăng xuất', en: 'Sign out')),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldLogout || !mounted) {
      return;
    }

    await context.read<AuthProvider>().logout();
    if (!mounted) {
      return;
    }

    context.read<ChatProvider>().resetForSignedOutUser();
    context.read<NotificationProvider>().reset();
    context.read<ProfileProvider>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _handleSessionExpired(ProfileProvider provider) async {
    if (_handledSessionExpired || !provider.hasSessionExpired || !mounted) {
      return;
    }

    _handledSessionExpired = true;
    await showSessionExpiredDialog(context, message: provider.error);
  }

  void _showVouchersBottomSheet(
    BuildContext context,
    ProfileProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr(
                            vi: 'Mã khuyến mãi khả dụng',
                            en: 'Your Voucher Inventory',
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: provider.myVouchers.every((v) => v.quantity == 0)
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.card_giftcard,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  context.tr(
                                    vi: 'Hiện chưa có mã khuyến mãi khả dụng.',
                                    en: 'Inventory is empty. You have no vouchers.',
                                  ),
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(20),
                            itemCount: provider.myVouchers.length,
                            itemBuilder: (context, index) {
                              final voucher = provider.myVouchers[index];
                              if (voucher.quantity <= 0)
                                return const SizedBox.shrink();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Color(0xFFEEEEEE)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.02,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5EE),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFC2E8D4),
                                        ),
                                      ),
                                      child: Text(
                                        voucher.code,
                                        style: const TextStyle(
                                          color: Color(0xFF0D6B42),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            voucher.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            voucher.description,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            voucher.expiry,
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'x${voucher.quantity}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF80ED99), Color(0xFF57CC99)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          ProfileAvatar(avatarUrl: user.avatarUrl),
          const SizedBox(height: 16),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              user.memberTier,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black26
                : Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailingText == null
          ? null
          : Text(
              trailingText!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(context.tr(vi: 'Thử lại', en: 'Retry')),
            ),
          ],
        ),
      ),
    );
  }
}
