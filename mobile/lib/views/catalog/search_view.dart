import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/catalog_models.dart';
import '../../providers/catalog_provider.dart';
import '../../utils/app_currency_formatter.dart';
import 'bus_detail_view.dart';
import 'hotel_detail_view.dart';

enum SearchMode { hotel, bus }

class SearchView extends StatefulWidget {
  const SearchView({
    super.key,
    this.initialMode = SearchMode.hotel,
    this.initialDestinationId,
    this.initialQuery,
  });

  final SearchMode initialMode;
  final int? initialDestinationId;
  final String? initialQuery;

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  late final TextEditingController _searchController;
  late SearchMode _mode;
  String _hotelSort = 'popular';
  String _busSort = 'earliest';
  double _minPrice = 500000;
  double _maxPrice = 5000000;
  double _minRating = 4.0;
  final Set<int> _selectedStars = {4, 5};
  int? _destinationId;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _destinationId = widget.initialDestinationId;
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) => _runInitialSearch());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runInitialSearch() async {
    if (_mode == SearchMode.hotel) {
      await _searchHotels();
    } else {
      await _searchBuses();
    }
  }

  Future<void> _searchHotels() {
    return context.read<CatalogProvider>().searchHotels(
      query: _searchController.text,
      destinationId: _destinationId,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minRating: _minRating,
      starRatings: _selectedStars.toList()..sort(),
      sort: _hotelSort,
    );
  }

  Future<void> _searchBuses() {
    return context.read<CatalogProvider>().searchBuses(
      query: _searchController.text,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      sort: _busSort,
    );
  }

  bool get _isRecentSelected =>
      _mode == SearchMode.hotel
          ? _hotelSort == 'popular'
          : _busSort == 'earliest';

  void _toggleRecent() {
    setState(() {
      if (_mode == SearchMode.hotel) {
        _hotelSort = 'popular';
      } else {
        _busSort = 'earliest';
      }
    });
    _mode == SearchMode.hotel ? _searchHotels() : _searchBuses();
  }

  void _togglePriceAsc() {
    setState(() {
      if (_mode == SearchMode.hotel) {
        _hotelSort = _hotelSort == 'priceasc' ? 'popular' : 'priceasc';
      } else {
        _busSort = _busSort == 'priceasc' ? 'earliest' : 'priceasc';
      }
    });
    _mode == SearchMode.hotel ? _searchHotels() : _searchBuses();
  }

  void _toggleHotelRatingDesc() {
    setState(() {
      _hotelSort = _hotelSort == 'ratingdesc' ? 'popular' : 'ratingdesc';
    });
    _searchHotels();
  }

  void _toggleQuickStarFilter() {
    setState(() {
      final hasQuickFilter =
          _selectedStars.contains(4) && _selectedStars.contains(5);
      if (hasQuickFilter) {
        _selectedStars
          ..remove(4)
          ..remove(5);
      } else {
        _selectedStars
          ..add(4)
          ..add(5);
      }
    });
    _searchHotels();
  }

  Future<void> _openFilters() async {
    var draftHotelSort = _hotelSort;
    var draftBusSort = _busSort;
    var draftMinPrice = _minPrice;
    var draftMaxPrice = _maxPrice;
    var draftMinRating = _minRating;
    final draftStars = {..._selectedStars};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isHotel = _mode == SearchMode.hotel;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 82,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Bộ lọc & Sắp xếp',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textHeading,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                draftHotelSort = 'popular';
                                draftBusSort = 'earliest';
                                draftMinPrice = 500000;
                                draftMaxPrice = 5000000;
                                draftMinRating = 4.0;
                                draftStars
                                  ..clear()
                                  ..addAll({4, 5});
                              });
                            },
                            child: const Text(
                              'Thiết lập lại',
                              style: TextStyle(
                                color: Color(0xFFF97316),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Sắp xếp theo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...[
                        ('popular', 'Phổ biến nhất'),
                        ('priceasc', 'Giá thấp đến cao'),
                        (
                          isHotel ? 'ratingdesc' : 'pricedesc',
                          isHotel ? 'Đánh giá cao' : 'Giá cao đến thấp',
                        ),
                      ].map(
                        (option) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RadioTile(
                            label: option.$2,
                            selected:
                                (isHotel ? draftHotelSort : draftBusSort) ==
                                option.$1,
                            onTap: () => setSheetState(() {
                              if (isHotel) {
                                draftHotelSort = option.$1;
                              } else {
                                draftBusSort = option.$1;
                              }
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Khoảng giá (VND)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '${(draftMinPrice / 1000).round()}k - ${(draftMaxPrice / 1000000).toStringAsFixed(1)}tr',
                            style: const TextStyle(
                              color: Color(0xFFF97316),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      RangeSlider(
                        values: RangeValues(draftMinPrice, draftMaxPrice),
                        min: 300000,
                        max: 5000000,
                        activeColor: const Color(0xFFF97316),
                        inactiveColor: const Color(0xFFE2E8F0),
                        onChanged: (value) {
                          setSheetState(() {
                            draftMinPrice = value.start;
                            draftMaxPrice = value.end;
                          });
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _PriceTile(
                              label: 'Tối thiểu',
                              value: draftMinPrice,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PriceTile(
                              label: 'Tối đa',
                              value: draftMaxPrice,
                            ),
                          ),
                        ],
                      ),
                      if (isHotel) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Đánh giá tối thiểu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [3.5, 4.0, 4.5, 4.8]
                              .map(
                                (rating) => _MiniChip(
                                  label: '${rating.toStringAsFixed(1)}★',
                                  selected: draftMinRating == rating,
                                  onTap: () => setSheetState(
                                    () => draftMinRating = rating,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Hạng sao',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [3, 4, 5].map((star) {
                            final selected = draftStars.contains(star);
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: star == 5 ? 0 : 10,
                                ),
                                child: GestureDetector(
                                  onTap: () => setSheetState(() {
                                    if (selected) {
                                      draftStars.remove(star);
                                    } else {
                                      draftStars.add(star);
                                    }
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFFFFF7ED)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: selected
                                            ? const Color(0xFFF97316)
                                            : AppColors.borderDefault,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '$star',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Color(0xFFFBBF24),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _hotelSort = draftHotelSort;
                              _busSort = draftBusSort;
                              _minPrice = draftMinPrice;
                              _maxPrice = draftMaxPrice;
                              _minRating = draftMinRating;
                              _selectedStars
                                ..clear()
                                ..addAll(draftStars);
                            });
                            Navigator.of(context).pop();
                            isHotel ? _searchHotels() : _searchBuses();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Áp dụng bộ lọc',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Consumer<CatalogProvider>(
          builder: (context, provider, _) {
            final isHotel = _mode == SearchMode.hotel;
            final isLoading = isHotel
                ? provider.isSearchingHotels
                : provider.isSearchingBuses;
            final hotelResult = provider.hotelSearchResult;
            final busResult = provider.busSearchResult;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.textHeading,
                              minimumSize: const Size(56, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: (_) =>
                                    isHotel ? _searchHotels() : _searchBuses(),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.search_rounded),
                                  hintText: 'Bạn muốn đi đâu?',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: _openFilters,
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(Icons.tune_rounded),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _ModeButton(
                              label: 'Khách sạn',
                              selected: isHotel,
                              onTap: () {
                                setState(() => _mode = SearchMode.hotel);
                                _searchHotels();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ModeButton(
                              label: 'Xe khách',
                              selected: !isHotel,
                              onTap: () {
                                setState(() => _mode = SearchMode.bus);
                                _searchBuses();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _QuickChip(
                              label: 'Gần đây',
                              selected: _isRecentSelected,
                              onTap: _toggleRecent,
                            ),
                            _QuickChip(
                              label: 'Giá rẻ nhất',
                              selected:
                                  (isHotel ? _hotelSort : _busSort) ==
                                  'priceasc',
                              onTap: _togglePriceAsc,
                            ),
                            if (isHotel)
                              _QuickChip(
                                label: '4 sao+',
                                selected: _selectedStars.contains(4) &&
                                    _selectedStars.contains(5),
                                onTap: _toggleQuickStarFilter,
                              ),
                            if (isHotel)
                              _QuickChip(
                                label: 'Đánh giá cao',
                                selected: _hotelSort == 'ratingdesc',
                                onTap: _toggleHotelRatingDesc,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => isHotel ? _searchHotels() : _searchBuses(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isHotel
                                    ? 'Tìm thấy ${hotelResult.total} kết quả'
                                    : 'Tìm thấy ${busResult.total} chuyến xe',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Việt Nam'
                                  : _searchController.text,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        else if (isHotel)
                          if (hotelResult.items.isEmpty)
                            _EmptyState(
                              message:
                                  provider.error ??
                                  'Chưa có khách sạn phù hợp với bộ lọc hiện tại.',
                              onRetry: _openFilters,
                            )
                          else
                            ...hotelResult.items.map(
                              (hotel) => Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: _HotelCard(
                                  hotel: hotel,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            HotelDetailView(hotelId: hotel.id),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            )
                        else if (busResult.items.isEmpty)
                          _EmptyState(
                            message:
                                provider.error ??
                                'Chưa có tuyến xe phù hợp với bộ lọc hiện tại.',
                            onRetry: _openFilters,
                          )
                        else
                          ...busResult.items.map(
                            (bus) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _BusCard(
                                bus: bus,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          BusDetailView(scheduleId: bus.id),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textHeading,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF7CEB8A) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.borderDefault,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textHeading,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _HotelCard extends StatelessWidget {
  const _HotelCard({required this.hotel, required this.onTap});

  final CatalogHotelCard hotel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: Image.network(
                    hotel.imageUrl,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Container(height: 250, color: const Color(0xFFE2E8F0)),
                  ),
                ),
                if (hotel.tag != null && hotel.tag!.isNotEmpty)
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        hotel.tag!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border_rounded),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotel.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textHeading,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFBBF24),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${hotel.rating} (${hotel.reviewCount} đánh giá)',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                hotel.address.isEmpty
                                    ? hotel.destinationName
                                    : hotel.address,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppCurrencyFormatter.format(hotel.pricePerNight),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Mỗi đêm',
                        style: TextStyle(color: AppColors.textMuted),
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bus.companyName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${bus.fromDestination} → ${bus.toDestination}',
                    style: const TextStyle(color: AppColors.textHeading),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ghế: ${bus.totalSeats} • ${bus.rating}★',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppCurrencyFormatter.format(bus.price),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(
            Icons.travel_explore_rounded,
            size: 52,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Điều chỉnh bộ lọc'),
          ),
        ],
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  const _RadioTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textHeading,
                ),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: selected
                      ? const Color(0xFFF97316)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: selected
                  ? const Center(
                      child: CircleAvatar(
                        radius: 6,
                        backgroundColor: Color(0xFFF97316),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceTile extends StatelessWidget {
  const _PriceTile({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Text(
            AppCurrencyFormatter.format(value),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textHeading,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFF97316) : AppColors.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFFF97316) : AppColors.textHeading,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
