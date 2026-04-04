import 'package:flutter/material.dart';
import '../../models/resort_model.dart';
import '../../widgets/resort_detail/resort_image_header.dart';
import '../../widgets/resort_detail/resort_info_section.dart';
import '../../widgets/resort_detail/resort_description.dart';
import '../../widgets/resort_detail/resort_location_map.dart';
import '../../widgets/resort_detail/resort_reviews.dart';
import '../../widgets/resort_detail/resort_bottom_bar.dart';
import '../checkout/booking_date_guest_screen.dart'; // Thêm import trang chọn ngày

class ResortDetailScreen extends StatelessWidget {
  const ResortDetailScreen({Key? key}) : super(key: key);

  // Mock data matching the UI provided
  final ResortModel resort = const ResortModel(
    id: 'resort_sun_valley',
    name: 'Resort Nghỉ Dưỡng Sun Valley',
    rating: 4.9,
    reviewsCount: 128,
    location: 'Đà Lạt, Lâm Đồng, Việt Nam',
    description: 'Nằm nép mình giữa những đồi thông thơ mộng của Đà Lạt, Sun Valley mang đến trải nghiệm nghỉ dưỡng đẳng cấp với không gian xanh mát, không khí trong lành và dịch vụ 5 sao đạt chuẩn quốc tế. Tận hưởng bữa sáng bên hồ bơi vô cực...',
    price: 2450000,
    imageUrls: [
      'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2070&q=80',
      'https://images.unsplash.com/photo-1542314831-c6a4d14d837e?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    ],
  );

  final List<ReviewModel> reviews = const [
    ReviewModel(
      id: 'rev1',
      userName: 'Minh Anh',
      userAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
      date: 'HÔM QUA',
      content: 'Không gian tuyệt vời, nhân viên vô cùng nhiệt tình và chu đáo. Chắc chắn tôi sẽ quay lại lần sau!',
      rating: 5,
    ),
    ReviewModel(
      id: 'rev2',
      userName: 'Quốc Trung',
      userAvatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
      date: '3 NGÀY TRƯỚC',
      content: 'View đẹp, phòng sạch sẽ. Tuy nhiên đường vào resort hơi khó tìm một chút vào buổi tối.',
      rating: 5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ResortImageHeader(imageUrls: resort.imageUrls),
            ResortInfoSection(
              name: resort.name,
              rating: resort.rating,
              reviewsCount: resort.reviewsCount,
              location: resort.location,
            ),
            const Divider(color: Color(0xFFEEEEEE), thickness: 1),
            ResortDescription(description: resort.description),
            ResortLocationMap(),
            const Divider(color: Color(0xFFEEEEEE), thickness: 1),
            ResortReviews(reviews: reviews),
            const SizedBox(height: 20), // padding at bottom
          ],
        ),
      ),
      bottomNavigationBar: ResortBottomBar(
        price: resort.price,
        onBookNow: () {
          // Chuyển hướng sang màn hình thanh toán
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BookingDateGuestScreen(),
            ),
          );
        },
      ),
    );
  }
}
