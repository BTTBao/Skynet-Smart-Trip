import 'package:flutter/material.dart';
import '../views.dart';

class TestNavigationView extends StatelessWidget {
  const TestNavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF80ed99);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skynet Smart Trip - UI Test Menu'),
        backgroundColor: primaryColor.withOpacity(0.1),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTestItem(
            context,
            title: '1. Hồ sơ cá nhân (Profile)',
            icon: Icons.person,
            subtitle: 'Profile Screen',
            destination: const ProfileView(),
            color: Colors.blue,
          ),
          _buildTestItem(
            context,
            title: '2. Chỉnh sửa hồ sơ (Edit Profile)',
            icon: Icons.edit,
            subtitle: 'Edit Profile Screen',
            destination: const EditProfileView(),
            color: Colors.green,
          ),
          _buildTestItem(
            context,
            title: '3. Cài đặt (Settings)',
            icon: Icons.settings,
            subtitle: 'Settings Screen',
            destination: const SettingsView(),
            color: Colors.orange,
          ),
          _buildTestItem(
            context,
            title: '4. Mục yêu thích (Empty Favorites)',
            icon: Icons.favorite,
            subtitle: 'Empty Favorites Screen',
            destination: const FavoritesView(),
            color: Colors.red,
          ),
          _buildTestItem(
            context,
            title: '5. Lịch sử hoạt động (Activity History)',
            icon: Icons.history,
            subtitle: 'Activity History Screen',
            destination: const ActivityHistoryView(),
            color: Colors.purple,
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'Bấm vào các mục trên để xem giao diện',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget destination,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
      ),
    );
  }
}
