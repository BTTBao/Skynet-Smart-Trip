import 'dart:async';

class MockApiService {
  // Simulate fetching profile data
  Future<Map<String, dynamic>> getProfileData() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return {
      'name': 'Nguyễn Văn Du',
      'email': 'vandu.traveler@email.com',
      'phone': '0987 654 321',
      'birthDate': '15/08/1995',
      'memberTier': 'Gold Member',
      'tripsCount': 12,
      'coins': 450,
      'vouchers': 15,
      'avatarUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuARlJrHYWx0Snqs6M2e3pDr_P-1_p8SfvoDKkBtUotLnXT2Ko7W6TMLJblZrrmf6rfH3dqvOeyetINOQinP_840be54uMbf8PPzVWKZMwdb16KBLIpCVbJLp4W-U-nd0jCy-o0T9VqNe5_3l7hPCs08sZz4hjmupkrdw_q8vLT275MOiGGgNIOOFJ7idFuY2X6HcgXIoGP1fPa50-6eEmJjL2Mca0AW2qac_Xq3OdT-WuuJXDaCX2X1ivaGZLS0p5FIAGBnwFQ8b7WG',
    };
  }
}
