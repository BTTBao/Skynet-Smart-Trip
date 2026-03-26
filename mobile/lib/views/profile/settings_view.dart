import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotificationEnabled = true;
  bool _emailOfferEnabled = false;

  @override
  Widget build(BuildContext context) {
    // Primary color from Tailwind config
    const primaryColor = Color(0xFF80ed99);

    return Scaffold(
      backgroundColor: Colors.white,
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[100],
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Preview Section
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(24),
              color: primaryColor.withOpacity(0.05),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                      image: const DecorationImage(
                        image: NetworkImage(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuAVjJ0XqPfTeih5p1pWe6rjguUON84aP7_na4mYzWQouZJh_0R24vN4KM5lVesTjg3GhFCtWVQoCcYTLD4ptHQNdCy7D3FPevAwHUfepqYJxxlolvfQ0XyhTg0CUFoyvNZ8yw7oPaJo0al8qvYLAHtbzNf5f9qzT5w6lpCFKePRVLF9XW8UbiLNVyreufaeKXkXqQEkzxP6F4sIS4lUMHeJj-M5T1yiLG6iDORvjUI3ogpTwNj3kKxIZnyRzGnrxvuf9rWkWjY_gmSw'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minh Tuấn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Thành viên Bạc • Chỉnh sửa hồ sơ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Category: Thông báo
            _buildSectionHeader('Thông báo'),
            _buildSwitchItem(
              icon: Icons.notifications_none,
              title: 'Thông báo đẩy',
              value: _pushNotificationEnabled,
              onChanged: (val) => setState(() => _pushNotificationEnabled = val),
              iconColor: primaryColor,
            ),
            _buildSwitchItem(
              icon: Icons.mail_outline,
              title: 'Ưu đãi qua Email',
              value: _emailOfferEnabled,
              onChanged: (val) => setState(() => _emailOfferEnabled = val),
              iconColor: primaryColor,
            ),

            const SizedBox(height: 16),

            // Category: Tùy chỉnh
            _buildSectionHeader('Tùy chỉnh'),
            _buildNavigationItem(
              icon: Icons.translate,
              title: 'Ngôn ngữ',
              trailingText: 'Tiếng Việt',
              iconColor: primaryColor,
              onTap: () {},
            ),
            _buildNavigationItem(
              icon: Icons.payments_outlined,
              title: 'Đơn vị tiền tệ',
              trailingText: 'VND',
              iconColor: primaryColor,
              onTap: () {},
            ),

            const SizedBox(height: 16),

            // Category: Bảo mật
            _buildSectionHeader('Bảo mật'),
            _buildNavigationItem(
              icon: Icons.lock_outline,
              title: 'Quyền riêng tư',
              iconColor: primaryColor,
              onTap: () {},
            ),
            _buildNavigationItem(
              icon: Icons.shield_outlined,
              title: 'Điều khoản dịch vụ',
              iconColor: primaryColor,
              onTap: () {},
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50.withOpacity(0.5),
                        border: Border.all(color: Colors.red.shade100),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.red.shade400, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Đăng xuất tài khoản',
                            style: TextStyle(
                              color: Colors.red.shade400,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'PHIÊN BẢN 4.2.0 (BUILD 124)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: iconColor,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade200,
              ),
            ],
          ),
        ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
