import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/catalog_models.dart';
import '../../providers/catalog_provider.dart';
import '../../utils/app_currency_formatter.dart';
import 'package:intl/intl.dart';
import '../transport/transport_search_screen.dart';
import '../catalog/search_view.dart';
import '../resort_detail/resort_detail_screen.dart';
import '../resort_search/resort_search_screen.dart';
import '../destination/destination_article_screen.dart';
import '../vehicle_rental/vehicle_rental_list_screen.dart';
import '../vehicle_rental/vehicle_rental_detail_screen.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    this.onNavigateToExplore,
    this.onNavigateToTrips,
  });

  final VoidCallback? onNavigateToExplore;
  final VoidCallback? onNavigateToTrips;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Consumer<CatalogProvider>(
          builder: (context, provider, _) {
            final home = provider.homeData;

            return RefreshIndicator(
              onRefresh: () => provider.loadHome(forceRefresh: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  GestureDetector(
                    onTap: _openSearch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Bạn muốn đi đâu?',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.tune_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _HeroBanner(),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _CategoryItem(
                          icon: Icons.apartment_rounded,
                          label: 'Khách sạn',
                          color: const Color(0xFF3B82F6),
                          background: const Color(0xFFEFF6FF),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ResortSearchScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _CategoryItem(
                          icon: Icons.directions_bus_rounded,
                          label: 'Xe khách',
                          color: const Color(0xFFF97316),
                          background: const Color(0xFFFFF7ED),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SearchView(
                                  initialMode: SearchMode.bus,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _CategoryItem(
                          icon: Icons.two_wheeler_rounded,
                          label: 'Thuê xe',
                          color: const Color(0xFF0EA5E9),
                          background: const Color(0xFFE0F2FE),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const VehicleRentalListScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _CategoryItem(
                          icon: Icons.map_outlined,
                          label: 'Tour',
                          color: const Color(0xFF8B5CF6),
                          background: const Color(0xFFF5F3FF),
                          onTap: _openTrips,
                        ),
                        const SizedBox(width: 12),
                        _CategoryItem(
                          icon: Icons.explore_outlined,
                          label: 'Khám phá',
                          color: const Color(0xFF22C55E),
                          background: const Color(0xFFF0FDF4),
                          onTap: () {
                            if (widget.onNavigateToExplore != null) {
                              widget.onNavigateToExplore!();
                            } else {
                              _openSearch();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Điểm đến phổ biến',
                    actionLabel: 'Xem tất cả',
                    onTap: _openSearch,
                  ),
                  const SizedBox(height: 14),
                  if (provider.isLoadingHome && home == null)
                    const _LoadingCard(height: 158)
                  else if (home != null)
                    SizedBox(
                      height: 168,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: home.popularDestinations.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) => _DestinationCard(
                          item: home.popularDestinations[index],
                          onTap: () => _showDestinationActionSheet(
                            home.popularDestinations[index].name,
                            home.popularDestinations[index].id,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Dịch vụ nổi bật',
                    actionLabel: 'Tìm kiếm',
                    onTap: _openSearch,
                  ),
                  const SizedBox(height: 14),
                  if (provider.isLoadingHome && home == null)
                    const _LoadingCard(height: 308)
                  else if (home != null)
                    SizedBox(
                      height: 308,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: home.featuredHotels.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 16),
                        itemBuilder: (context, index) => _FeaturedHotelCard(
                          hotel: home.featuredHotels[index],
                          onTap: () => _openHotel(home.featuredHotels[index]),
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Dịch vụ thuê xe tự lái',
                    actionLabel: 'Xem tất cả',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const VehicleRentalListScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  if (provider.isLoadingHome && home == null)
                    const _LoadingCard(height: 190)
                  else if (home != null)
                    SizedBox(
                      height: 210,
                      child: home.featuredVehicleRentalShops.isEmpty
                          ? Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Text(
                                'Chưa có cửa hàng cho thuê xe.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: home.featuredVehicleRentalShops.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, index) =>
                                  _VehicleRentalShopCard(
                                shop: home.featuredVehicleRentalShops[index],
                                onTap: () => _openVehicleRentalShop(
                                  home.featuredVehicleRentalShops[index],
                                ),
                              ),
                            ),
                    ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Tuyến xe nổi bật',
                    actionLabel: 'Xem tuyến',
                    onTap: () => _openSearch(mode: SearchMode.bus),
                  ),
                  const SizedBox(height: 14),
                  if (provider.isLoadingHome && home == null)
                    const _LoadingCard(height: 190)
                  else if (home != null)
                    SizedBox(
                      height: 200,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: home.featuredBuses.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) => _BusCard(
                          bus: home.featuredBuses[index],
                          onTap: () => _openBus(home.featuredBuses[index]),
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Gợi ý cho bạn',
                    actionLabel: 'Khám phá',
                    onTap: () {
                      if (widget.onNavigateToExplore != null) {
                        widget.onNavigateToExplore!();
                      } else {
                        _openSearch();
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  if (provider.isLoadingHome && home == null)
                    const _LoadingCard(height: 420)
                  else if (home != null)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: home.recommendedHotels.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.82,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 14,
                          ),
                      itemBuilder: (context, index) => _SuggestedHotelCard(
                        hotel: home.recommendedHotels[index],
                        onTap: () => _openHotel(home.recommendedHotels[index]),
                      ),
                    ),
                  if (provider.error != null && home == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: Text(
                        provider.error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openSearch({
    SearchMode mode = SearchMode.hotel,
    int? destinationId,
    String? initialQuery,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchView(
          initialMode: mode,
          initialDestinationId: destinationId,
          initialQuery: initialQuery,
        ),
      ),
    );
  }


  void _openTrips() {
    if (widget.onNavigateToTrips != null) {
      widget.onNavigateToTrips!();
    }
  }

  void _openHotel(CatalogHotelCard hotel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResortDetailScreen(hotelId: hotel.id),
      ),
    );
  }

  void _openBus(CatalogBusCard bus) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransportSearchScreen(initialScheduleId: bus.id),
      ),
    );
  }

  void _openVehicleRentalShop(CatalogVehicleRentalShopCard shop) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VehicleRentalDetailScreen(shopId: shop.id),
      ),
    );
  }

  void _showDestinationActionSheet(String destinationName, int destinationId) {
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
                  'Khám phá $destinationName',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  'Chọn loại hình dịch vụ bạn muốn trải nghiệm.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),
                _buildActionOptionCard(
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
                          destinationName: destinationName,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildActionOptionCard(
                  sheetContext,
                  icon: Icons.two_wheeler_rounded,
                  color: const Color(0xFF0284C7),
                  label: 'THUÊ XE',
                  description: 'Thuê xe máy, ô tô tự lái tại điểm đến',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VehicleRentalListScreen(
                          destinationId: destinationId,
                          destinationName: destinationName,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildActionOptionCard(
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
                        builder: (_) => SearchView(
                          initialMode: SearchMode.bus,
                          initialDestinationId: destinationId,
                          initialQuery: destinationName,
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
                      final nameLower = destinationName.toLowerCase();
                      String slug = 'da-lat';
                      String title = 'Đà Lạt: Bản Tình Ca Giữa Màn Sương';
                      String imageUrl = 'https://images.unsplash.com/photo-1596423735880-532688b1ccfc?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80';
                      String category = 'Cẩm nang';
                      String readTime = '4 phút đọc';

                      if (nameLower.contains('nẵng') || nameLower.contains('nang')) {
                        slug = 'da-nang';
                        title = 'Kinh nghiệm du lịch Đà Nẵng tự túc từ A-Z';
                        imageUrl = 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
                        category = 'Cẩm nang';
                        readTime = '5 phút đọc';
                      } else if (nameLower.contains('lộng') || nameLower.contains('long')) {
                        slug = 'ha-long';
                        title = 'Hạ Long có gì chơi? Gợi ý lịch trình 2 ngày 1 đêm';
                        imageUrl = 'https://images.unsplash.com/photo-1524230507669-e29f7363618d?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80';
                        category = 'Lịch trình';
                        readTime = '6 phút đọc';
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DestinationArticleScreen(
                            title: title,
                            imageUrl: imageUrl,
                            category: category,
                            readTime: readTime,
                            citySlug: slug,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_rounded, color: Colors.green[800], size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Đọc cẩm nang chi tiết về $destinationName',
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

  Widget _buildActionOptionCard(
    BuildContext sheetContext, {
    required IconData icon,
    required Color color,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7CEB8A), Color(0xFF57D978)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -18,
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: 34,
            bottom: -24,
            child: Container(
              width: 126,
              height: 126,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Khám phá thế giới',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ưu đãi mùa hè lên đến 30%',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Đặt ngay',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.16)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textHeading,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textHeading,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.item, required this.onTap});

  final CatalogDestination item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 134,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                item.coverImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: const Color(0xFFDDEEE0)),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedHotelCard extends StatelessWidget {
  const _FeaturedHotelCard({required this.hotel, required this.onTap});

  final CatalogHotelCard hotel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 274,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Image.network(
                hotel.imageUrl,
                height: 172,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(height: 172, color: const Color(0xFFE2E8F0)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hotel.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textHeading,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFBBF24),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hotel.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${hotel.destinationName}, Việt Nam',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        AppCurrencyFormatter.format(hotel.pricePerNight),
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        ' / đêm',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const Spacer(),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusCard extends StatelessWidget {
  const _BusCard({required this.bus, required this.onTap});

  final CatalogBusCard bus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 230,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: bus.imageUrl.isEmpty
                      ? const Icon(
                          Icons.directions_bus_rounded,
                          color: Color(0xFFF97316),
                        )
                      : Image.network(
                          bus.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.directions_bus_rounded,
                            color: Color(0xFFF97316),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    bus.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${bus.fromDestination} → ${bus.toDestination}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 4),
                Text(
                  '${bus.rating} (${bus.reviewCount})',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${bus.departureTime != null ? DateFormat('HH:mm').format(bus.departureTime!) : '--:--'}  →  ${bus.arrivalTime != null ? DateFormat('HH:mm').format(bus.arrivalTime!) : '--:--'}',
                    style: const TextStyle(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              AppCurrencyFormatter.format(bus.price),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleRentalShopCard extends StatelessWidget {
  const _VehicleRentalShopCard({required this.shop, required this.onTap});

  final CatalogVehicleRentalShopCard shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                shop.imageUrl,
                height: 96,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 96,
                  color: const Color(0xFFE2E8F0),
                  child: const Icon(
                    Icons.two_wheeler_rounded,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              shop.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              shop.destinationName,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const Spacer(),
            Text(
              'Từ ${AppCurrencyFormatter.format(shop.minPricePerDay)}/ngày',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestedHotelCard extends StatelessWidget {
  const _SuggestedHotelCard({required this.hotel, required this.onTap});

  final CatalogHotelCard hotel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: Image.network(
                hotel.imageUrl,
                height: 126,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: const Color(0xFFE2E8F0)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Text(
                hotel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHeading,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                hotel.destinationName,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Text(
                'Từ ${AppCurrencyFormatter.format(hotel.pricePerNight)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: AppColors.primary),
    );
  }
}
