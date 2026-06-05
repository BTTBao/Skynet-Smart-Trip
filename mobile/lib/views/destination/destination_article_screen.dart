import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/explore_post.dart';
import '../../providers/destination_provider.dart';
import '../catalog/search_view.dart';

class DestinationArticleScreen extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String category;
  final String readTime;
  final String citySlug;

  const DestinationArticleScreen({
    Key? key,
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.readTime,
    required this.citySlug,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final articleData = _getArticleDataBySlug(citySlug);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, articleData),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAuthorInfo(articleData),
                _buildArticleContent(articleData),
                const SizedBox(height: 120), // Space for bottom container
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomActions(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Map<String, dynamic> data) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Colors.white70,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Color(0xFF0D6B42)),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white70,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: Color(0xFF0D6B42)),
          ),
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
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                data['badge'] ?? 'Đánh giá cao nhất',
                style: const TextStyle(
                  color: Color(0xFF0D6B42),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data['shortTitle'] ?? title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 6,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorInfo(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(data['authorAvatar']),
                radius: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['authorName'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${data['date']} • $readTime',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.amber[700], size: 16),
                Icon(Icons.star, color: Colors.amber[700], size: 16),
                Icon(Icons.star, color: Colors.amber[700], size: 16),
                Icon(Icons.star, color: Colors.amber[700], size: 16),
                Icon(Icons.star, color: Colors.amber[700], size: 16),
                const SizedBox(width: 8),
                Text(
                  data['rating'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleContent(Map<String, dynamic> data) {
    final List<dynamic> paragraphs = data['content'] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey[800], fontSize: 15, height: 1.6),
              children: [
                TextSpan(
                  text: data['firstLetter'] ?? 'Đ',
                  style: const TextStyle(
                    color: Color(0xFF0D6B42),
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                TextSpan(text: data['introText'] ?? ''),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...paragraphs.map((p) {
            if (p['type'] == 'heading') {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  p['text'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              );
            } else if (p['type'] == 'text') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  p['text'],
                  style: TextStyle(color: Colors.grey[800], fontSize: 15, height: 1.6),
                ),
              );
            } else if (p['type'] == 'image') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        p['url'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p['caption'],
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.green[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            } else if (p['type'] == 'tip') {
              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(color: Color(0xFF0D6B42), width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mẹo nhỏ hữu ích:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D6B42),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p['text'],
                      style: const TextStyle(
                        color: Color(0xFF1B5E20),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sẵn sàng cho chuyến đi của bạn?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'Hoàn tất hành trình của bạn chỉ với vài lần chạm.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _openUnifiedSearch(context, mode: SearchMode.hotel),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D6B42),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.bed, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LƯU TRÚ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Đặt phòng tại đây',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
              onTap: () => _openUnifiedSearch(context, mode: SearchMode.bus),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F7A4D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.directions_bus, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DI CHUYỂN',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Đặt xe đến đây',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  void _openUnifiedSearch(BuildContext context, {required SearchMode mode}) {
    if (mode == SearchMode.bus) {
      final destProvider = context.read<DestinationProvider>();
      int? toDestId;
      String? toDestName;

      try {
        final matchedCity = kPopularCities.firstWhere(
          (c) => c.slug == citySlug,
        );
        final destination = destProvider.destinations.firstWhere(
          (d) => d.name.toLowerCase().contains(matchedCity.name.toLowerCase()) ||
                 matchedCity.name.toLowerCase().contains(d.name.toLowerCase()),
        );
        toDestId = destination.id;
        toDestName = destination.name;
      } catch (_) {
        if (destProvider.destinations.isNotEmpty) {
          final first = destProvider.destinations.first;
          toDestId = first.id;
          toDestName = first.name;
        }
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchView(
            initialMode: SearchMode.bus,
            initialDestinationId: toDestId,
            initialQuery: toDestName,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchView(initialMode: mode)),
    );
  }

  Map<String, dynamic> _getArticleDataBySlug(String slug) {
    if (slug == 'da-nang') {
      return {
        'badge': 'Thành phố đáng sống',
        'shortTitle': 'Đà Nẵng: Thành phố\ncủa những cây cầu',
        'authorName': 'Hoàng Nam',
        'authorAvatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
        'date': '12 tháng 5, 2026',
        'rating': '4.8/5',
        'firstLetter': 'Đ',
        'introText': 'à Nẵng không chỉ hấp dẫn bởi bờ biển dài xanh biếc mà còn nổi danh với những công trình kiến trúc độc đáo bắc qua sông Hàn. Nơi đây là điểm giao thoa hoàn hảo giữa nét trẻ trung, năng động của thành phố hiện đại và sự yên bình của thiên nhiên nhiệt đới.',
        'content': [
          {
            'type': 'heading',
            'text': '1. Hành trình khám phá các cây cầu huyền thoại',
          },
          {
            'type': 'text',
            'text': 'Bắt đầu buổi tối bằng việc ghé thăm Cầu Rồng - biểu tượng vươn mình của thành phố. Vào mỗi tối cuối tuần (Thứ 7 & Chủ Nhật lúc 21:00), bạn sẽ được chiêm ngưỡng màn trình diễn phun lửa và phun nước độc nhất vô nhị. Đừng quên dạo quanh Cầu Tình Yêu ngay bên cạnh để chụp ảnh kỉ niệm nhé.',
          },
          {
            'type': 'image',
            'url': 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
            'caption': 'Cầu Vàng Bà Nà Hills - Cây cầu đi bộ nổi tiếng thế giới nâng đỡ bởi hai bàn tay khổng lồ.',
          },
          {
            'type': 'heading',
            'text': '2. Ẩm thực miền Trung ăn một lần là nhớ mãi',
          },
          {
            'type': 'text',
            'text': 'Đến Đà Nẵng nhất định phải thử Mỳ Quảng ếch, Bánh tráng cuốn thịt heo hai đầu da chấm mắm nêm đậm đà. Các quán ăn ngon tập trung nhiều dọc theo đường Lê Duẩn và Hải Phòng với mức giá vô cùng bình dân chỉ từ 30.000đ.',
          },
          {
            'type': 'tip',
            'text': 'Nên thuê xe máy để di chuyển tự túc lên Bán Đảo Sơn Trà tham quan Chùa Linh Ứng và ngắm cảnh toàn thành phố từ trên cao. Cung đường đèo rất đẹp nhưng hãy giữ vững tay lái và kiểm tra phanh xe kỹ càng.',
          },
        ]
      };
    } else if (slug == 'ha-long') {
      return {
        'badge': 'Kỳ quan thế giới',
        'shortTitle': 'Hạ Long có gì chơi?\nLịch trình 2 ngày 1 đêm',
        'authorName': 'Thanh Vân',
        'authorAvatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
        'date': '01 tháng 6, 2026',
        'rating': '4.9/5',
        'firstLetter': 'H',
        'introText': 'ạ Long luôn là lựa chọn hàng đầu cho các kỳ nghỉ gia đình và nhóm bạn nhờ vẻ đẹp hùng vĩ của hàng nghìn đảo đá vôi nhô lên từ mặt nước xanh ngọc. Lịch trình 2 ngày 1 đêm trên du thuyền hạng sang sẽ là trải nghiệm trọn vẹn nhất cho chuyến du hí của bạn.',
        'content': [
          {
            'type': 'heading',
            'text': '1. Trải nghiệm ngủ đêm trên Vịnh',
          },
          {
            'type': 'text',
            'text': 'Chọn một chiếc du thuyền 4 hoặc 5 sao để bắt đầu hành trình. Bạn sẽ được dùng bữa trưa buffet giữa vịnh khơi, tham gia chèo thuyền kayak qua Hang Luồn, ngắm hoàng hôn buông xuống thung lũng đá vôi huyền ảo và tham gia câu mực đêm cực kỳ thú vị.',
          },
          {
            'type': 'image',
            'url': 'https://images.unsplash.com/photo-1524230507669-e29f7363618d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
            'caption': 'Vẻ đẹp kỳ vĩ của Vịnh Hạ Long nhìn từ đỉnh núi Bài Thơ.',
          },
          {
            'type': 'heading',
            'text': '2. Thưởng thức chả mực giã tay đặc sản',
          },
          {
            'type': 'text',
            'text': 'Mực ở Hạ Long có vị ngọt và dai đặc trưng. Chả mực nóng hổi giòn sần sật ăn kèm bánh cuốn thanh mát hoặc xôi nếp dẻo thơm là món ăn sáng hoàn hảo tại chợ đêm Bãi Cháy.',
          },
          {
            'type': 'tip',
            'text': 'Nếu đi du thuyền, hãy thức dậy sớm vào lúc 6:00 sáng để tham gia lớp học Thái Cực Quyền (Tai Chi) trên boong tàu đón bình minh. Cực kỳ thư thái và tràn đầy năng lượng lành mạnh!',
          },
        ]
      };
    } else {
      // Default / da-lat
      return {
        'badge': 'Đánh giá cao nhất',
        'shortTitle': 'Đà Lạt: Bản Tình Ca\nGiữa Màn Sương',
        'authorName': 'Minh Thư',
        'authorAvatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-4.0.3&auto=format&fit=crop&w=150&q=80',
        'date': '24 tháng 5, 2026',
        'rating': '4.9/5',
        'firstLetter': 'Đ',
        'introText': 'à Lạt không chỉ là một điểm đến, đó là một trạng thái tâm hồn. Khi những tia nắng đầu tiên xuyên qua kẽ lá thông, cả thành phố bừng tỉnh trong một sắc màu huyền ảo mà không nơi nào có được. Trong bài viết này, mình sẽ đưa các bạn đi qua những ngóc ngách "chill" nhất của thành phố ngàn hoa.',
        'content': [
          {
            'type': 'heading',
            'text': '1. Buổi sáng tĩnh lặng tại Hồ Tuyền Lâm',
          },
          {
            'type': 'text',
            'text': 'Nằm cách trung tâm thành phố khoảng 7km, Hồ Tuyền Lâm là nơi lý tưởng để bắt đầu ngày mới. Không gian yên tĩnh, mặt hồ phẳng lặng như tờ, bao quanh là rừng thông xanh ngắt. Bạn có thể thuê một chiếc thuyền nhỏ hoặc chèo SUP để cảm nhận trọn vẹn sự bình yên này.',
          },
          {
            'type': 'image',
            'url': 'https://images.unsplash.com/photo-1596423735880-532688b1ccfc?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
            'caption': 'Mặt hồ buổi sớm như một chiếc gương phẳng khổng lồ phản chiếu bầu trời cao vút.',
          },
          {
            'type': 'heading',
            'text': '2. Những quán cà phê mộc mạc ẩn trong mây',
          },
          {
            'type': 'text',
            'text': 'Đà Lạt nổi tiếng với văn hóa cà phê bản địa độc đáo. Đừng bỏ lỡ các quán có view thung lũng lãng mạn như Tiệm Cà Phê Túi Mơ To hay Cheo Veooo. Nhâm nhi một tách cacao ấm nóng trong cái se lạnh của chiều hoàng hôn là trải nghiệm tuyệt vời nhất.',
          },
          {
            'type': 'tip',
            'text': 'Hãy luôn mang theo một chiếc áo khoác mỏng hoặc khăn quàng nhẹ bên mình ngay cả khi trời đang nắng ráo, vì nhiệt độ Đà Lạt có thể giảm rất nhanh khi mây kéo đến hoặc lúc hoàng hôn buông xuống.',
          },
        ]
      };
    }
  }
}
