import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bus_schedule_model.dart';
import '../../providers/bus_provider.dart';
import '../../providers/destination_provider.dart';
import 'transport_checkout_screen.dart';

class TransportSearchScreen extends StatefulWidget {
  final int? toDestId;
  final String? toDestName;
  final int? initialScheduleId;

  const TransportSearchScreen({
    Key? key,
    this.toDestId,
    this.toDestName,
    this.initialScheduleId,
  }) : super(key: key);

  @override
  State<TransportSearchScreen> createState() => _TransportSearchScreenState();
}

class _TransportSearchScreenState extends State<TransportSearchScreen> {
  int? _fromDestId;
  String _fromDestName = 'Đà Nẵng';
  int? _toDestId;
  String _toDestName = 'Hội An';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));
  bool _didOpenInitialSchedule = false;

  @override
  void initState() {
    super.initState();
    _toDestId = widget.toDestId;
    if (widget.toDestName != null) {
      _toDestName = widget.toDestName!;
    } else {
      _toDestName = 'Hội An';
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final destProvider = context.read<DestinationProvider>();
      
      if (destProvider.destinations.isEmpty) {
        await destProvider.fetchDestinations(forceRefresh: true);
      }
      
      if (destProvider.destinations.isNotEmpty) {
        // Resolve default from destination (Da Nang)
        final fromMatch = destProvider.destinations.firstWhere(
          (d) => d.name.toLowerCase().contains('đà nẵng') || d.name.toLowerCase().contains('da nang'),
          orElse: () => destProvider.destinations.first,
        );
        
        // Resolve target to destination
        final toMatch = destProvider.destinations.firstWhere(
          (d) => d.name.toLowerCase() == _toDestName.toLowerCase() || d.name.toLowerCase().contains(_toDestName.toLowerCase()),
          orElse: () => destProvider.destinations.length > 1 ? destProvider.destinations[1] : destProvider.destinations.first,
        );
        
        setState(() {
          _fromDestId = fromMatch.id;
          _fromDestName = fromMatch.name;
          _toDestId = toMatch.id;
          _toDestName = toMatch.name;
        });
      }
      if (widget.initialScheduleId != null) {
        await _openInitialSchedule();
      } else {
        _loadSchedules();
      }
    });
  }

  Future<void> _loadSchedules() {
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    return context.read<BusProvider>().fetchSchedules(
      fromDestId: _fromDestId,
      toDestId: _toDestId,
      date: dateStr,
    );
  }

  Future<void> _openInitialSchedule() async {
    if (_didOpenInitialSchedule) {
      return;
    }
    _didOpenInitialSchedule = true;

    final busProvider = context.read<BusProvider>();
    await busProvider.fetchSchedules();
    if (!mounted) {
      return;
    }

    BusScheduleModel? schedule;
    for (final item in busProvider.schedules) {
      if (item.id == widget.initialScheduleId) {
        schedule = item;
        break;
      }
    }

    if (schedule == null) {
      await _loadSchedules();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy tuyến xe này.')),
      );
      return;
    }

    setState(() {
      _fromDestId = schedule!.fromDestId;
      _fromDestName = schedule.fromDestName;
      _toDestId = schedule.toDestId;
      _toDestName = schedule.toDestName;
      _selectedDate = DateTime(
        schedule.departureTime.year,
        schedule.departureTime.month,
        schedule.departureTime.day,
      );
    });
    _showSeatSelection(context, schedule);
  }

  void _changeFromDest(int id, String name) {
    setState(() {
      _fromDestId = id;
      _fromDestName = name;
    });
    _loadSchedules();
  }

  void _changeToDest(int id, String name) {
    setState(() {
      _toDestId = id;
      _toDestName = name;
    });
    _loadSchedules();
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadSchedules();
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day} Thg ${dt.month}';
  }

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$formattedđ';
  }

  @override
  Widget build(BuildContext context) {
    final busProvider = context.watch<BusProvider>();
    final destProvider = context.watch<DestinationProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D6B42)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Vé Xe Limousine', style: TextStyle(color: Color(0xFF0D6B42), fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSearchForm(destProvider),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildFilters(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: busProvider.isLoadingSchedules
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D6B42))))
                : busProvider.error != null
                    ? Center(child: Text('Lỗi: ${busProvider.error}', style: const TextStyle(color: Colors.red)))
                    : busProvider.schedules.isEmpty
                        ? const Center(child: Text('Không tìm thấy chuyến xe phù hợp cho tuyến đường này.', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: busProvider.schedules.length,
                            itemBuilder: (context, index) {
                              final schedule = busProvider.schedules[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: _buildTransportCard(context, schedule),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchForm(DestinationProvider destProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showDestSelector(context, destProvider, isFrom: true),
            child: _buildFormRow(Icons.location_on, 'Điểm đi: $_fromDestName'),
          ),
          const Divider(height: 24, indent: 36),
          GestureDetector(
            onTap: () => _showDestSelector(context, destProvider, isFrom: false),
            child: _buildFormRow(Icons.navigation, 'Điểm đến: $_toDestName'),
          ),
          const Divider(height: 24, indent: 36),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: _buildFormRow(Icons.calendar_today, 'Ngày đi: ${_formatDate(_selectedDate)}'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0D6B42), size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        ),
        const Icon(Icons.arrow_drop_down, color: Colors.grey),
      ],
    );
  }

  void _showDestSelector(BuildContext context, DestinationProvider destProvider, {required bool isFrom}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  isFrom ? 'Chọn điểm khởi hành' : 'Chọn điểm đến',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: destProvider.destinations.length,
                  itemBuilder: (context, idx) {
                    final dest = destProvider.destinations[idx];
                    return ListTile(
                      title: Text(dest.name),
                      onTap: () {
                        Navigator.pop(context);
                        if (isFrom) {
                          _changeFromDest(dest.id, dest.name);
                        } else {
                          _changeToDest(dest.id, dest.name);
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
  }

  Widget _buildFilters() {
    final filters = ['Phổ biến nhất', 'Giá thấp nhất', 'Giờ chạy sớm nhất', 'Nhà xe ưu tiên'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = index == 0;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filters[index]),
              selected: isSelected,
              onSelected: (val) {},
              selectedColor: const Color(0xFF0D6B42),
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTransportCard(BuildContext context, BusScheduleModel schedule) {
    final departureStr = '${schedule.departureTime.hour.toString().padLeft(2, '0')}:${schedule.departureTime.minute.toString().padLeft(2, '0')}';
    final arrivalStr = '${schedule.arrivalTime.hour.toString().padLeft(2, '0')}:${schedule.arrivalTime.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: schedule.companyLogoUrl.isNotEmpty
                        ? Image.network(schedule.companyLogoUrl, width: 40, height: 40, fit: BoxFit.cover, 
                            errorBuilder: (_, __, ___) => Container(width: 40, height: 40, color: Colors.grey[200], child: const Icon(Icons.directions_bus, color: Colors.grey)))
                        : Container(width: 40, height: 40, color: Colors.grey[200], child: const Icon(Icons.directions_bus, color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(schedule.companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('${schedule.totalSeats} CHỖ GIƯỜNG NẰM', style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFF0D6B42), size: 14),
                  const SizedBox(width: 4),
                  Text(schedule.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D6B42), fontSize: 13)),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(departureStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  Text(schedule.fromDestName, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(schedule.duration, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      Row(
                        children: [
                          const Icon(Icons.circle, size: 8, color: Color(0xFF0D6B42)),
                          Expanded(child: Container(height: 1, color: Colors.grey[300])),
                          const Icon(Icons.directions_bus, size: 16, color: Color(0xFF0D6B42)),
                          Expanded(child: Container(height: 1, color: Colors.grey[300])),
                          Icon(Icons.circle, size: 8, color: Colors.grey[300]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  Text(arrivalStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  Text(schedule.toDestName, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatPrice(schedule.price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0D6B42))),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.red, size: 12),
                      const SizedBox(width: 4),
                      Text('Còn ${schedule.spotsLeft} ghế trống', style: const TextStyle(color: Colors.red, fontSize: 11)),
                    ],
                  )
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  _showSeatSelection(context, schedule);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6B42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
                child: const Text('Chọn ghế', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }

  void _showSeatSelection(BuildContext context, BusScheduleModel schedule) async {
    final busProvider = context.read<BusProvider>();
    busProvider.selectSchedule(schedule);
    
    // Tải sơ đồ ghế ngồi
    await busProvider.fetchSeats(schedule.id);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Consumer<BusProvider>(
          builder: (context, provider, child) {
            final seats = provider.seats;

            return Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Text('Chọn vị trí ghế ngồi - ${schedule.companyName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Tuyến: ${schedule.fromDestName} ➔ ${schedule.toDestName}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 24),
                  
                  // Chú thích
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSeatLegend(Colors.grey[200]!, 'Trống'),
                      _buildSeatLegend(const Color(0xFF0D6B42), 'Đang chọn'),
                      _buildSeatLegend(Colors.red[100]!, 'Đã đặt'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Đầu Xe (Tài xế)', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Sơ đồ ghế
                  Expanded(
                    child: provider.isLoadingSeats
                        ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D6B42))))
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5, // 2 ghế trái, 1 lối đi, 2 ghế phải
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: ((seats.length / 4).ceil() * 5),
                            itemBuilder: (context, index) {
                              final seatRow = index ~/ 5;
                              final seatCol = index % 5;

                              // Cột lối đi ở giữa
                              if (seatCol == 2) {
                                return const Center(
                                  child: Text('Aisle', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                                );
                              }

                              final realCol = seatCol > 2 ? seatCol - 1 : seatCol;
                              final seatIndex = seatRow * 4 + realCol;

                              if (seatIndex >= seats.length) {
                                return const SizedBox.shrink();
                              }

                              final seat = seats[seatIndex];
                              final isSelected = provider.selectedSeatNumbers.contains(seat.seatNumber);
                              
                              Color seatBg = Colors.grey[200]!;
                              Color textCol = Colors.black87;
                              if (seat.isBooked) {
                                seatBg = Colors.red[100]!;
                                textCol = Colors.red[800]!;
                              } else if (isSelected) {
                                seatBg = const Color(0xFF0D6B42);
                                textCol = Colors.white;
                              }

                              return GestureDetector(
                                onTap: seat.isBooked ? null : () {
                                  provider.toggleSeatSelection(seat.seatNumber);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: seatBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF0D6B42) : Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    seat.seatNumber,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textCol),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Bottom bar trong sheet
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${provider.selectedSeatNumbers.length} ghế đã chọn', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              _formatPrice(provider.selectedSeatNumbers.length * schedule.price),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0D6B42)),
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
                                    MaterialPageRoute(builder: (_) => const TransportCheckoutScreen())
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6B42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Tiếp tục', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  )
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
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
