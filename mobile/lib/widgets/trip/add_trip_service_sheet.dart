import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bus_schedule_model.dart';
import '../../models/create_trip_itinerary_request.dart';
import '../../models/destination.dart';
import '../../models/resort_model.dart';
import '../../models/trip_service_option.dart';
import '../../providers/bus_provider.dart';
import '../../providers/destination_provider.dart';
import '../../providers/hotel_provider.dart';
import '../../providers/trip_provider.dart';
import '../../views/checkout/booking_date_guest_screen.dart';
import '../../views/trip/trip_ui_constants.dart';
import 'place_search_field.dart';

class TripBusCheckoutRequest {
  const TripBusCheckoutRequest({
    required this.tripId,
    required this.dayNumber,
  });

  final int tripId;
  final int dayNumber;
}

class AddTripServiceSheet extends StatefulWidget {
  const AddTripServiceSheet({
    super.key,
    required this.tripId,
    required this.dayNumber,
    required this.initialServiceDate,
    this.destinationId,
    this.destinationName,
    this.tripStartDate,
    this.tripEndDate,
  });

  final int tripId;
  final int dayNumber;
  final DateTime initialServiceDate;
  final int? destinationId;
  final String? destinationName;
  final DateTime? tripStartDate;
  final DateTime? tripEndDate;

  @override
  State<AddTripServiceSheet> createState() => _AddTripServiceSheetState();
}

