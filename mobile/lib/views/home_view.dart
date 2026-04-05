import 'package:flutter/material.dart';
import '../widgets/promo_banner.dart';
import '../widgets/category_icon.dart';
import '../widgets/popular_destination_card.dart';
import '../widgets/featured_service_card.dart';
import '../widgets/suggestion_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thanh tìm kiếm
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        hintText: 'Bạn muốn đi đâu?',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune, color: Colors.black54),
                  )
                ],
              ),
              const SizedBox(height: 16),

              // 2. Banner khuyến mãi
              const PromoBanner(),
              const SizedBox(height: 20),

              // 3. Danh mục dịch vụ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  CategoryIcon(icon: Icons.flight_takeoff, title: 'Máy bay', color: Colors.green),
                  CategoryIcon(icon: Icons.hotel, title: 'Khách sạn', color: Colors.blue),
                  CategoryIcon(icon: Icons.map, title: 'Tour', color: Colors.orange),
                  CategoryIcon(icon: Icons.directions_car, title: 'Thuê xe', color: Colors.purple),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Điểm đến phổ biến
              const SectionHeader(title: 'Điểm đến phổ biến'),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    PopularDestinationCard(title: 'Đà Lạt', placeholderColor: Colors.teal),
                    PopularDestinationCard(title: 'Phú Quốc', placeholderColor: Colors.blueGrey),
                    PopularDestinationCard(title: 'Sa Pa', placeholderColor: Colors.brown),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Dịch vụ nổi bật
              const SectionHeader(title: 'Dịch vụ nổi bật'),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    FeaturedServiceCard(
                      name: 'Vinpearl Luxury Resort',
                      location: 'Phú Quốc, Việt Nam',
                      price: '2.450.000đ',
                      rating: '4.8',
                    ),
                    FeaturedServiceCard(
                      name: 'Tour 3N2Đ Sapa',
                      location: 'Lào Cai, Việt Nam',
                      price: '1.890.000đ',
                      rating: '4.5',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 6. Gợi ý cho bạn
              const SectionHeader(title: 'Gợi ý cho bạn'),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
                children: const [
                  SuggestionCard(title: 'InterContinental', location: 'Đà Nẵng', price: 'Từ 1.200k'),
                  SuggestionCard(title: 'Rex Hotel Saigon', location: 'TP. Hồ Chí Minh', price: 'Từ 850k'),
                  SuggestionCard(title: 'Phố Cổ Hội An', location: 'Quảng Nam', price: 'Free Admission'),
                  SuggestionCard(title: 'VinWonders', location: 'Khánh Hòa', price: 'Từ 650k'),
                ],
              ),
            ],
          ),
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm kiếm'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Chuyến đi'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Đặt chỗ'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}

// Widget phụ tiêu đề tiêu chuẩn
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Xem tất cả',
          style: TextStyle(color: Colors.green, fontSize: 14),
        ),
      ],
    );
  }
}