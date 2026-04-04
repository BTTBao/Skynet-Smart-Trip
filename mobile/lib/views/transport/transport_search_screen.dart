import 'package:flutter/material.dart';
import 'transport_checkout_screen.dart';

class TransportSearchScreen extends StatelessWidget {
  const TransportSearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Hành Trình Việt', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.account_circle, color: Colors.green), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchForm(),
              const SizedBox(height: 16),
              _buildFilters(),
              const SizedBox(height: 24),
              const Text('Chuyến xe có sẵn (12)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              _buildTransportCard(
                context,
                logo: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
                name: 'Phương Trang',
                type: 'GIƯỜNG NẰM 40 CHỖ',
                rating: '4.8',
                timeStart: '22:00',
                timeEnd: '04:30',
                duration: '6h 30p',
                price: '250.000đ',
                spotsLeft: 'Còn 8 ghế trống',
              ),
              const SizedBox(height: 16),
              _buildTransportCard(
                context,
                logo: 'https://images.unsplash.com/photo-1464219789935-c2d9d9aba644?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
                name: 'Thành Bưởi',
                type: 'PHÒNG NẰM VIP 22 CHỖ',
                rating: '4.9',
                timeStart: '23:30',
                timeEnd: '05:30',
                duration: '6h 00p',
                price: '380.000đ',
                spotsLeft: 'Còn 4 ghế trống',
              ),
              const SizedBox(height: 16),
              _buildTransportCard(
                context,
                logo: 'https://images.unsplash.com/photo-1563720225132-069fdca49be0?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
                name: 'Minh Trí Limousine',
                type: 'LIMOUSINE 9 CHỖ',
                rating: '4.7',
                timeStart: '08:00',
                timeEnd: '13:45',
                duration: '5h 45p',
                price: '320.000đ',
                spotsLeft: 'Còn 2 ghế trống',
              ),
              const SizedBox(height: 16),
              _buildPromoBanner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildFormRow(Icons.location_on, 'TP. Hồ Chí Minh'),
          const Divider(height: 24, indent: 36),
          _buildFormRow(Icons.navigation, 'Đà Lạt'),
          const Divider(height: 24, indent: 36),
          _buildFormRow(Icons.calendar_today, 'Hôm nay, 24 Thg 5'),
        ],
      ),
    );
  }

  Widget _buildFormRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.green[800], size: 20),
        const SizedBox(width: 16),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      ],
    );
  }

  Widget _buildFilters() {
    final filters = ['Phổ biến nhất', 'Giá thấp nhất', 'Giờ chạy sớm nhất', 'Nhà xe ưu tiên'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = index == 0;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filters[index]),
              selected: isSelected,
              onSelected: (val) {},
              selectedColor: Colors.green[800],
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTransportCard(BuildContext context, {
    required String logo, required String name, required String type, required String rating,
    required String timeStart, required String timeEnd, required String duration,
    required String price, required String spotsLeft,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(logo, width: 40, height: 40, fit: BoxFit.cover)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(type, style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.green[700], size: 14),
                  const SizedBox(width: 4),
                  Text(rating, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800], fontSize: 13)),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(timeStart, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  Text('Sài Gòn', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(duration, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.green[700]),
                          Expanded(child: Container(height: 1, color: Colors.grey[300])),
                          Icon(Icons.directions_bus, size: 16, color: Colors.green[700]),
                          Expanded(child: Container(height: 1, color: Colors.grey[300])),
                          Icon(Icons.circle, size: 8, color: Colors.grey[300]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  Text(timeEnd, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  Text('Đà Lạt', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(price, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green[800])),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.red, size: 12),
                      const SizedBox(width: 4),
                      Text(spotsLeft, style: const TextStyle(color: Colors.red, fontSize: 11)),
                    ],
                  )
                ],
              ),
              ElevatedButton(
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const TransportCheckoutScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6B42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
                child: const Text('Chọn chuyến', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.green[800], borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.receipt, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 12),
          const Text('Ưu đãi đặt sớm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Giảm ngay 15% khi đặt vé trước 3 ngày khởi hành. Chỉ áp dụng cho các nhà xe ưu tiên.', style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Xem chi tiết', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, color: Colors.green[800], size: 16),
            ],
          )
        ],
      ),
    );
  }
}
