import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/destination_provider.dart';
import '../destination/destination_article_screen.dart';
import '../resort_search/resort_search_screen.dart';
import '../transport/transport_search_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final destProvider = context.watch<DestinationProvider>();

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
              child: _buildDestinationsGrid(context, destProvider),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationsGrid(BuildContext context, DestinationProvider destProvider) {
    if (destProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D6B42)),
        ),
      );
    }

    if (destProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              destProvider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => destProvider.fetchDestinations(forceRefresh: true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6B42)),
              child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (destProvider.destinations.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy điểm đến nào.', style: TextStyle(color: Colors.grey)),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: destProvider.destinations.length,
      itemBuilder: (context, index) {
        final destination = destProvider.destinations[index];
        
        // Cung cấp các ảnh đẹp chất lượng cao tương ứng với các địa điểm nổi tiếng làm fallback
        String imageUrl = destination.coverImageUrl.trim();
        if (imageUrl.isEmpty || !imageUrl.startsWith('http') || imageUrl.contains('example.com')) {
          final lowerName = destination.name.toLowerCase();
          if (lowerName.contains('da nang') || lowerName.contains('đà nẵng')) {
            imageUrl = 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
          } else if (lowerName.contains('hoi an') || lowerName.contains('hội an')) {
            imageUrl = 'https://images.unsplash.com/photo-1588001400947-6385aef4ab0e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
          } else if (lowerName.contains('hue') || lowerName.contains('huế')) {
            imageUrl = 'https://images.unsplash.com/photo-1570710891163-6d3b5c47248b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
          } else if (lowerName.contains('da lat') || lowerName.contains('đà lạt')) {
            imageUrl = 'https://images.unsplash.com/photo-1589308078059-be1415eab4c3?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
          } else if (lowerName.contains('nha trang')) {
            imageUrl = 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
          } else {
            imageUrl = 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
          }
        }

        return _buildDestinationCard(
          context,
          title: destination.name,
          imageUrl: imageUrl,
          onTap: () {
            _showActionSheet(context, destination.name, destination.id);
          },
        );
      },
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

  void _showActionSheet(BuildContext context, String destination, int destinationId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
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
                  sheetContext,
                  icon: Icons.bed,
                  color: const Color(0xFF0D6B42),
                  label: 'LƯU TRÚ',
                  description: 'Tìm Khách sạn / Resort',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ResortSearchScreen(destinationId: destinationId, destinationName: destination)));
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionCard(
                  sheetContext,
                  icon: Icons.directions_bus,
                  color: const Color(0xFF0F7A4D),
                  label: 'DI CHUYỂN',
                  description: 'Đặt vé xe Limousine',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TransportSearchScreen(toDestId: destinationId, toDestName: destination)));
                  },
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
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
