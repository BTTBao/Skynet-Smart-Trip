import 'package:flutter/material.dart';
import '../resort_detail/resort_detail_screen.dart';

class ResortMapScreen extends StatelessWidget {
  const ResortMapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Map Simulation
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1524661135-423995f22d0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=1500&q=80',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: Stack(
                    children: [
                      // Markers
                      Positioned(top: 150, left: 100, child: _buildMapMarker('1.2tr', false)),
                      Positioned(top: 250, right: 120, child: _buildMapMarker('500k', false)),
                      Positioned(top: 350, left: 180, child: _buildMapMarker('850k', true)),
                      Positioned(top: 450, left: 80, child: _buildMapMarker('2.1tr', false)),

                      Positioned(
                        bottom: 120,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.list, color: Colors.white, size: 18),
                            label: const Text('Xem danh sách', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E1E2C),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                _buildPreviewCard(context),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kết quả tại', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  const Text('Đà Lạt, Lâm Đồng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.tune), onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildMapMarker(String price, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6DE899) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? Colors.white : const Color(0xFF6DE899), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 4))],
      ),
      child: Text(price, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.black87, fontSize: 13)),
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: GestureDetector(
        onTap: () {
          // Đi thẳng tới chi tiết resort
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ResortDetailScreen(hotelId: 1)));
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                child: Image.network(
                  'https://images.unsplash.com/photo-1542314831-c6a4d14d837e?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80',
                  width: 120, height: 120, fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(child: Text('DaLat Palace Heritage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Icon(Icons.favorite, color: const Color(0xFF6DE899), size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text('4.8', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(' (1.2k)', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on, color: Colors.grey[500], size: 14),
                                const SizedBox(width: 4),
                                Expanded(child: Text('1.2km từ trung tâm', style: TextStyle(color: Colors.grey[500], fontSize: 11), maxLines: 2)),
                              ],
                            ),
                          ),
                          Text('850.000đ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF119E50))),
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
