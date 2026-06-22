import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/resort_model.dart';
import '../../providers/hotel_provider.dart';
import '../../widgets/app_network_image.dart';
import '../resort_detail/resort_detail_screen.dart';
import 'resort_filter_sheet.dart';
import 'resort_map_screen.dart';

class ResortSearchScreen extends StatefulWidget {
  const ResortSearchScreen({
    super.key,
    this.destinationId,
    this.destinationName,
  });

  final int? destinationId;
  final String? destinationName;

  @override
  State<ResortSearchScreen> createState() => _ResortSearchScreenState();
}

class _ResortSearchScreenState extends State<ResortSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  ResortFilterResult _filter = const ResortFilterResult();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HotelProvider>().fetchHotels(
        destinationId: widget.destinationId,
        forceRefresh: true,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ResortModel> _filteredHotels(List<ResortModel> source) {
    final query = _searchController.text.trim().toLowerCase();
    final result = source.where((hotel) {
      final amenities = hotel.amenities
          .map((item) => item.name)
          .join(' ')
          .toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          hotel.name.toLowerCase().contains(query) ||
          hotel.address.toLowerCase().contains(query) ||
          amenities.contains(query);
      final matchesPool =
          !_filter.poolOnly ||
          amenities.contains('ho boi') ||
          amenities.contains('hồ bơi') ||
          amenities.contains('pool');
      return matchesQuery &&
          matchesPool &&
          hotel.starRating >= _filter.minimumStars &&
          hotel.minPricePerNight >= _filter.minPrice &&
          hotel.minPricePerNight <= _filter.maxPrice;
    }).toList();

    switch (_filter.sort) {
      case ResortSortOption.priceLowToHigh:
        result.sort((a, b) => a.minPricePerNight.compareTo(b.minPricePerNight));
      case ResortSortOption.ratingHighToLow:
        result.sort((a, b) => b.avgRating.compareTo(a.avgRating));
      case ResortSortOption.popular:
        result.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }
    return result;
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<ResortFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ResortFilterSheet(initialValue: _filter),
    );
    if (result != null && mounted) setState(() => _filter = result);
  }

  void _setFilter({
    ResortSortOption? sort,
    int? stars,
    bool? poolOnly,
    bool reset = false,
  }) {
    setState(() {
      _filter = reset
          ? const ResortFilterResult()
          : ResortFilterResult(
              sort: sort ?? _filter.sort,
              minPrice: _filter.minPrice,
              maxPrice: _filter.maxPrice,
              minimumStars: stars ?? _filter.minimumStars,
              poolOnly: poolOnly ?? _filter.poolOnly,
            );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HotelProvider>();
    final title = widget.destinationName ?? 'Tất cả điểm đến';
    final hotels = _filteredHotels(provider.hotels);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Tìm khách sạn tại $title',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Icon(Icons.close, color: Colors.grey, size: 20),
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black87),
            onPressed: _openFilters,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(
                    'Tất cả',
                    _isDefaultFilter,
                    () => _setFilter(reset: true),
                  ),
                  _chip(
                    'Giá rẻ nhất',
                    _filter.sort == ResortSortOption.priceLowToHigh,
                    () => _setFilter(sort: ResortSortOption.priceLowToHigh),
                  ),
                  _chip(
                    '4 sao+',
                    _filter.minimumStars == 4,
                    () => _setFilter(stars: _filter.minimumStars == 4 ? 0 : 4),
                  ),
                  _chip(
                    'Có hồ bơi',
                    _filter.poolOnly,
                    () => _setFilter(poolOnly: !_filter.poolOnly),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _body(provider, hotels, title),
          if (!provider.isLoadingList && hotels.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D6B42), Color(0xFF1B9058)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D6B42).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResortMapScreen(
                            hotels: hotels,
                            locationTitle: title,
                            onFilter: () async {
                              await _openFilters();
                              return _filteredHotels(provider.hotels);
                            },
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(30),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.map, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Bản đồ (${hotels.length})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool get _isDefaultFilter =>
      _filter.sort == ResortSortOption.popular &&
      _filter.minimumStars == 0 &&
      !_filter.poolOnly &&
      _filter.minPrice == 0 &&
      _filter.maxPrice == 10000000;

  Widget _body(HotelProvider provider, List<ResortModel> hotels, String title) {
    if (provider.isLoadingList) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.listError != null) {
      return Center(
        child: FilledButton(
          onPressed: () => provider.fetchHotels(
            destinationId: widget.destinationId,
            forceRefresh: true,
          ),
          child: const Text('Thử lại'),
        ),
      );
    }
    if (hotels.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy khách sạn phù hợp.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
      children: [
        Text(
          'Tìm thấy ${hotels.length} kết quả tại $title',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...hotels.map(_hotelCard),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8F5EE) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? const Color(0xFFC2E8D4) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF0D6B42) : const Color(0xFF64748B),
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _hotelCard(ResortModel hotel) {
    final ratingStars = hotel.starRating;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResortDetailScreen(hotelId: hotel.id),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      hotel.coverImageUrl.isEmpty
                          ? Container(
                              height: 200,
                              color: Colors.grey[100],
                              child: const Center(
                                child: Icon(Icons.hotel, size: 56, color: Colors.grey),
                              ),
                            )
                          : AppNetworkImage(
                              imageUrl: hotel.coverImageUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 200,
                                color: Colors.grey[100],
                                child: const Center(
                                  child: Icon(Icons.hotel, size: 56, color: Colors.grey),
                                ),
                              ),
                            ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                hotel.avgRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                hotel.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: _formatPrice(hotel.minPricePerNight),
                                    style: const TextStyle(
                                      color: Color(0xFF0D6B42),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: '/đêm',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: index < ratingStars
                                      ? const Color(0xFFF59E0B)
                                      : Colors.grey[300],
                                );
                              }),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${hotel.reviewCount} đánh giá)',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined, color: Colors.grey[400], size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                hotel.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (hotel.amenities.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: hotel.amenities
                                .take(3)
                                .map(
                                  (item) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFEDF2F7)),
                                    ),
                                    child: Text(
                                      item.name,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(double value) {
    final formatted = value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '${formatted}₫';
  }
}
