import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_settings.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/app_text.dart';
import 'change_password_view.dart';
import 'profile_session_helper.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  UserSettings? _draftSettings;
  bool _handledSessionExpired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadSettings(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        _handleSessionExpired(provider);
        _draftSettings ??= provider.settings;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              context.tr(vi: 'Cai dat', en: 'Settings'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              if (provider.isSavingSettings)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(ProfileProvider provider) {
    if (provider.isLoadingSettings && provider.settings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null &&
        provider.settings == null &&
        !provider.hasSessionExpired) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(provider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => provider.loadSettings(forceRefresh: true),
                child: Text(context.tr(vi: 'Thu lai', en: 'Retry')),
              ),
            ],
          ),
        ),
      );
    }

    final settings = _draftSettings;
    if (settings == null) {
      return const SizedBox.shrink();
    }

    return AbsorbPointer(
      absorbing: provider.isSavingSettings,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(context.tr(vi: 'Tai khoan', en: 'Account')),
          _SettingsCard(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.email_outlined,
                  title: context.tr(vi: 'Email', en: 'Email'),
                  subtitle: settings.email,
                ),
                const Divider(height: 1),
                _InfoRow(
                  icon: settings.isEmailVerified
                      ? Icons.verified_outlined
                      : Icons.error_outline,
                  title: context.tr(vi: 'Xac thuc email', en: 'Email verification'),
                  subtitle: settings.isEmailVerified
                      ? context.tr(vi: 'Da xac thuc', en: 'Verified')
                      : context.tr(vi: 'Chua xac thuc', en: 'Not verified'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(context.tr(vi: 'Doi mat khau', en: 'Change password')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordView(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(context.tr(vi: 'Thong bao', en: 'Notifications')),
          _SettingsCard(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: settings.pushNotificationEnabled,
                  onChanged: (value) => _saveSetting(
                    provider,
                    settings.copyWith(pushNotificationEnabled: value),
                  ),
                  title: Text(context.tr(vi: 'Thong bao day', en: 'Push notifications')),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  value: settings.emailOfferEnabled,
                  onChanged: (value) => _saveSetting(
                    provider,
                    settings.copyWith(emailOfferEnabled: value),
                  ),
                  title: Text(context.tr(vi: 'Nhan uu dai qua email', en: 'Email offers')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(context.tr(vi: 'Tuy chinh', en: 'Preferences')),
          _SettingsCard(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: settings.darkModeEnabled,
                  onChanged: (value) => _saveSetting(
                    provider,
                    settings.copyWith(darkModeEnabled: value),
                  ),
                  title: Text(context.tr(vi: 'Che do toi', en: 'Dark mode')),
                  subtitle: Text(
                    context.tr(
                      vi: 'Thay doi giao dien ngay lap tuc',
                      en: 'Apply the new appearance immediately',
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(context.tr(vi: 'Ngon ngu', en: 'Language')),
                  subtitle: Text(
                    settings.language.toLowerCase() == 'vi'
                        ? 'Tieng Viet'
                        : 'English',
                  ),
                  trailing: DropdownButton<String>(
                    value: settings.language.toLowerCase(),
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'vi', child: Text('Tieng Viet')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      _saveSetting(provider, settings.copyWith(language: value));
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(context.tr(vi: 'Don vi tien te', en: 'Currency')),
                  subtitle: Text(settings.currency.toUpperCase()),
                  trailing: DropdownButton<String>(
                    value: settings.currency.toUpperCase(),
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'VND', child: Text('VND')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      _saveSetting(provider, settings.copyWith(currency: value));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  void _updateDraft(UserSettings nextValue) {
    setState(() {
      _draftSettings = nextValue;
    });
  }

  Future<void> _saveSetting(
    ProfileProvider provider,
    UserSettings nextValue,
  ) async {
    final previousValue = _draftSettings;
    if (previousValue == null) {
      return;
    }

    _updateDraft(nextValue);
    await context.read<AppSettingsProvider>().applyUserSettings(nextValue);

    final success = await provider.saveSettings(nextValue);
    if (!mounted) {
      return;
    }

    if (provider.hasSessionExpired) {
      await _handleSessionExpired(provider);
      return;
    }

    if (success) {
      setState(() {
        _draftSettings = provider.settings;
      });
      return;
    }

    _updateDraft(previousValue);
    await context.read<AppSettingsProvider>().applyUserSettings(previousValue);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.error ??
              context.trRead(
                vi: 'Khong the cap nhat cai dat.',
                en: 'Unable to update settings.',
              ),
        ),
      ),
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
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
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
