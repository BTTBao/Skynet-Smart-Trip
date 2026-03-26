import 'package:flutter/material.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _pushNotificationEnabled = true;
  bool _emailOfferEnabled = false;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF80ed99);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Slightly grey background for sections
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cài đặt',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Tài khoản & Bảo mật
            _buildSectionHeader('Tài khoản & Bảo mật'),
            _buildSectionContainer([
              _buildNavigationItem(
                icon: Icons.lock_outline,
                title: 'Đổi mật khẩu',
                iconColor: Colors.blueAccent,
                onTap: () {},
              ),
              _buildDivider(),
              _buildNavigationItem(
                icon: Icons.verified_user_outlined,
                title: 'Xác minh danh tính',
                trailingText: 'Đã xác minh',
                iconColor: primaryColor,
                onTap: () {},
              ),
              _buildDivider(),
              _buildNavigationItem(
                icon: Icons.vibration,
                title: 'Xác thực 2 lớp',
                trailingText: 'Bật',
                iconColor: Colors.orange,
                onTap: () {},
              ),
            ]),

            // Section: Thông báo
            _buildSectionHeader('Thông báo'),
            _buildSectionContainer([
              _buildSwitchItem(
                icon: Icons.notifications_none,
                title: 'Thông báo đẩy',
                value: _pushNotificationEnabled,
                onChanged: (val) => setState(() => _pushNotificationEnabled = val),
                iconColor: Colors.purpleAccent,
              ),
              _buildDivider(),
              _buildSwitchItem(
                icon: Icons.mail_outline,
                title: 'Ưu đãi qua Email',
                value: _emailOfferEnabled,
                onChanged: (val) => setState(() => _emailOfferEnabled = val),
                iconColor: Colors.teal,
              ),
            ]),

            // Section: Tùy chỉnh
            _buildSectionHeader('Tùy chỉnh'),
            _buildSectionContainer([
              _buildNavigationItem(
                icon: Icons.translate,
                title: 'Ngôn ngữ',
                trailingText: 'Tiếng Việt',
                iconColor: primaryColor,
                onTap: () {},
              ),
              _buildDivider(),
              _buildNavigationItem(
                icon: Icons.payments_outlined,
                title: 'Đơn vị tiền tệ',
                trailingText: 'VND',
                iconColor: Colors.green,
                onTap: () {},
              ),
              _buildDivider(),
              _buildSwitchItem(
                icon: Icons.dark_mode_outlined,
                title: 'Chế độ tối',
                value: _darkModeEnabled,
                onChanged: (val) => setState(() => _darkModeEnabled = val),
                iconColor: Colors.indigo,
              ),
            ]),

            // Section: Hỗ trợ
            _buildSectionHeader('Hỗ trợ'),
            _buildSectionContainer([
              _buildNavigationItem(
                icon: Icons.help_outline,
                title: 'Trung tâm trợ giúp',
                iconColor: Colors.blue,
                onTap: () {},
              ),
              _buildDivider(),
              _buildNavigationItem(
                icon: Icons.bug_report_outlined,
                title: 'Báo cáo lỗi',
                iconColor: Colors.redAccent,
                onTap: () {},
              ),
              _buildDivider(),
              _buildNavigationItem(
                icon: Icons.info_outline,
                title: 'Về Skynet Smart Trip',
                iconColor: Colors.grey,
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 32),
            Center(
              child: Text(
                'PHIÊN BẢN 4.2.0 (BUILD 124)',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: Colors.grey.shade50,
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color iconColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF80ed99),
      ),
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    String? trailingText,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20),
        ],
      ),
    );
  }
}
