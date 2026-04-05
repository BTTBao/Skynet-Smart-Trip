import 'package:flutter/material.dart';
import 'package:mobile/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'profile/profile_view.dart';
import 'chatbot/chatbot_view.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Danh sách các trang chính của ứng dụng
  // Hiện tại chỉ có 1  tab "Cài đặt", sau này thêm tab khác vào đây
  final List<Widget> _pages = [
    _PlaceholderPage(label: 'Trang chủ', icon: Icons.home_outlined),
    ChatbotView(), // Tích hợp Chatbot vào tab 2
    _PlaceholderPage(label: 'Khám phá', icon: Icons.explore_outlined),
    _PlaceholderPage(label: 'Đặt chỗ', icon: Icons.bookmark_outline),
    ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    // Tải thông tin profile khi app khởi động
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF80ed99);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Trang chủ', primaryColor),
                _buildNavItem(1, Icons.chat_bubble_outline, Icons.chat_bubble, 'Sky Chat', primaryColor),
                _buildNavItem(2, Icons.explore_outlined, Icons.explore, 'Khám phá', primaryColor),
                _buildNavItem(3, Icons.bookmark_outline, Icons.bookmark, 'Đặt chỗ', primaryColor),
                _buildNavItem(4, Icons.settings_outlined, Icons.settings, 'Cài đặt', primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, Color activeColor) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? activeColor : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget giữ chỗ cho các tab chưa phát triển
class _PlaceholderPage extends StatelessWidget {
  final String label;
  final IconData icon;

  const _PlaceholderPage({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đang phát triển...',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
