import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF80ed99);
    const goldColor = Color(0xFFFFD700);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Background light
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIconButton(Icons.arrow_back),
                    const Text(
                      'Hồ sơ cá nhân',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildIconButton(Icons.edit_outlined),
                  ],
                ),
              ),

              // Profile Hero
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                child: Column(
                  children: [
                    // Avatar with gradient border
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF80ed99), Color(0xFF57cc99)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          )
                        ],
                      ),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          image: const DecorationImage(
                            image: NetworkImage(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuARlJrHYWx0Snqs6M2e3pDr_P-1_p8SfvoDKkBtUotLnXT2Ko7W6TMLJblZrrmf6rfH3dqvOeyetINOQinP_840be54uMbf8PPzVWKZMwdb16KBLIpCVbJLp4W-U-nd0jCy-o0T9VqNe5_3l7hPCs08sZz4hjmupkrdw_q8vLT275MOiGGgNIOOFJ7idFuY2X6HcgXIoGP1fPa50-6eEmJjL2Mca0AW2qac_Xq3OdT-WuuJXDaCX2X1ivaGZLS0p5FIAGBnwFQ8b7WG'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nguyễn Văn A',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: goldColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: goldColor.withOpacity(0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars, color: goldColor, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Gold Member',
                            style: TextStyle(
                              color: goldColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Stats Overview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildStatCard('12', 'Chuyến đi', primaryColor),
                    const SizedBox(width: 12),
                    _buildStatCard('450', 'Xu tích lũy', primaryColor),
                    const SizedBox(width: 12),
                    _buildStatCard('15', 'Voucher', primaryColor),
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
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem(Icons.person_outline, 'Thông tin cá nhân', primaryColor),
                          _buildDivider(),
                          _buildMenuItem(Icons.payments_outlined, 'Thanh toán', primaryColor),
                          _buildDivider(),
                          _buildMenuItem(Icons.security_outlined, 'Bảo mật', primaryColor),
                          _buildDivider(),
                          _buildMenuItem(Icons.favorite_outline, 'Dịch vụ yêu thích', primaryColor),
                          _buildDivider(),
                          _buildMenuItem(Icons.history, 'Lịch sử hoạt động', primaryColor),
                          _buildDivider(),
                          _buildMenuItem(Icons.settings_outlined, 'Cài đặt', primaryColor),
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
                  onTap: () {},
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
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          )
        ],
      ),
      child: Icon(icon, color: Colors.grey.shade700, size: 20),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            )
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
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
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade50,
      indent: 16,
      endIndent: 16,
    );
  }
}
