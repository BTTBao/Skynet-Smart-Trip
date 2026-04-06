import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/app_text.dart';
import '../../widgets/widgets.dart';
import '../auth/login_screen.dart';
import 'activity_history_view.dart';
import 'change_password_view.dart';
import 'edit_profile_view.dart';
import 'favorites_view.dart';
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
                message: 'Khong the tai thong tin ho so.',
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
                          context.tr(vi: 'Ho so', en: 'Profile'),
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
                        tooltip:
                            context.tr(vi: 'Chinh sua ho so', en: 'Edit profile'),
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
                        label: context.tr(vi: 'Chuyen di', en: 'Trips'),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: context.tr(
                      vi: 'Thong tin tai khoan',
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
                            ? context.tr(vi: 'Da xac thuc', en: 'Verified')
                            : context.tr(vi: 'Chua xac thuc', en: 'Not verified'),
                      ),
                      const Divider(height: 1),
                      _InfoTile(
                        icon: Icons.phone_outlined,
                        title: context.tr(vi: 'So dien thoai', en: 'Phone'),
                        subtitle: user.phone.isEmpty
                            ? context.tr(vi: 'Chua cap nhat', en: 'Not updated')
                            : user.phone,
                      ),
                      const Divider(height: 1),
                      _InfoTile(
                        icon: Icons.cake_outlined,
                        title: context.tr(vi: 'Ngay sinh', en: 'Birth date'),
                        subtitle: user.birthDate.isEmpty
                            ? context.tr(vi: 'Chua cap nhat', en: 'Not updated')
                            : user.birthDate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle(title: context.tr(vi: 'Tien ich', en: 'Utilities')),
                  _CardSection(
                    children: [
                      MenuItemTile(
                        icon: Icons.person_outline,
                        title:
                            context.tr(vi: 'Chinh sua ho so', en: 'Edit profile'),
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
                        title:
                            context.tr(vi: 'Doi mat khau', en: 'Change password'),
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
                        title: context.tr(vi: 'Dich vu yeu thich', en: 'Favorites'),
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
                          vi: 'Lich su hoat dong',
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
                        title: context.tr(vi: 'Cai dat', en: 'Settings'),
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
                      child: Text(context.tr(vi: 'Dang xuat', en: 'Sign out')),
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
    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(context.tr(vi: 'Dang xuat', en: 'Sign out')),
              content: Text(
                context.tr(
                  vi: 'Ban co chac muon dang xuat khoi tai khoan?',
                  en: 'Do you want to sign out of this account?',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(context.tr(vi: 'Huy', en: 'Cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(context.tr(vi: 'Dang xuat', en: 'Sign out')),
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
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

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
              child: Text(context.tr(vi: 'Thu lai', en: 'Retry')),
            ),
          ],
        ),
      ),
    );
  }
}



