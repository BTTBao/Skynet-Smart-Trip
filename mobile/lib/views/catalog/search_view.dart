import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/bus_schedule_model.dart';
import '../../models/catalog_models.dart';
import '../../providers/bus_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/destination_provider.dart';
import '../../utils/app_currency_formatter.dart';
import '../transport/transport_checkout_screen.dart';
import 'hotel_detail_view.dart';

enum SearchMode { hotel, bus }

class SearchView extends StatefulWidget {
  const SearchView({
    super.key,
    this.initialMode = SearchMode.hotel,
    this.initialDestinationId,
    this.initialQuery,
    this.showBackButton = true,
  });

  final SearchMode initialMode;
  final bool showBackButton;
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
  int? _fromDestId;
  String _fromDestName = 'Chọn điểm đi';
  int? _toDestId;
  String _toDestName = 'Chọn điểm đến';
  DateTime _selectedBusDate = DateTime.now().add(const Duration(days: 2));
  bool _isPreparingBusSearch = false;
  int _selectedBusFilterIndex = 0;

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
      await _prepareBusSearch();
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

  Future<void> _prepareBusSearch() async {
    if (_isPreparingBusSearch) {
      return;
    }

    _isPreparingBusSearch = true;
    final destProvider = context.read<DestinationProvider>();

    if (destProvider.destinations.isEmpty) {
      await destProvider.fetchDestinations(forceRefresh: true);
    }

    if (!mounted) {
      _isPreparingBusSearch = false;
      return;
    }

    if (destProvider.destinations.isNotEmpty) {
      if (_toDestId == null &&
          (widget.initialDestinationId != null ||
              widget.initialQuery != null)) {
        final toMatch = destProvider.destinations.firstWhere(
          (d) =>
              widget.initialDestinationId != null &&
              d.id == widget.initialDestinationId,
          orElse: () {
            final q = widget.initialQuery ?? '';
            return destProvider.destinations.firstWhere(
              (d) =>
                  d.name.toLowerCase() == q.toLowerCase() ||
                  d.name.toLowerCase().contains(q.toLowerCase()),
              orElse: () => destProvider.destinations.first,
            );
          },
        );
        if (mounted) {
          setState(() {
            _toDestId = toMatch.id;
            _toDestName = toMatch.name;
          });
        }
      }
    }

    _isPreparingBusSearch = false;
    _loadBusSchedules();
  }

  void _loadBusSchedules() {
    if (_fromDestId == null || _toDestId == null || _fromDestId == _toDestId) {
      return;
    }
    final dateStr =
        '${_selectedBusDate.year}-${_selectedBusDate.month.toString().padLeft(2, '0')}-${_selectedBusDate.day.toString().padLeft(2, '0')}';
    context.read<BusProvider>().fetchSchedules(
      fromDestId: _fromDestId,
      toDestId: _toDestId,
      date: dateStr,
    );
  }

  void _swapDestinations() {
    setState(() {
      final tempId = _fromDestId;
      final tempName = _fromDestName;
      _fromDestId = _toDestId;
      _fromDestName = _toDestId == null ? 'Chọn điểm đi' : _toDestName;
      _toDestId = tempId;
      _toDestName = tempId == null ? 'Chọn điểm đến' : tempName;
    });
    _loadBusSchedules();
  }

  String _formatDate(DateTime dt) => '${dt.day} Tháng ${dt.month}, ${dt.year}';

  void _changeFromDestination(int id, String name) {
    setState(() {
      _fromDestId = id;
      _fromDestName = name;
    });
    _loadBusSchedules();
  }

  void _changeToDestination(int id, String name) {
    setState(() {
      _toDestId = id;
      _toDestName = name;
    });
    _loadBusSchedules();
  }

