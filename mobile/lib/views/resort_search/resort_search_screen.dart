import 'package:flutter/material.dart';
import 'resort_filter_sheet.dart';
import 'resort_map_screen.dart';
import '../resort_detail/resort_detail_screen.dart';

class ResortSearchScreen extends StatelessWidget {
  const ResortSearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text('Bạn muốn đi đâu?', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const ResortFilterSheet(),
              );
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Gần đây', isSelected: true),
                  _buildFilterChip('Giá rẻ nhất', isSelected: false),
                  _buildFilterChip('4 sao+', isSelected: false),
                  _buildFilterChip('Có hồ bơi', isSelected: false),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tìm thấy 124 kết quả', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Đà Lạt, Việt Nam', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildResortCard(context,
                    name: 'An Nhiên Boutique Hotel',
                    rating: '4.8',
                    reviews: '128 đánh giá',
                    location: 'Phường 2, TP. Đà Lạt',
                    price: '1.250.000đ',
                    imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                  ),
                  const SizedBox(height: 16),
                  _buildResortCard(context,
                    name: 'Misty Valley Resort',
                    rating: '4.5',
                    reviews: '85 đánh giá',
                    location: 'Hồ Tuyền Lâm, Đà Lạt',
                    price: '1.680.000đ',
                    oldPrice: '2.100.000đ',
                    discount: 'GIẢM 20%',
                    imageUrl: 'https://images.unsplash.com/photo-1542314831-c6a4d14d837e?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                  ),
                  const SizedBox(height: 16),
                  _buildResortCard(context,
                    name: 'Lâm Viên Homestay',
                    rating: '4.9',
                    reviews: '210 đánh giá',
                    location: 'Phường 10, Đà Lạt',
                    price: '850.000đ',
                    imageUrl: 'https://images.unsplash.com/photo-1587061949409-02df41d5e562?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                  ),
                  const SizedBox(height: 80), // Map button spacing
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ResortMapScreen()));
                },
                icon: const Icon(Icons.map, color: Colors.white, size: 18),
                label: const Text('Bản đồ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6DE899),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 6,
                  shadowColor: Colors.greenAccent.withOpacity(0.5)
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {required bool isSelected}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6DE899) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isSelected ? const Color(0xFF6DE899) : Colors.grey[300]!),
      ),
      child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildResortCard(BuildContext context, {
    required String name, required String rating, required String reviews,
    required String location, required String price, String? oldPrice, String? discount, required String imageUrl,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ResortDetailScreen()));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Image.network(imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 16, right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_border, color: Colors.white, size: 20),
                  ),
                ),
                if (discount != null)
                  Positioned(
                    top: 16, left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF6DE899), borderRadius: BorderRadius.circular(16)),
                      child: Text(discount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber)),
                                Text(' ($reviews)', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.grey[400], size: 14),
                                const SizedBox(width: 4),
                                Text(location, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ],
                            )
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (oldPrice != null) Text(oldPrice, style: TextStyle(color: Colors.grey[400], decoration: TextDecoration.lineThrough, fontSize: 11)),
                          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6DE899))),
                          Text('MỖI ĐÊM', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
