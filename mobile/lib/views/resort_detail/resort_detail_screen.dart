import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hotel_provider.dart';
import '../../widgets/resort_detail/resort_image_header.dart';
import '../../widgets/resort_detail/resort_info_section.dart';
import '../../widgets/resort_detail/resort_description.dart';
import '../../widgets/resort_detail/resort_location_map.dart';
import '../../widgets/resort_detail/resort_reviews.dart';
import '../../widgets/resort_detail/resort_bottom_bar.dart';
import '../../models/resort_model.dart';
import '../checkout/booking_date_guest_screen.dart';

class ResortDetailScreen extends StatefulWidget {
  final int hotelId;

  const ResortDetailScreen({Key? key, required this.hotelId}) : super(key: key);

  @override
  State<ResortDetailScreen> createState() => _ResortDetailScreenState();
}

class _ResortDetailScreenState extends State<ResortDetailScreen> {
  int selectedRoomIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HotelProvider>().fetchHotelDetail(widget.hotelId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hotelProvider = context.watch<HotelProvider>();

    if (hotelProvider.isLoadingDetail) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6DE899))),
              SizedBox(height: 16),
              Text('Đang tải thông tin khách sạn...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (hotelProvider.detailError != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(hotelProvider.detailError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => hotelProvider.fetchHotelDetail(widget.hotelId),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6DE899)),
                child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final hotel = hotelProvider.selectedHotel;
    if (hotel == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ResortImageHeader(
              imageUrls: hotel.imageUrls.isNotEmpty
                  ? hotel.imageUrls
                  : ['https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80'],
            ),
            ResortInfoSection(
              name: hotel.name,
              rating: hotel.avgRating,
              reviewsCount: hotel.reviewCount,
              location: hotel.address,
            ),
            // Amenities row
            if (hotel.amenities.isNotEmpty) _buildAmenitiesSection(hotel),
            const Divider(color: Color(0xFFEEEEEE), thickness: 1),
            ResortDescription(description: hotel.description),
            // Room types
            _buildRoomTypesSection(hotel),
            const Divider(color: Color(0xFFEEEEEE), thickness: 1),
            ResortLocationMap(location: hotel.address),
            const Divider(color: Color(0xFFEEEEEE), thickness: 1),
            ResortReviews(reviews: hotel.reviews),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: ResortBottomBar(
        price: hotel.rooms.isNotEmpty
            ? hotel.rooms[selectedRoomIndex].pricePerNight
            : hotel.minPricePerNight,
        onBookNow: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDateGuestScreen(
                hotel: hotel,
                selectedRoom: hotel.rooms.isNotEmpty ? hotel.rooms[selectedRoomIndex] : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAmenitiesSection(ResortModel hotel) {
    final iconMap = <String, IconData>{
      'pool': Icons.pool,
      'wifi': Icons.wifi,
      'ac_unit': Icons.ac_unit,
      'local_parking': Icons.local_parking,
      'restaurant': Icons.restaurant,
      'fitness_center': Icons.fitness_center,
      'spa': Icons.spa,
      'local_bar': Icons.local_bar,
      'room_service': Icons.room_service,
      'airport_shuttle': Icons.airport_shuttle,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tiện nghi nổi bật', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: hotel.amenities.map((a) {
              final icon = iconMap[a.iconUrl] ?? Icons.check_circle;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.green[700], size: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(a.name, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypesSection(ResortModel hotel) {
    if (hotel.rooms.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Loại phòng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...List.generate(hotel.rooms.length, (index) {
            final room = hotel.rooms[index];
            final isSelected = selectedRoomIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedRoomIndex = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE8F8F0) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6DE899) : const Color(0xFFE8F8F0),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(room.roomType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle, color: Color(0xFF119E50), size: 16),
                              ]
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text('${room.capacity} người', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              const SizedBox(width: 12),
                              Icon(Icons.hotel, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text('${room.availableQty} phòng còn trống', style: TextStyle(fontSize: 12, color: room.availableQty <= 2 ? Colors.red : Colors.grey[600])),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_formatPrice(room.pricePerNight)}/đêm',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isSelected ? const Color(0xFF119E50) : const Color(0xFF6DE899),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      final m = price / 1000000;
      return '${m.toStringAsFixed(m.truncateToDouble() == m ? 0 : 1)}M đ';
    }
    return '${(price / 1000).round()}k đ';
  }
}
