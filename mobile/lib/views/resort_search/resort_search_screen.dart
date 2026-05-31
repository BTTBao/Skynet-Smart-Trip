import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hotel_provider.dart';
import '../../models/resort_model.dart';
import 'resort_filter_sheet.dart';
import 'resort_map_screen.dart';
import '../resort_detail/resort_detail_screen.dart';

class ResortSearchScreen extends StatefulWidget {
  final int? destinationId;
  final String? destinationName;

  const ResortSearchScreen({Key? key, this.destinationId, this.destinationName}) : super(key: key);

  @override
  State<ResortSearchScreen> createState() => _ResortSearchScreenState();
}

class _ResortSearchScreenState extends State<ResortSearchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HotelProvider>().fetchHotels(destinationId: widget.destinationId, forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hotelProvider = context.watch<HotelProvider>();
    final title = widget.destinationName ?? 'Tất cả';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text('Tìm khách sạn tại $title', style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
                  _buildFilterChip('Tất cả', isSelected: true),
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
          _buildBody(context, hotelProvider, title),
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
                  shadowColor: Colors.greenAccent.withOpacity(0.5),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, HotelProvider provider, String locationTitle) {
    if (provider.isLoadingList) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6DE899))),
            SizedBox(height: 16),
            Text('Đang tìm khách sạn...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (provider.listError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: Colors.grey, size: 64),
            const SizedBox(height: 16),
            Text(provider.listError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.fetchHotels(destinationId: widget.destinationId, forceRefresh: true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6DE899)),
              child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (provider.hotels.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text('Không tìm thấy khách sạn nào.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tìm thấy ${provider.hotels.length} kết quả', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(locationTitle, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ...provider.hotels.map((hotel) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildResortCard(context, hotel),
            )),
            const SizedBox(height: 80),
          ],
        ),
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

  Widget _buildResortCard(BuildContext context, ResortModel hotel) {
    final hasDiscount = hotel.starRating >= 5;
    final displayPrice = _formatPrice(hotel.minPricePerNight);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ResortDetailScreen(hotelId: hotel.id)));
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
                  child: hotel.coverImageUrl.isNotEmpty
                      ? Image.network(hotel.coverImageUrl, height: 200, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey[200], child: const Icon(Icons.hotel, size: 64, color: Colors.grey)),
                        )
                      : Container(height: 200, color: Colors.grey[200], child: const Icon(Icons.hotel, size: 64, color: Colors.grey)),
                ),
                Positioned(
                  top: 16, right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_border, color: Colors.white, size: 20),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 16, left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF6DE899), borderRadius: BorderRadius.circular(16)),
                      child: Text('${hotel.starRating} SAO', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hotel.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(hotel.avgRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber)),
                            Text(' (${hotel.reviewCount} đánh giá)', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.grey[400], size: 14),
                            const SizedBox(width: 4),
                            Expanded(child: Text(hotel.address, style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        if (hotel.amenities.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            children: hotel.amenities.take(3).map((a) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                              child: Text(a.name, style: TextStyle(fontSize: 10, color: Colors.green[800])),
                            )).toList(),
                          ),
                        ]
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('từ', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                      Text(displayPrice, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6DE899))),
                      Text('MỖI ĐÊM', style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      final million = price / 1000000;
      return '${million.toStringAsFixed(million.truncateToDouble() == million ? 0 : 1)}M đ';
    }
    final thousands = (price / 1000).round();
    return '${thousands}k đ';
  }
}
