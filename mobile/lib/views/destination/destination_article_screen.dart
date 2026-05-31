import 'package:flutter/material.dart';
import '../resort_search/resort_search_screen.dart';
import '../transport/transport_search_screen.dart';

class DestinationArticleScreen extends StatelessWidget {
  const DestinationArticleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAuthorInfo(),
                _buildArticleContent(),
                const SizedBox(height: 100), // Space for bottom container
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomActions(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.green),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.green),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.greenAccent[100], borderRadius: BorderRadius.circular(4)),
              child: const Text('Đánh giá cao nhất', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Đà Lạt: Bản Tình Ca\nGiữa Màn Sương',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1542314831-c6a4d14d837e?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80'),
                radius: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Minh Thư', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('24 tháng 5, 2024 • 8 phút đọc', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.green[600], size: 16),
                Icon(Icons.star, color: Colors.green[600], size: 16),
                Icon(Icons.star, color: Colors.green[600], size: 16),
                Icon(Icons.star, color: Colors.green[600], size: 16),
                Icon(Icons.star_half, color: Colors.green[600], size: 16),
                const SizedBox(width: 8),
                const Text('4.9/5', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey[800], fontSize: 15, height: 1.6),
              children: [
                TextSpan(text: 'Đ', style: TextStyle(color: Colors.green[800], fontSize: 40, fontWeight: FontWeight.bold, height: 1)),
                const TextSpan(text: 'à Lạt không chỉ là một điểm đến, đó là một trạng thái tâm hồn. Khi những tia nắng đầu tiên xuyên qua kẽ lá thông, cả thành phố bừng tỉnh trong một sắc màu huyền ảo mà không nơi nào có được. Trong bài viết này, mình sẽ đưa các bạn đi qua những ngóc ngách "chill" nhất của thành phố ngàn hoa.\n\n'),
              ],
            ),
          ),
          const Text('1. Buổi sáng tại Hồ Tuyền Lâm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'Nằm cách trung tâm thành phố khoảng 7km, Hồ Tuyền Lâm là nơi lý tưởng để bắt đầu ngày mới. Không gian yên tĩnh, mặt hồ phẳng lặng như tờ, bao quanh là rừng thông xanh ngắt. Bạn có thể thuê một chiếc thuyền nhỏ hoặc SUP để cảm nhận trọn vẹn sự bình yên này.',
            style: TextStyle(color: Colors.grey[800], fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://images.unsplash.com/photo-1596423735880-532688b1ccfc?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Text('"Mặt hồ buổi sớm như một chiếc gương phẳng lồ phản chiếu bầu trời cao vút."', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.green[700], fontSize: 13)),
          const SizedBox(height: 24),
          const Text('2. Những quán cà phê "trong mây"', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'Đà Lạt nổi tiếng với văn hóa cà phê. Đừng bỏ lỡ những quán có view thung lũng như Tiệm Cà Phê Túi Mơ To hay Cheo Veooo. Nhâm nhi một tách cacao nóng trong cái se lạnh của chiều tà là trải nghiệm tuyệt vời nhất.',
            style: TextStyle(color: Colors.grey[800], fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: Colors.green[700]!, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mẹo nhỏ từ Thư:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
                const SizedBox(height: 8),
                Text('Hãy mang theo một chiếc áo khoác mỏng ngay cả khi trời đang nắng, vì nhiệt độ Đà Lạt có thể giảm rất nhanh khi mây kéo đến hoặc lúc hoàng hôn buông xuống.', style: TextStyle(color: Colors.green[900], fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sẵn sàng cho chuyến đi của bạn?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Hoàn tất hành trình của bạn chỉ với vài lần chạm.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ResortSearchScreen()));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFF0D6B42), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.bed, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LƯU TRÚ', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          Text('Đặt phòng tại đây', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TransportSearchScreen()));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFF0F7A4D), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.directions_bus, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DI CHUYỂN', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          Text('Đặt xe đến đây', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

