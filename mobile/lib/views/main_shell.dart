import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/app_text.dart';
import 'chatbot/chatbot_view.dart';
import 'explore/explore_view.dart';
import 'home/home_view.dart';
import 'profile/profile_view.dart';
import 'search/search_screen.dart';
import 'trip/my_trips_view.dart';

abstract class MainShellController {
  void openTab(int index);

  void openExplore({String? citySlug, String? cityName});
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static MainShellController? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<_MainShellState>();
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> implements MainShellController {
  static const primaryColor = Color(0xFF80ED99);

  int _currentIndex = 0;

  late final List<Widget> _pages = [
    HomeView(
      onNavigateToExplore: () => setState(() => _currentIndex = 2),
    ),
    ChatbotView(),
    const SearchScreen(),
    const MyTripsView(),
    const ProfileView(),
  ];

  @override
  void initState() {
    super.initState();

    _pages = [
      HomeView(onOpenExplore: () => setState(() => _currentIndex = 2)),
      ChatbotView(),
      const SearchScreen(),
      const MyTripsView(),
      const ProfileView(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile(forceRefresh: false);
      context.read<NotificationProvider>().fetchUnreadCount();
      _notificationTimer = Timer.periodic(const Duration(seconds: 45), (_) {
        if (mounted) {
          context.read<NotificationProvider>().fetchUnreadCount();
        }
      });
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  @override
  void openTab(int index) {
    if (!mounted || _currentIndex == index) {
      return;
    }

    setState(() => _currentIndex = index);
  }

  @override
  void openExplore({String? citySlug, String? cityName}) {
    if (!mounted) {
      return;
    }

    setState(() {
      _exploreCitySlug = citySlug;
      _exploreCityName = cityName;
      _exploreViewVersion += 1;
      _currentIndex = 3;
    });
  }

  List<Widget> _buildPages() {
    return [
      _homePage,
      _chatbotPage,
      _searchPage,
      ExploreView(
        key: ValueKey(
          'explore-$_exploreViewVersion-${_exploreCitySlug ?? ''}-${_exploreCityName ?? ''}',
        ),
        initialCitySlug: _exploreCitySlug,
        initialCityName: _exploreCityName,
      ),
      _tripsPage,
      _profilePage,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _buildPages()),
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
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, _) {
                    return _buildNavItem(
                      index: 5,
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: context.tr(vi: 'Ho so', en: 'Profile'),
                      badgeCount: notificationProvider.unreadCount,
                    );
                  },
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
    int badgeCount = 0,
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isActive ? activeIcon : icon,
                    size: 23,
                    color: isActive ? primaryColor : Colors.grey.shade400,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -7,
                      child: _NotificationBadge(count: badgeCount),
                    ),
                ],
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

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';

    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.surface),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
