import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../utils/app_text.dart';

import 'chatbot/chatbot_view.dart';
import 'explore/explore_view.dart';
import 'search/search_screen.dart';
import 'profile/profile_view.dart';
import 'trip/my_trips_view.dart';
import './home/home_view.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const primaryColor = Color(0xFF80ED99);

  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeView(),
    ChatbotView(),
    const SearchScreen(),
    const ExploreView(),
    const MyTripsView(),
    const ProfileView(),
  ];

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
      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: context.tr(vi: 'Trang chu', en: 'Home'),
                ),

                _buildNavItem(
                  index: 1,
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Sky Chat',
                ),

                _buildNavItem(
                  index: 2,
                  icon: Icons.search_outlined,
                  activeIcon: Icons.search,
                  label: context.tr(vi: 'Tim kiem', en: 'Search'),
                ),

                _buildNavItem(
                  index: 3,
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore,
                  label: context.tr(vi: 'Kham pha', en: 'Explore'),
                ),

                _buildNavItem(
                  index: 4,
                  icon: Icons.bookmark_outline,
                  activeIcon: Icons.bookmark,
                  label: context.tr(vi: 'Chuyen di', en: 'Trips'),
                ),

                _buildNavItem(
                  index: 5,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: context.tr(vi: 'Ho so', en: 'Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),

        behavior: HitTestBehavior.translucent,

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),

          constraints: const BoxConstraints(minHeight: 54),

          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),

          decoration: BoxDecoration(
            color: isActive
                ? primaryColor.withValues(alpha: 0.12)
                : Colors.transparent,

            borderRadius: BorderRadius.circular(16),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 23,
                color: isActive ? primaryColor : Colors.grey.shade400,
              ),

              const SizedBox(height: 4),

              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? primaryColor : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
