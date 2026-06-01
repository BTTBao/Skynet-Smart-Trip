import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/resort_model.dart';
import '../../providers/hotel_provider.dart';
import '../../widgets/checkout/checkout_stepper.dart';
import 'customer_info_screen.dart';

class BookingDateGuestScreen extends StatefulWidget {
  final ResortModel hotel;
  final RoomModel? selectedRoom;

  const BookingDateGuestScreen({Key? key, required this.hotel, this.selectedRoom}) : super(key: key);

  @override
  State<BookingDateGuestScreen> createState() => _BookingDateGuestScreenState();
}

class _BookingDateGuestScreenState extends State<BookingDateGuestScreen> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _checkIn;
  DateTime? _checkOut;

  int adultCount = 2;
  int childCount = 0;
  int infantCount = 0;

  @override
  void initState() {
    super.initState();
    adultCount = widget.selectedRoom?.capacity ?? 2;
    _fetchCalendar(_currentMonth);
  }

  void _fetchCalendar(DateTime month) {
    context.read<HotelProvider>().fetchCalendar(
      widget.hotel.id,
      year: month.year,
      month: month.month,
    );
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _fetchCalendar(_currentMonth);
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _fetchCalendar(_currentMonth);
  }

  void _onDayTap(HotelCalendarDay day) {
    if (!day.available) return;
    final date = day.dateTime;
    setState(() {
      if (_checkIn == null || (_checkIn != null && _checkOut != null)) {
        _checkIn = date;
        _checkOut = null;
      } else {
        if (date.isBefore(_checkIn!)) {
          _checkOut = _checkIn;
          _checkIn = date;
        } else if (date == _checkIn) {
          _checkIn = null;
        } else {
          _checkOut = date;
        }
      }
    });
  }

  int get nightsCount {
    if (_checkIn == null || _checkOut == null) return 0;
    return _checkOut!.difference(_checkIn!).inDays;
  }

  double get totalPrice {
    if (nightsCount == 0) return widget.selectedRoom?.pricePerNight ?? widget.hotel.minPricePerNight;
    final provider = context.read<HotelProvider>();
    // Tính tổng giá thực tế dựa trên calendar days trong khoảng đã chọn
    final days = provider.calendarDays;
    double total = 0;

    double multiplier = 1.0;
    if (widget.selectedRoom != null && widget.hotel.minPricePerNight > 0) {
      multiplier = widget.selectedRoom!.pricePerNight / widget.hotel.minPricePerNight;
    }

    for (final d in days) {
      final dt = d.dateTime;
      if (_checkIn != null && _checkOut != null &&
          !dt.isBefore(_checkIn!) && dt.isBefore(_checkOut!)) {
        total += d.price * multiplier;
      }
    }
    // Nếu không có calendar data cho tất cả các ngày thì fallback về basePrice
    return total > 0 ? total : (widget.selectedRoom?.pricePerNight ?? widget.hotel.minPricePerNight) * nightsCount;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HotelProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chọn ngày & Khách',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const CheckoutStepper(currentStep: 1),
            ),
            // Hotel mini summary card
            _buildHotelSummary(),
            const SizedBox(height: 16),
            // Calendar section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chọn ngày', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    _checkIn == null
                        ? 'Chọn ngày check-in'
                        : _checkOut == null
                            ? 'Chọn ngày check-out'
                            : '${_formatDate(_checkIn!)} → ${_formatDate(_checkOut!)} · $nightsCount đêm',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildCalendar(provider),
            ),
            // Chú thích màu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 16,
                children: [
                  _buildLegend(const Color(0xFF6DE899), 'Đã chọn'),
                  _buildLegend(const Color(0xFFD4F8E5), 'Trong khoảng'),
                  _buildLegend(Colors.grey[200]!, 'Hết phòng'),
                  _buildLegend(const Color(0xFFFFF3CD), 'Ngày lễ'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Số lượng khách',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildGuestCounter('Người lớn', 'Từ 13 tuổi trở lên', adultCount, (val) => setState(() => adultCount = val)),
                    const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 16, endIndent: 16),
                    _buildGuestCounter('Trẻ em', 'Độ tuổi 2 - 12', childCount, (val) => setState(() => childCount = val)),
                    const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 16, endIndent: 16),
                    _buildGuestCounter('Em bé', 'Dưới 2 tuổi', infantCount, (val) => setState(() => infantCount = val)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      decoration: const BoxDecoration(color: Color(0xFF6DE899), shape: BoxShape.circle),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.info_outline, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Giá phòng có thể thay đổi tùy thuộc vào ngày bạn chọn (cuối tuần, ngày lễ). Hãy đảm bảo thông tin check-in/check-out chính xác.',
                        style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildHotelSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: widget.hotel.coverImageUrl.isNotEmpty
                ? Image.network(widget.hotel.coverImageUrl, width: 60, height: 60, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.hotel, color: Colors.grey)))
                : Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.hotel, color: Colors.grey)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.hotel.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 12),
                    Text(' ${widget.hotel.avgRating} · ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text(widget.hotel.address, style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(HotelProvider provider) {
    final monthNames = ['', 'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final now = DateTime.now();
                  if (_currentMonth.year > now.year || _currentMonth.month > now.month) {
                    _prevMonth();
                  }
                },
              ),
              Text(
                '${monthNames[_currentMonth.month]} ${_currentMonth.year}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Day of week header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('T2', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('T3', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('T4', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('T5', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('T6', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('T7', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('CN', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.isLoadingCalendar)
            const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6DE899)))))
          else if (provider.calendarError != null)
            SizedBox(
              height: 160,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 32),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(provider.calendarError!, style: const TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _fetchCalendar(_currentMonth),
                      child: const Text('Thử lại', style: TextStyle(color: Color(0xFF6DE899), fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            )
          else if (provider.calendarDays.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(child: Text('Không có lịch giá cho tháng này.', style: TextStyle(color: Colors.grey))),
            )
          else
            _buildCalendarGrid(provider.calendarDays),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(List<HotelCalendarDay> days) {
    // Ngày đầu tiên trong tháng là thứ mấy? (1=T2, 7=CN)
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    int startWeekday = firstDay.weekday; // 1=Mon...7=Sun
    int leadingEmpty = startWeekday - 1;

    final totalCells = leadingEmpty + days.length;
    final totalRows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(totalRows, (rowIdx) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: List.generate(7, (colIdx) {
              final cellIdx = rowIdx * 7 + colIdx;
              final dayIdx = cellIdx - leadingEmpty;

              if (dayIdx < 0 || dayIdx >= days.length) {
                return const Expanded(child: SizedBox());
              }

              final day = days[dayIdx];
              return Expanded(child: _buildDayCell(day));
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDayCell(HotelCalendarDay day) {
    final date = day.dateTime;
    final isCheckIn = _checkIn != null && date == _checkIn;
    final isCheckOut = _checkOut != null && date == _checkOut;
    final isInRange = _checkIn != null && _checkOut != null &&
        date.isAfter(_checkIn!) && date.isBefore(_checkOut!);
    final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    Color bgColor = Colors.transparent;
    BorderRadius? borderRadius;
    Color dateColor = day.available && !isPast ? Colors.black87 : Colors.grey[400]!;
    Color priceColor = Colors.grey[500]!;
    FontWeight dateFontWeight = FontWeight.normal;

    if (!day.available || isPast) {
      bgColor = Colors.grey[100]!;
    } else if (day.isHoliday) {
      bgColor = const Color(0xFFFFF3CD);
      priceColor = const Color(0xFF856404);
    } else if (day.isWeekend) {
      priceColor = Colors.orange[600]!;
    }

    if (isCheckIn || isCheckOut) {
      bgColor = const Color(0xFF6DE899);
      dateColor = Colors.white;
      priceColor = Colors.white70;
      dateFontWeight = FontWeight.bold;
      borderRadius = BorderRadius.circular(8);
    } else if (isInRange) {
      bgColor = const Color(0xFFD4F8E5);
      dateColor = Colors.black87;
      priceColor = Colors.green[700]!;
    }

    String priceText;
    if (!day.available || isPast) {
      priceText = isPast ? '' : 'Hết';
    } else {
      priceText = _formatShortPrice(day.price);
    }

    return GestureDetector(
      onTap: () {
        if (!isPast) _onDayTap(day);
      },
      child: Container(
        decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(fontSize: 15, fontWeight: dateFontWeight, color: dateColor,
                  decoration: (!day.available && !isPast) ? TextDecoration.lineThrough : null),
            ),
            if (priceText.isNotEmpty)
              Text(priceText, style: TextStyle(fontSize: 9, color: priceColor, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildGuestCounter(String title, String subtitle, int count, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () { if (count > 0) onChanged(count - 1); },
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.green[100]!), color: Colors.white),
                  child: const Center(child: Icon(Icons.remove, color: Colors.green, size: 16)),
                ),
              ),
              SizedBox(width: 32, child: Center(child: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
              GestureDetector(
                onTap: () => onChanged(count + 1),
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF6DE899)),
                  child: const Center(child: Icon(Icons.add, color: Colors.white, size: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final hasSelection = _checkIn != null && _checkOut != null;
    final price = hasSelection ? totalPrice : widget.hotel.minPricePerNight;
    final nights = nightsCount > 0 ? nightsCount : 1;
    final guests = adultCount + childCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -2), blurRadius: 10)],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _formatPriceFull(price),
                      style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (hasSelection) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          '$nights đêm',
                          style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[500], size: 12),
                    const SizedBox(width: 4),
                    Text(
                      hasSelection
                          ? '${_formatDate(_checkIn!)} → ${_formatDate(_checkOut!)} · $guests người'
                          : '$guests người',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              onPressed: hasSelection ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerInfoScreen(
                      hotel: widget.hotel,
                      selectedRoom: widget.selectedRoom,
                      checkIn: _checkIn!,
                      checkOut: _checkOut!,
                      adultCount: adultCount,
                      childCount: childCount,
                      infantCount: infantCount,
                      totalPrice: price,
                    ),
                  ),
                );
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasSelection ? const Color(0xFF6DE899) : Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                elevation: 0,
              ),
              child: Text(
                hasSelection ? 'Tiếp tục' : 'Chọn ngày',
                style: TextStyle(color: hasSelection ? Colors.black : Colors.grey, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatShortPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    }
    return '${(price / 1000).round()}k';
  }

  String _formatPriceFull(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$formatted₫';
  }
}
