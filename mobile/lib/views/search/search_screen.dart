import 'package:flutter/material.dart';
import '../destination/destination_article_screen.dart';
import '../resort_search/resort_search_screen.dart';
import '../transport/transport_search_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tìm kiếm', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Bạn muốn đi đâu?',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Điểm đến phổ biến', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
                children: [
                  _buildDestinationCard(
                    context,
                    title: 'Đà Lạt',
                    imageUrl: 'https://images.unsplash.com/photo-1542314831-c6a4d14d837e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
                    onTap: () {
                      _showActionSheet(context, 'Đà Lạt');
                    },
                  ),
                  _buildDestinationCard(
                    context,
                    title: 'Nha Trang',
                    imageUrl: 'https://images.unsplash.com/photo-1576487248805-fd0891df42f4?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
                    onTap: () {
                      _showActionSheet(context, 'Nha Trang');
                    },
                  ),
                  _buildDestinationCard(
                    context,
                    title: 'Vũng Tàu',
                    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ee/Vung_Tau_beach.jpg/800px-Vung_Tau_beach.jpg',
                    onTap: () {
                      _showActionSheet(context, 'Vũng Tàu');
                    },
                  ),
                  _buildDestinationCard(
                    context,
                    title: 'Đà Nẵng',
                    imageUrl: 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
                    onTap: () {
                      _showActionSheet(context, 'Đà Nẵng');
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCard(BuildContext context, {required String title, required String imageUrl, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            ),
          ),
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context, String destination) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Bạn muốn làm gì tại $destination?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 8),
                Text('Khám phá dịch vụ tốt nhất dành cho chuyến đi của bạn.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 24),
                _buildOptionCard(
                  context,
                  icon: Icons.bed,
                  color: const Color(0xFF0D6B42),
                  label: 'LƯU TRÚ',
                  description: 'Tìm Khách sạn / Resort',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ResortSearchScreen()));
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionCard(
                  context,
                  icon: Icons.directions_bus,
                  color: const Color(0xFF0F7A4D),
                  label: 'DI CHUYỂN',
                  description: 'Đặt vé xe Limousine',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TransportSearchScreen()));
                  },
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DestinationArticleScreen()));
                    },
                    child: Text(
                      'Hoặc khám phá bài viết giới thiệu $destination',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard(BuildContext context, {required IconData icon, required Color color, required String label, required String description, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