class _AddTripServiceSheetState extends State<AddTripServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedServiceType = 'NOTE';
  TripServiceOption? _selectedOption;
  late Future<List<TripServiceOption>> _optionsFuture;
  late DateTime _selectedServiceDate;
  TimeOfDay? _selectedDepartureTime;
  int? _busFromDestId;
  int? _busToDestId;
  BusScheduleModel? _selectedBusSchedule;
  int _seatSelectionToken = 0;
  int? _loadingSeatScheduleId;
  String _searchAddress = '';

  bool get _isNote => _selectedServiceType == 'NOTE';
  bool get _isBus => _selectedServiceType == 'BUS';
  bool get _isHotel => _selectedServiceType == 'HOTEL';

  /// Resolves the trip destination selected when the trip was created.
  String? get _resolvedDestinationName {
    final direct = widget.destinationName?.trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final id = widget.destinationId;
    if (id == null) return null;
    final destinations = context.read<DestinationProvider>().destinations;
    for (final d in destinations) {
      if (d.id == id) return d.name;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _selectedServiceDate = DateTime(
      widget.initialServiceDate.year,
      widget.initialServiceDate.month,
      widget.initialServiceDate.day,
    );
    _optionsFuture = _loadOptions();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapBusForm());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<List<TripServiceOption>> _loadOptions() {
    return context.read<TripProvider>().getServiceOptions(
          serviceType: _selectedServiceType,
          destinationId: widget.destinationId,
        );
  }

  Future<void> _bootstrapBusForm() async {
    if (!mounted) {
      return;
    }

    final destinationProvider = context.read<DestinationProvider>();
    if (destinationProvider.destinations.isEmpty) {
      await destinationProvider.fetchDestinations(forceRefresh: true);
    }

    if (!mounted || destinationProvider.destinations.isEmpty) {
      return;
    }

    final destinations = destinationProvider.destinations;
    final initialTo = widget.destinationId != null
        ? destinations.firstWhere(
            (destination) => destination.id == widget.destinationId,
            orElse: () => destinations.length > 1 ? destinations[1] : destinations.first,
          )
        : (destinations.length > 1 ? destinations[1] : destinations.first);
    final initialFrom = destinations.firstWhere(
      (destination) => destination.id != initialTo.id,
      orElse: () => destinations.first,
    );

    setState(() {
      _busFromDestId = initialFrom.id;
      _busToDestId = initialTo.id;
    });

    if (_isBus) {
      _loadBusSchedules();
    }
  }

  String _dateQuery(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _clearBusProviderSelection() {
    context.read<BusProvider>().selectSchedule(null);
  }

  Future<void> _loadBusSchedules() async {
    final fromDestId = _busFromDestId;
    final toDestId = _busToDestId;
    if (!_isBus || fromDestId == null || toDestId == null || fromDestId == toDestId) {
      return;
    }

    await context.read<BusProvider>().fetchSchedules(
          fromDestId: fromDestId,
          toDestId: toDestId,
          date: _dateQuery(_selectedServiceDate),
        );
  }

  Destination? _destinationById(int? id) {
    if (id == null) {
      return null;
    }

    final destinations = context.read<DestinationProvider>().destinations;
    for (final destination in destinations) {
      if (destination.id == id) {
        return destination;
      }
    }

    return null;
  }

  Future<void> _showBusDestinationPicker({required bool isFrom}) async {
    final destinationProvider = context.read<DestinationProvider>();
    if (destinationProvider.destinations.isEmpty) {
      await destinationProvider.fetchDestinations(forceRefresh: true);
    }

    if (!mounted) {
      return;
    }

    final selected = await showModalBottomSheet<Destination>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        final destinations = context.read<DestinationProvider>().destinations;
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: Text(
                    isFrom ? 'Chọn điểm đi' : 'Chọn điểm đến',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: TripUiColors.textPrimary,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: destinations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final destination = destinations[index];
                      final disabled = isFrom
                          ? destination.id == _busToDestId
                          : destination.id == _busFromDestId;
                      return ListTile(
                        enabled: !disabled,
                        leading: const Icon(Icons.place_outlined),
                        title: Text(destination.name),
                        subtitle: disabled ? const Text('Không thể trùng điểm còn lại') : null,
                        onTap: disabled ? null : () => Navigator.pop(sheetContext, destination),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      if (isFrom) {
        _busFromDestId = selected.id;
      } else {
        _busToDestId = selected.id;
      }
      _selectedBusSchedule = null;
      _loadingSeatScheduleId = null;
      _seatSelectionToken++;
    });
    _clearBusProviderSelection();
    _loadBusSchedules();
  }

  void _onServiceTypeChanged(String serviceType) {
    setState(() {
      _selectedServiceType = serviceType;
      _selectedOption = null;
      _priceController.clear();
      _optionsFuture = _loadOptions();
      if (serviceType != 'BUS') {
        _selectedBusSchedule = null;
        _loadingSeatScheduleId = null;
        _seatSelectionToken++;
      }
    });
    if (serviceType != 'BUS') {
      _clearBusProviderSelection();
    }
    if (serviceType == 'BUS') {
      _loadBusSchedules();
    }
  }

  Future<void> _pickServiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedServiceDate,
      firstDate: widget.tripStartDate ?? DateTime(2020, 1, 1),
      lastDate: widget.tripEndDate ?? DateTime(2100, 12, 31),
      helpText: 'Chọn ngày đi',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedServiceDate = DateTime(picked.year, picked.month, picked.day);
      if (_isBus) {
        _selectedBusSchedule = null;
        _loadingSeatScheduleId = null;
        _seatSelectionToken++;
      }
    });
    if (_isBus) {
      _clearBusProviderSelection();
      _loadBusSchedules();
    }
  }

  Future<void> _pickDepartureTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedDepartureTime ?? TimeOfDay.now(),
      helpText: 'Chọn giờ khởi hành',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDepartureTime = picked;
    });
  }

  int _resolveDayNumber() {
    final startDate = widget.tripStartDate;
    if (startDate == null) {
      return widget.dayNumber;
    }

    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final dayOffset = _selectedServiceDate.difference(normalizedStart).inDays;
    return dayOffset + 1;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isBus) {
      final schedule = _selectedBusSchedule;
      final selectedSeats = context.read<BusProvider>().selectedSeatNumbers;
      if (schedule == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn chuyến xe.')),
        );
        return;
      }

      if (selectedSeats.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ít nhất một ghế.')),
        );
        return;
      }

      Navigator.of(context).pop(
        TripBusCheckoutRequest(
          tripId: widget.tripId,
          dayNumber: _resolveDayNumber(),
        ),
      );
      return;
    }

    if (_isHotel) {
      final option = _selectedOption;
      if (option == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn khách sạn.')),
        );
        return;
      }
      _openHotelBooking(option);
      return;
    }

    if (!_isNote && _selectedOption == null) {
      return;
    }

    if (_isNote && _searchAddress.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập và chọn địa điểm.')),
      );
      return;
    }

    if (_selectedDepartureTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isNote ? 'Vui lòng chọn thời gian ghi chú.' : 'Vui lòng chọn giờ khởi hành.'),
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
    final price = double.tryParse(
      _priceController.text.trim().replaceAll(',', ''),
    );
    final departure = _selectedDepartureTime!;
    final departureText =
        '${departure.hour.toString().padLeft(2, '0')}:${departure.minute.toString().padLeft(2, '0')}:00';

    String combinedAddress = _searchAddress.trim();
    if (_isNote && _addressController.text.trim().isNotEmpty) {
      combinedAddress = '$combinedAddress\n${_addressController.text.trim()}';
    } else if (!_isNote) {
      combinedAddress = _addressController.text.trim();
    }

    Navigator.of(context).pop(
      CreateTripItineraryRequest(
        dayNumber: _resolveDayNumber(),
        serviceType: _isNote ? 'NOTE' : _selectedOption!.serviceType,
        serviceId: _isNote ? 1 : _selectedOption!.serviceId,
        quantity: _isNote ? 1 : quantity,
        adultCount: !_isNote && _selectedOption!.serviceType.toUpperCase() == 'HOTEL'
            ? quantity
            : 1,
        bookedPrice: _isNote ? 0 : price,
        bookedCommissionRate: _isNote ? 0 : _selectedOption!.defaultCommissionRate,
        serviceDate: _selectedServiceDate,
        departureTime: departureText,
        serviceAddress: combinedAddress,
      ),
    );
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _timeLabel(TimeOfDay? time) {
    if (time == null) {
      return 'Chọn giờ khởi hành';
    }
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _timeText(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _moneyText(double value) {
    final text = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer} VND';
  }

  Future<void> _selectBusSchedule(BusScheduleModel schedule) async {
    final token = ++_seatSelectionToken;
    setState(() {
      _selectedBusSchedule = schedule;
      _loadingSeatScheduleId = schedule.id;
    });
    final busProvider = context.read<BusProvider>();
    busProvider.selectSchedule(schedule);
    try {
      await busProvider.fetchSeats(schedule.id);
      if (!mounted) {
        return;
      }
      if (token != _seatSelectionToken || busProvider.selectedSchedule?.id != schedule.id) {
        return;
      }
      _showBusSeatSelection(schedule);
    } finally {
      if (mounted && token == _seatSelectionToken) {
        setState(() {
          _loadingSeatScheduleId = null;
        });
      }
    }
  }

  Future<void> _openHotelBooking(TripServiceOption option) async {
    final navigator = Navigator.of(context);
    final hotelProvider = context.read<HotelProvider>();
    await hotelProvider.fetchHotelDetail(option.serviceId, forceRefresh: true);

    if (!mounted) {
      return;
    }

    final hotel = hotelProvider.selectedHotel;
    if (hotel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hotelProvider.detailError ?? 'Không tải được khách sạn.')),
      );
      return;
    }

    final availableRooms = hotel.rooms
        .where((room) => room.availableQty > 0)
        .toList(growable: false);

    if (availableRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khách sạn hiện không còn phòng trống.')),
      );
      return;
    }

    var selectedRoom = availableRooms.first;
    if (availableRooms.length > 1) {
      final pickedRoom = await showModalBottomSheet<RoomModel>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              shrinkWrap: true,
              itemCount: availableRooms.length + 1,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Chọn hạng phòng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: TripUiColors.textPrimary,
                      ),
                    ),
                  );
                }

                final room = availableRooms[index - 1];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    room.roomType,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'Sức chứa ${room.capacity} người • Còn ${room.availableQty} phòng',
                  ),
                  trailing: Text(
                    _moneyText(room.pricePerNight),
                    style: const TextStyle(
                      color: TripUiColors.timelineGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(room),
                );
              },
            ),
          );
        },
      );

      if (pickedRoom == null || !mounted) {
        return;
      }
      selectedRoom = pickedRoom;
    }

    navigator.pop();
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => BookingDateGuestScreen(
          hotel: hotel,
          selectedRoom: selectedRoom,
          existingTripId: widget.tripId,
          existingTripDayNumber: widget.dayNumber,
          existingTripStartDate: widget.tripStartDate,
          existingTripEndDate: widget.tripEndDate,
          initialCheckIn: _selectedServiceDate,
        ),
      ),
    );
  }

  void _showBusSeatSelection(BusScheduleModel schedule) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Consumer<BusProvider>(
          builder: (context, provider, child) {
            final seats = provider.seats;
            final selectedSeats = provider.selectedSeatNumbers;
            final total = selectedSeats.length * schedule.price;
            final isCurrentSchedule = provider.selectedSchedule?.id == schedule.id;

            return Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(sheetContext).size.height * 0.75,
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
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Tuyến: ${schedule.fromDestName} → ${schedule.toDestName}',
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
                    child: !isCurrentSchedule
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0D6B42),
                              ),
                            ),
                          )
                        : provider.isLoadingSeats
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0D6B42),
                              ),
                            ),
                          )
                        : provider.seatError != null
                            ? Center(
                                child: Text(
                                  provider.seatError!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                            : GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1.0,
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

                                  final realCol = seatCol > 2 ? seatCol - 1 : seatCol;
                                  final seatIndex = seatRow * 4 + realCol;

                                  if (seatIndex >= seats.length) {
                                    return const SizedBox.shrink();
                                  }

                                  final seat = seats[seatIndex];
                                  final isSelected = selectedSeats.contains(seat.seatNumber);
                                  final isUnavailable = seat.isBooked || seat.isLocked;

                                  Color seatBg = Colors.grey[200]!;
                                  Color textColor = Colors.black87;
                                  if (isUnavailable) {
                                    seatBg = Colors.red[100]!;
                                    textColor = Colors.red[800]!;
                                  } else if (isSelected) {
                                    seatBg = const Color(0xFF0D6B42);
                                    textColor = Colors.white;
                                  }

                                  return GestureDetector(
                                    onTap: isUnavailable
                                        ? null
                                        : () => provider.toggleSeatSelection(seat.seatNumber),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: seatBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF0D6B42)
                                              : Colors.grey[300]!,
                                          width: 1,
                                        ),
                                      ),
                                      alignment: Alignment.center,
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
                              '${selectedSeats.length} ghế đã chọn',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              _moneyText(total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Color(0xFF0D6B42),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: selectedSeats.isEmpty || !isCurrentSchedule
                              ? null
                              : () {
                                  Navigator.pop(sheetContext);
                                  Navigator.of(context).pop(
                                    TripBusCheckoutRequest(
                                      tripId: widget.tripId,
                                      dayNumber: _resolveDayNumber(),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6B42),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildBusPlanner(
    BusProvider busProvider,
    DestinationProvider destinationProvider,
  ) {
    final from = _destinationById(_busFromDestId);
    final to = _destinationById(_busToDestId);
    final hasSameDestination = _busFromDestId != null && _busFromDestId == _busToDestId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SheetNotice(
          text: 'Chọn điểm đi, điểm đến và ngày đi để lọc các chuyến xe phù hợp. Sau khi chọn chuyến, bạn chọn ghế ngay bên dưới.',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _BusSelectButton(
                icon: Icons.trip_origin_rounded,
                title: 'Điểm đi',
                label: from?.name ?? 'Chọn điểm đi',
                onTap: () => _showBusDestinationPicker(isFrom: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BusSelectButton(
                icon: Icons.place_rounded,
                title: 'Điểm đến',
                label: to?.name ?? 'Chọn điểm đến',
                onTap: widget.destinationId == null
                    ? () => _showBusDestinationPicker(isFrom: false)
                    : null,
              ),
            ),
          ],
        ),
        if (widget.destinationId != null) ...[
          const SizedBox(height: 8),
          const Text(
            'Điểm đến được khóa theo điểm đến của chuyến đi.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TripUiColors.textSecondary,
            ),
          ),
        ],
        if (hasSameDestination) ...[
          const SizedBox(height: 8),
          const Text(
            'Điểm đi và điểm đến không được trùng nhau.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD14343),
            ),
          ),
        ],
        const SizedBox(height: 14),
        const _SheetLabel('Ngày đi'),
        const SizedBox(height: 10),
        _SelectFieldButton(
          icon: Icons.calendar_month_rounded,
          label: _dateLabel(_selectedServiceDate),
          onTap: _pickServiceDate,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: _SheetLabel('Chuyến xe phù hợp')),
            if (busProvider.isLoadingSchedules)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (destinationProvider.isLoading && destinationProvider.destinations.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (hasSameDestination)
          const _SheetNotice(text: 'Hãy chọn hai địa điểm khác nhau để tìm chuyến xe.')
        else if (busProvider.scheduleError != null)
          _SheetNotice(text: busProvider.scheduleError!)
        else if (busProvider.schedules.isEmpty && !busProvider.isLoadingSchedules)
          const _SheetNotice(text: 'Không có chuyến xe phù hợp trong ngày đã chọn.')
        else
          _buildBusScheduleList(busProvider.schedules),
      ],
    );
  }

  Widget _buildBusScheduleList(List<BusScheduleModel> schedules) {
    final listHeight = schedules.length > 3 ? 330.0 : schedules.length * 112.0;
    return SizedBox(
      height: listHeight,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: schedules.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final schedule = schedules[index];
          final isSelected = _selectedBusSchedule?.id == schedule.id;
          final isLoadingSeats = _loadingSeatScheduleId == schedule.id;
          return InkWell(
            onTap: schedule.spotsLeft <= 0 || _loadingSeatScheduleId != null
                ? null
                : () => _selectBusSchedule(schedule),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEAFBF1) : const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? TripUiColors.timelineGreen : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          schedule.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: TripUiColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _moneyText(schedule.price),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: TripUiColors.timelineGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_timeText(schedule.departureTime)} - ${_timeText(schedule.arrivalTime)} • ${schedule.duration}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: TripUiColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${schedule.fromDestName} → ${schedule.toDestName} • Còn ${schedule.spotsLeft}/${schedule.totalSeats} ghế',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TripUiColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: schedule.spotsLeft <= 0
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFFEAFBF1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        schedule.spotsLeft <= 0
                            ? 'Hết ghế'
                            : isLoadingSeats
                                ? 'Đang tải ghế'
                                : 'Chọn ghế',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: schedule.spotsLeft <= 0
                              ? TripUiColors.textSecondary
                              : TripUiColors.timelineGreen,
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final busProvider = context.watch<BusProvider>();
    final destinationProvider = context.watch<DestinationProvider>();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DDE3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Thêm dịch vụ cho ngày ${widget.dayNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: TripUiColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bổ sung ngày, giờ và địa chỉ để tối ưu hiển thị lộ trình trên bản đồ.',
                style: TextStyle(
                  fontSize: 13,
                  color: TripUiColors.textSecondary,
                ),
              ),

              if (_isBus) ...[
                const SizedBox(height: 16),
                _buildBusPlanner(busProvider, destinationProvider),
              ] else if (!_isNote) ...[
                const SizedBox(height: 16),
                const _SheetLabel('Danh sách dịch vụ'),
                const SizedBox(height: 10),
                FutureBuilder<List<TripServiceOption>>(
                  future: _optionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return const _SheetNotice(
                        text:
                            'Không tải được danh sách dịch vụ. Thử đóng lại sheet để thử lại.',
                      );
                    }

                    final options = snapshot.data ?? const <TripServiceOption>[];
                    if (options.isEmpty) {
                      return const _SheetNotice(
                        text: 'Không có dịch vụ phù hợp cho điểm đến này.',
                      );
                    }

                    return DropdownButtonFormField<TripServiceOption>(
                      value: _selectedOption,
                      items: options.map((option) {
                        return DropdownMenuItem<TripServiceOption>(
                          value: option,
                          child: Text(option.title),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value;
                          _priceController.text =
                              value?.defaultPrice?.toStringAsFixed(0) ?? '';
                        });
                        if (value != null && _isHotel) {
                          _openHotelBooking(value);
                        }
                      },
                      validator: (value) => value == null ? 'Chọn một dịch vụ' : null,
                      decoration: InputDecoration(
                        hintText: 'Chọn dịch vụ',
                        filled: true,
                        fillColor: const Color(0xFFF1F4F6),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    );
                  },
                ),
              ] else ...[
                const SizedBox(height: 16),
                const _SheetNotice(
                  text: 'Ghi lại nơi bạn muốn đi, việc cần làm hoặc thời gian hẹn trong chuyến đi.',
                ),
              ],
              if (!_isBus && !_isNote && _selectedOption != null) ...[
                const SizedBox(height: 12),
                _SheetNotice(
                  text: _selectedOption!.subtitle ?? 'Không có mô tả thêm.',
                ),
              ],
              if (_isNote) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SheetLabel('Ngày đi'),
                        const SizedBox(height: 10),
                        _SelectFieldButton(
                          icon: Icons.calendar_month_rounded,
                          label: _dateLabel(_selectedServiceDate),
                          onTap: _pickServiceDate,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SheetLabel('Thời gian (bắt buộc)'),
                        const SizedBox(height: 10),
                        _SelectFieldButton(
                          icon: Icons.access_time_rounded,
                          label: _timeLabel(_selectedDepartureTime),
                          onTap: _pickDepartureTime,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PlaceSearchField(
                labelText: 'Địa điểm',
                hintText: 'Nhập địa điểm để vẽ trên bản đồ...',
                initialValue: _searchAddress.isNotEmpty ? _searchAddress : null,
                destinationName: _resolvedDestinationName,
                onAddressConfirmed: (address) {
                  setState(() {
                    _searchAddress = address;
                  });
                },
              ),
              const SizedBox(height: 16),
              const _SheetLabel('Nội dung ghi chú (không bắt buộc)'),
              const SizedBox(height: 8),
              _SheetTextField(
                controller: _addressController,
                hintText: 'Ví dụ: Ăn tối, chụp ảnh lưu niệm...',
                validator: (value) {
                  return null;
                },
              ),
              if (!_isNote) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SheetLabel('Số lượng'),
                          const SizedBox(height: 10),
                          _SheetTextField(
                            controller: _quantityController,
                            hintText: '1',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final quantity = int.tryParse((value ?? '').trim());
                              if (quantity == null || quantity <= 0) {
                                return 'Nhập số hợp lệ';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SheetLabel('Giá đặt'),
                          const SizedBox(height: 10),
                          _SheetTextField(
                            controller: _priceController,
                            hintText: 'Nhập giá',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                              return 'Nhập giá';
                              }
                              final parsed =
                                  double.tryParse(value!.trim().replaceAll(',', ''));
                              if (parsed == null || parsed < 0) {
                              return 'Giá không hợp lệ';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TripUiColors.timelineGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isBus
                        ? 'Thêm chuyến xe'
                        : _isNote
                            ? 'Thêm ghi chú'
                            : 'Thêm vào lịch trình',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required String value,
  }) {
    final isSelected = _selectedServiceType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : TripUiColors.textPrimary,
      ),
      backgroundColor: const Color(0xFFF1F4F6),
      selectedColor: TripUiColors.timelineGreen,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      onSelected: (_) => _onServiceTypeChanged(value),
    );
  }
}

class _BusSelectButton extends StatelessWidget {
  const _BusSelectButton({
    required this.icon,
    required this.title,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF1F4F6) : const Color(0xFFE8ECEF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: enabled
                  ? TripUiColors.timelineGreen
                  : TripUiColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TripUiColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: TripUiColors.textPrimary,
                    ),
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

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: TripUiColors.textPrimary,
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.controller,
    required this.hintText,
    required this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF1F4F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SheetNotice extends StatelessWidget {
  const _SheetNotice({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: TripUiColors.textSecondary,
        ),
      ),
    );
  }
}

class _SelectFieldButton extends StatelessWidget {
  const _SelectFieldButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: TripUiColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TripUiColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
