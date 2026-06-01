import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/destination_provider.dart';
import '../destination/destination_article_screen.dart';
import '../resort_search/resort_search_screen.dart';
import '../transport/transport_search_screen.dart';

class CategoryItem {
  final String name;
  final IconData icon;
  const CategoryItem(this.name, this.icon);
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  static const List<CategoryItem> _categories = [
    CategoryItem('Biển đảo', Icons.beach_access_rounded),
    CategoryItem('Nghỉ dưỡng', Icons.spa_rounded),
    CategoryItem('Cắm trại', Icons.terrain_rounded),
    CategoryItem('Di tích', Icons.museum_rounded),
    CategoryItem('Ẩm thực', Icons.restaurant_rounded),
    CategoryItem('Thành phố', Icons.location_city_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destProvider = context.watch<DestinationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildSearchField(context),
                const SizedBox(height: 24),
                _buildSectionTitle('Bạn muốn trải nghiệm gì?'),
                const SizedBox(height: 14),
                _buildCategoryList(),
                const SizedBox(height: 20),
                _buildPromotionSlider(),
                const SizedBox(height: 28),
                _buildSectionTitle('Điểm đến phổ biến'),
                const SizedBox(height: 16),
                _buildDestinationsGrid(context, destProvider),
                const SizedBox(height: 28),
                _buildArticlesSection(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Chào ngày mới!',
              style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 4),
            Text(
              'Khám phá thế giới',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0D6B42)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                hintText: 'Tìm điểm đến, khách sạn...',
                border: InputBorder.none,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D6B42),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D6B42).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            onPressed: () {
              if (_searchQuery.isNotEmpty || _selectedCategory != null) {
                setState(() {
                  _searchController.clear();
                  _selectedCategory = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa tất cả bộ lọc!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hãy chọn danh mục hoặc tìm kiếm để lọc!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: Colors.black87,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 92,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat.name;

          return Padding(
            padding: const EdgeInsets.only(right: 18),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCategory = null;
                  } else {
                    _selectedCategory = cat.name;
                  }
                });
              },
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0D6B42) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? const Color(0xFF0D6B42).withOpacity(0.3)
                              : Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0D6B42) : Colors.grey[100]!,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      cat.icon,
                      color: isSelected ? Colors.white : const Color(0xFF0D6B42),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? const Color(0xFF0D6B42) : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromotionSlider() {
    final promos = [
      {
        'title': 'Mùa Hè Rực Rỡ',
        'subtitle': 'Giảm ngay 15% đặt phòng khách sạn',
        'code': 'SUMMER15',
        'gradient': const LinearGradient(
          colors: [Color(0xFF0D6B42), Color(0xFF1E8D5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      },
      {
        'title': 'Đặt Xe Limousine',
        'subtitle': 'Ưu đãi đặt sớm giảm 30k chuyến đi',
        'code': 'LIMOSMART',
        'gradient': const LinearGradient(
          colors: [Color(0xFF1F4E3D), Color(0xFF0D6B42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      }
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: promos.length,
        itemBuilder: (context, index) {
          final promo = promos[index];
          final gradient = promo['gradient'] as LinearGradient;
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      promo['title'] as String,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      promo['subtitle'] as String,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Code: ${promo['code']}',
                        style: TextStyle(
                          color: gradient.colors.first,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(
                    Icons.card_giftcard,
                    color: Colors.white.withOpacity(0.12),
                    size: 80,
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDestinationsGrid(BuildContext context, DestinationProvider destProvider) {
    if (destProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D6B42)),
          ),
        ),
      );
    }

    if (destProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                destProvider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => destProvider.fetchDestinations(forceRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6B42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final filteredDestinations = destProvider.destinations.where((dest) {
      if (_searchQuery.isNotEmpty) {
        final matchesQuery = dest.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            dest.description.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesQuery) return false;
      }

      if (_selectedCategory != null) {
        final category = _selectedCategory!.toLowerCase();
        final name = dest.name.toLowerCase();
        final desc = dest.description.toLowerCase();

        if (category.contains('biển') || category.contains('beach')) {
          return name.contains('nha trang') ||
              name.contains('đà nẵng') ||
              name.contains('hạ long') ||
              desc.contains('biển') ||
              desc.contains('vịnh') ||
              desc.contains('đảo');
        } else if (category.contains('nghỉ dưỡng') || category.contains('resort')) {
          return name.contains('đà lạt') ||
              name.contains('nha trang') ||
              desc.contains('nghỉ dưỡng') ||
              desc.contains('resort') ||
              desc.contains('spa');
        } else if (category.contains('cắm trại') || category.contains('camping')) {
          return name.contains('đà lạt') ||
              desc.contains('cắm trại') ||
              desc.contains('núi') ||
              desc.contains('hồ') ||
              desc.contains('rừng');
        } else if (category.contains('di tích') || category.contains('heritage')) {
          return name.contains('huế') ||
              name.contains('hội an') ||
              desc.contains('cổ') ||
              desc.contains('di tích') ||
              desc.contains('lịch sử') ||
              desc.contains('chùa');
        } else if (category.contains('ẩm thực') || category.contains('food')) {
          return name.contains('hội an') ||
              name.contains('đà nẵng') ||
              desc.contains('ẩm thực') ||
              desc.contains('ăn') ||
              desc.contains('món');
        } else if (category.contains('thành phố') || category.contains('city')) {
          return name.contains('đà nẵng') || desc.contains('thành phố') || desc.contains('phố');
        }
      }

      return true;
    }).toList();

    if (filteredDestinations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Không tìm thấy điểm đến nào phù hợp.',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: filteredDestinations.length,
      itemBuilder: (context, index) {
        final destination = filteredDestinations[index];
        
        String imageUrl = destination.coverImageUrl.trim();
        if (imageUrl.isEmpty || !imageUrl.startsWith('http') || imageUrl.contains('example.com')) {
          final lowerName = destination.name.toLowerCase();
          if (lowerName.contains('da nang') || lowerName.contains('đà nẵng')) {
            imageUrl = 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
          } else if (lowerName.contains('hoi an') || lowerName.contains('hội an')) {
            imageUrl = 'https://images.unsplash.com/photo-1588001400947-6385aef4ab0e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
          } else if (lowerName.contains('hue') || lowerName.contains('huế')) {
            imageUrl = 'https://images.unsplash.com/photo-1570710891163-6d3b5c47248b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
          } else if (lowerName.contains('da lat') || lowerName.contains('đà lạt')) {
            imageUrl = 'https://images.unsplash.com/photo-1589308078059-be1415eab4c3?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
          } else if (lowerName.contains('nha trang')) {
            imageUrl = 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
          } else if (lowerName.contains('ha long') || lowerName.contains('hạ long')) {
            imageUrl = 'https://images.unsplash.com/photo-1524230507669-e29f7363618d?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
          } else {
            imageUrl = 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
          }
        }

        return _buildDestinationCard(
          context,
          title: destination.name,
          imageUrl: imageUrl,
          isHot: destination.isHot,
          onTap: () {
            _showActionSheet(context, destination.name, destination.id);
          },
        );
      },
    );
  }

  Widget _buildDestinationCard(BuildContext context, {required String title, required String imageUrl, required bool isHot, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 32),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D6B42)),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        shadows: [
                          Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black45),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.location_on, color: Colors.white70, size: 12),
                        SizedBox(width: 2),
                        Text(
                          'Việt Nam',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isHot)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.local_fire_department, color: Colors.white, size: 10),
                        SizedBox(width: 2),
                        Text(
                          'HOT',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticlesSection(BuildContext context) {
    final articles = [
      {
        'title': 'Kinh nghiệm du lịch Đà Nẵng tự túc từ A-Z',
        'image': 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        'readTime': '5 phút đọc',
        'category': 'Cẩm nang',
      },
      {
        'title': 'Top 5 resort sang chảnh bậc nhất tại Đà Lạt',
        'image': 'https://images.unsplash.com/photo-1589308078059-be1415eab4c3?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        'readTime': '4 phút đọc',
        'category': 'Nghỉ dưỡng',
      },
      {
        'title': 'Hạ Long có gì chơi? Gợi ý lịch trình 2 ngày 1 đêm',
        'image': 'https://images.unsplash.com/photo-1524230507669-e29f7363618d?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        'readTime': '6 phút đọc',
        'category': 'Lịch trình',
      }
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Cẩm nang & Bài viết'),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DestinationArticleScreen()));
              },
              child: const Text(
                'Xem tất cả',
                style: TextStyle(
                  color: Color(0xFF0D6B42),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DestinationArticleScreen()));
                },
                child: Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                    border: Border.all(color: Colors.grey[200]!, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          article['image']!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, err, stack) => Container(
                            height: 100,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D6B42).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    article['category']!,
                                    style: const TextStyle(
                                      color: Color(0xFF0D6B42),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                                Text(
                                  article['readTime']!,
                                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              article['title']!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showActionSheet(BuildContext context, String destination, int destinationId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Khám phá $destination',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  'Chọn loại hình dịch vụ bạn muốn trải nghiệm.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),
                _buildOptionCard(
                  sheetContext,
                  icon: Icons.hotel_rounded,
                  color: const Color(0xFF0D6B42),
                  label: 'LƯU TRÚ',
                  description: 'Tìm Khách sạn / Resort sang trọng',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResortSearchScreen(
                          destinationId: destinationId,
                          destinationName: destination,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildOptionCard(
                  sheetContext,
                  icon: Icons.directions_bus_rounded,
                  color: const Color(0xFF1B5E20),
                  label: 'DI CHUYỂN',
                  description: 'Đặt vé xe Limousine chất lượng cao',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransportSearchScreen(
                          toDestId: destinationId,
                          toDestName: destination,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DestinationArticleScreen()));
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_rounded, color: Colors.green[800], size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Đọc cẩm nang chi tiết về $destination',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
