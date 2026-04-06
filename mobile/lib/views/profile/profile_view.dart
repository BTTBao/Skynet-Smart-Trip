import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';
import '../auth/login_screen.dart';
import 'edit_profile_view.dart';
import 'settings_view.dart';
import 'favorites_view.dart';
import 'activity_history_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  static const primaryColor = Color(0xFF80ed99);
  static const goldColor = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Consumer<ProfileProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator(color: primaryColor));
            }
            if (provider.error != null) {
              return Center(child: Text('Đã xảy ra lỗi: ${provider.error}'));
            }
            
            final user = provider.profileData;
            if (user == null) {
              return const Center(child: Text('Không có dữ liệu người dùng'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 40), // Cân bằng với nút edit
                        const Text(
                          'Hồ sơ cá nhân',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildHeaderButton(Icons.edit_outlined, onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfileView()),
                          );
                        }),
                      ],
                    ),
                  ),

                  // Profile Hero
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Column(
                      children: [
                        ProfileAvatar(avatarUrl: user.avatarUrl),
                        const SizedBox(height: 16),
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTierBadge(user.memberTier),
                      ],
                    ),
                  ),

                  // Stats Overview
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        StatCard(
                          value: '${user.tripsCount}',
                          label: 'Chuyến đi',
                          color: primaryColor,
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xem chi tiết các chuyến đi'))),
                        ),
                        const SizedBox(width: 12),
                        StatCard(
                          value: '${user.coins}',
                          label: 'Xu tích lũy',
                          color: Colors.orange,
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mở ví xu của bạn'))),
                        ),
                        const SizedBox(width: 12),
                        StatCard(
                          value: '${user.vouchers}',
                          label: 'Voucher',
                          color: Colors.pink,
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Danh sách mã giảm giá'))),
                        ),
                      ],
                    ),
                  ),

                  // Menu List
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'TÀI KHOẢN & TIỆN ÍCH',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade400,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))
                            ],
                          ),
                          child: Column(
                            children: [
                              MenuItemTile(
                                icon: Icons.person_outline,
                                title: 'Thông tin cá nhân',
                                color: primaryColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const EditProfileView()),
                                  );
                                },
                              ),
                              const MenuDivider(),
                              MenuItemTile(icon: Icons.payments_outlined, title: 'Thanh toán', color: primaryColor, onTap: () {}),
                              const MenuDivider(),
                              MenuItemTile(icon: Icons.security_outlined, title: 'Bảo mật', color: primaryColor, onTap: () {}),
                              const MenuDivider(),
                              MenuItemTile(
                                icon: Icons.favorite_outline,
                                title: 'Dịch vụ yêu thích',
                                color: primaryColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const FavoritesView()),
                                  );
                                },
                              ),
                              const MenuDivider(),
                              MenuItemTile(
                                icon: Icons.history,
                                title: 'Lịch sử hoạt động',
                                color: primaryColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ActivityHistoryView(userId: user.id),
                                    ),
                                  );
                                },
                              ),
                              const MenuDivider(),
                              MenuItemTile(
                                icon: Icons.settings_outlined,
                                title: 'Cài đặt',
                                color: primaryColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SettingsView()),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: InkWell(
                      onTap: () => _handleLogout(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: Colors.red.shade500),
                            const SizedBox(width: 8),
                            Text(
                              'Đăng xuất',
                              style: TextStyle(
                                color: Colors.red.shade500,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildHeaderButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))
          ],
        ),
        child: Icon(icon, color: Colors.grey.shade700, size: 20),
      ),
    );
  }

  Widget _buildTierBadge(String tier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [goldColor, goldColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: goldColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            tier.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