  Future<void> _selectBusDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBusDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D6B42),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || picked == _selectedBusDate) {
      return;
    }

    setState(() => _selectedBusDate = picked);
    _loadBusSchedules();
  }

  String _formatTransportPrice(double price) {
    final formatted = price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
    return '$formattedđ';
  }

  bool get _isRecentSelected => _mode == SearchMode.hotel
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
            final isLoading = provider.isSearchingHotels;
            final hotelResult = provider.hotelSearchResult;
            final busProvider = context.watch<BusProvider>();
            final destProvider = context.watch<DestinationProvider>();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (widget.showBackButton) ...[
                            IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                              ),
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
                          ],
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: TextField(
                                controller: _searchController,
                                readOnly: !isHotel,
                                onTap: isHotel ? null : _prepareBusSearch,
                                onSubmitted: (_) => _searchHotels(),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: isHotel
                                      ? IconButton(
                                          tooltip: 'Tim khach san',
                                          onPressed: _searchHotels,
                                          icon: const Icon(
                                            Icons.arrow_forward_rounded,
                                          ),
                                        )
                                      : null,
                                  hintText: 'Bạn muốn đi đâu?',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: isHotel ? _openFilters : _loadBusSchedules,
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
                                _prepareBusSearch();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (isHotel)
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
                                selected: _hotelSort == 'priceasc',
                                onTap: _togglePriceAsc,
                              ),
                              _QuickChip(
                                label: '4 sao+',
                                selected:
                                    _selectedStars.contains(4) &&
                                    _selectedStars.contains(5),
                                onTap: _toggleQuickStarFilter,
                              ),
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
                    onRefresh: () => isHotel
                        ? _searchHotels()
                        : Future.sync(_loadBusSchedules),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      children: [
                        if (isHotel) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Tìm thấy ${hotelResult.total} kết quả',
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
                          else if (hotelResult.items.isEmpty)
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
                            ),
                        ] else
                          ..._buildIntegratedBusSearch(
                            busProvider,
                            destProvider,
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

  List<Widget> _buildIntegratedBusSearch(
    BusProvider busProvider,
    DestinationProvider destProvider,
  ) {
    return [
      _buildBusSearchForm(destProvider),
      const SizedBox(height: 16),
      _buildBusFilters(),
      const SizedBox(height: 18),
      if (_fromDestId == null || _toDestId == null)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_bus_filled_outlined,
                  color: Colors.grey,
                  size: 54,
                ),
                SizedBox(height: 12),
                Text(
                  'Vui lòng chọn điểm đi và điểm đến',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Chọn đủ thông tin để tìm kiếm chuyến xe thích hợp',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        )
      else if (_fromDestId == _toDestId)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 54,
                ),
                SizedBox(height: 12),
                Text(
                  'Tuyến đường không hợp lệ',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Điểm đi và điểm đến không thể trùng nhau.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )
      else if (busProvider.isLoadingSchedules)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF0D6B42)),
          ),
        )
      else if (busProvider.error != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Text(
              'Lỗi: ${busProvider.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        )
      else if (busProvider.schedules.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(
            child: Text(
              'Không tìm thấy chuyến xe phù hợp cho tuyến đường này.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        )
      else
        ...busProvider.schedules.map(
          (schedule) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildTransportCard(schedule),
          ),
        ),
    ];
  }

  Widget _buildBusSearchForm(DestinationProvider destProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // From
          GestureDetector(
            onTap: () => _showDestinationSelector(destProvider, isFrom: true),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D6B42).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.radio_button_checked,
                      color: Color(0xFF0D6B42),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Điểm đi',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _fromDestName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _fromDestId == null
                                ? Colors.grey[400]
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),

          // Swap divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 38,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Divider(color: Colors.grey[200]!, height: 1),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: _swapDestinations,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D6B42),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0D6B42,
                              ).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.swap_vert_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // To
          GestureDetector(
            onTap: () => _showDestinationSelector(destProvider, isFrom: false),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: Colors.orange[600],
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Điểm đến',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _toDestName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _toDestId == null
                                ? Colors.grey[400]
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),

          Divider(color: Colors.grey[100], height: 1, thickness: 1),

          // Date
          GestureDetector(
            onTap: _selectBusDate,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.blue[600],
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ngày đi',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(_selectedBusDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D6B42).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Đổi ngày',
                      style: TextStyle(
                        color: Color(0xFF0D6B42),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDestinationSelector(
    DestinationProvider destProvider, {
    required bool isFrom,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = destProvider.destinations.where((dest) {
              final name = dest.name.toLowerCase();
              final query = searchQuery.toLowerCase();
              return name.contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isFrom ? 'Chọn điểm khởi hành' : 'Chọn điểm đến',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.grey,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7F5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        onChanged: (val) =>
                            setSheetState(() => searchQuery = val),
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm địa điểm...',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Color(0xFF0D6B42),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Không tìm thấy địa điểm nào phù hợp.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, idx) {
                              final dest = filtered[idx];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 2,
                                ),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF0D6B42,
                                    ).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFF0D6B42),
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  dest.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  if (isFrom) {
                                    _changeFromDestination(dest.id, dest.name);
                                  } else {
                                    _changeToDestination(dest.id, dest.name);
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBusFilters() {
    const filters = ['Phổ biến', 'Giá thấp', 'Giờ sớm', 'Ưu tiên'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          final active = index == _selectedBusFilterIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedBusFilterIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF0D6B42) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? const Color(0xFF0D6B42) : Colors.grey[300]!,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF0D6B42,
                            ).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: active ? Colors.white : Colors.grey[700],
                    fontWeight: active ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTransportCard(BusScheduleModel schedule) {
    final dep =
        '${schedule.departureTime.hour.toString().padLeft(2, '0')}:${schedule.departureTime.minute.toString().padLeft(2, '0')}';
    final arr =
        '${schedule.arrivalTime.hour.toString().padLeft(2, '0')}:${schedule.arrivalTime.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent
              Container(
                width: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D6B42), Color(0xFF1A9058)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company row
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: schedule.companyLogoUrl.isNotEmpty
                                ? Image.network(
                                    schedule.companyLogoUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) =>
                                        _busLogoFallback(),
                                  )
                                : _busLogoFallback(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  schedule.companyName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5EE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${schedule.totalSeats} chỗ giường nằm',
                                    style: const TextStyle(
                                      color: Color(0xFF0D6B42),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Rating badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0D6B42), Color(0xFF1A9058)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  schedule.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Route
                      Row(
                        children: [
                          // Dep
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dep,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                schedule.fromDestName,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          // Line
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    schedule.duration,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0D6B42),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              height: 1.5,
                                              color: Colors.grey[200],
                                            ),
                                            const Icon(
                                              Icons.directions_bus_rounded,
                                              color: Color(0xFF0D6B42),
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey[400]!,
                                            width: 1.5,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Arr
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                arr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                schedule.toDestName,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[100], height: 1),
                      const SizedBox(height: 14),

                      // Footer
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatTransportPrice(schedule.price),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Color(0xFF0D6B42),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.event_seat_rounded,
                                      color: Colors.red[400],
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Còn ${schedule.spotsLeft} ghế',
                                      style: TextStyle(
                                        color: Colors.red[400],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showSeatSelection(schedule),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0D6B42),
                                    Color(0xFF1A9058),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0D6B42,
                                    ).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Chọn ghế',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _busLogoFallback() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF0D6B42).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.directions_bus_rounded,
        color: Color(0xFF0D6B42),
        size: 24,
      ),
    );
  }

  Future<void> _showSeatSelection(BusScheduleModel schedule) async {
    final busProvider = context.read<BusProvider>();
    busProvider.selectSchedule(schedule);

    await busProvider.fetchSeats(schedule.id);

    if (!mounted) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Consumer<BusProvider>(
          builder: (context, provider, _) {
            final seats = provider.seats;

            return Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chọn vị trí ghế ngồi - ${schedule.companyName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Tuyến: ${schedule.fromDestName} ➔ ${schedule.toDestName}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSeatLegend(Colors.grey[200]!, 'Trống'),
                      _buildSeatLegend(const Color(0xFF0D6B42), 'Đang chọn'),
                      _buildSeatLegend(Colors.red[100]!, 'Đã đặt'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Đầu Xe (Tài xế)',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: provider.isLoadingSeats
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF0D6B42),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1,
                                ),
                            itemCount: ((seats.length / 4).ceil() * 5),
                            itemBuilder: (context, index) {
                              final seatRow = index ~/ 5;
                              final seatCol = index % 5;

                              if (seatCol == 2) {
                                return const Center(
                                  child: Text(
                                    'Aisle',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }

                              final realCol = seatCol > 2
                                  ? seatCol - 1
                                  : seatCol;
                              final seatIndex = seatRow * 4 + realCol;

                              if (seatIndex >= seats.length) {
                                return const SizedBox.shrink();
                              }

                              final seat = seats[seatIndex];
                              final isSelected = provider.selectedSeatNumbers
                                  .contains(seat.seatNumber);

                              var seatBg = Colors.grey[200]!;
                              var textColor = Colors.black87;
                              if (seat.isBooked) {
                                seatBg = Colors.red[100]!;
                                textColor = Colors.red[800]!;
                              } else if (isSelected) {
                                seatBg = const Color(0xFF0D6B42);
                                textColor = Colors.white;
                              }

                              return GestureDetector(
                                onTap: seat.isBooked
                                    ? null
                                    : () => provider.toggleSeatSelection(
                                        seat.seatNumber,
                                      ),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: seatBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF0D6B42)
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Text(
                                    seat.seatNumber,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${provider.selectedSeatNumbers.length} ghế đã chọn',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _formatTransportPrice(
                                provider.selectedSeatNumbers.length *
                                    schedule.price,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Color(0xFF0D6B42),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: provider.selectedSeatNumbers.isEmpty
                              ? null
                              : () {
                                  Navigator.pop(sheetContext);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const TransportCheckoutScreen(),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6B42),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Tiếp tục',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSeatLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
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
