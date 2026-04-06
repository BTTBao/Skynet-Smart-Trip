import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_settings.dart';
import '../../providers/profile_provider.dart';
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
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'Cai dat',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              TextButton(
                onPressed: provider.isSavingSettings || _draftSettings == null
                    ? null
                    : () => _save(provider),
                child: provider.isSavingSettings
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Luu'),
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
                child: const Text('Thu lai'),
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Tai khoan'),
        _SettingsCard(
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: settings.email,
              ),
              const Divider(height: 1),
              _InfoRow(
                icon: settings.isEmailVerified
                    ? Icons.verified_outlined
                    : Icons.error_outline,
                title: 'Xac thuc email',
                subtitle: settings.isEmailVerified
                    ? 'Da xac thuc'
                    : 'Chua xac thuc',
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Doi mat khau'),
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
        _buildSectionTitle('Thong bao'),
        _SettingsCard(
          child: Column(
            children: [
              SwitchListTile.adaptive(
                value: settings.pushNotificationEnabled,
                onChanged: (value) => _updateDraft(
                  settings.copyWith(pushNotificationEnabled: value),
                ),
                title: const Text('Thong bao day'),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                value: settings.emailOfferEnabled,
                onChanged: (value) => _updateDraft(
                  settings.copyWith(emailOfferEnabled: value),
                ),
                title: const Text('Nhan uu dai qua email'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Tuy chinh'),
        _SettingsCard(
          child: Column(
            children: [
              SwitchListTile.adaptive(
                value: settings.darkModeEnabled,
                onChanged: (value) => _updateDraft(
                  settings.copyWith(darkModeEnabled: value),
                ),
                title: const Text('Che do toi'),
                subtitle: const Text('Luu lai tuy chon giao dien cua ban'),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Ngon ngu'),
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
                    _updateDraft(settings.copyWith(language: value));
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Don vi tien te'),
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
                    _updateDraft(settings.copyWith(currency: value));
                  },
                ),
              ),
            ],
          ),
        ),
      ],
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

  Future<void> _save(ProfileProvider provider) async {
    final draft = _draftSettings;
    if (draft == null) {
      return;
    }

    final success = await provider.saveSettings(draft);
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
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Da luu cai dat.'
              : (provider.error ?? 'Khong the luu cai dat.'),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
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
