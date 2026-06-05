import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bus_schedule_model.dart';
import '../../providers/bus_provider.dart';
import '../../providers/destination_provider.dart';
import 'transport_checkout_screen.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF0D6B42);
const _kBg = Color(0xFFF4F7F5);

// ─── Screen ───────────────────────────────────────────────────────────────────

class TransportSearchScreen extends StatefulWidget {
  final int? toDestId;
  final String? toDestName;
  final DateTime? initialDate;
  final int? initialScheduleId;

  const TransportSearchScreen({
    super.key,
    this.toDestId,
    this.toDestName,
    this.initialDate,
    this.initialScheduleId,
  });

  @override
  State<TransportSearchScreen> createState() => _TransportSearchScreenState();
}

class _TransportSearchScreenState extends State<TransportSearchScreen> {
  int? _fromDestId;
  String _fromDestName = 'Đà Nẵng';
  int? _toDestId;
  String _toDestName = 'Hội An';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));
  int _selectedFilterIndex = 0;
  bool _didOpenInitialSchedule = false;

  static const _filters = ['Phổ biến', 'Giá thấp', 'Giờ sớm', 'Ưu tiên'];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final requestedDate = widget.initialDate != null
        ? DateTime(
            widget.initialDate!.year,
            widget.initialDate!.month,
            widget.initialDate!.day,
          )
        : null;
    _selectedDate = requestedDate == null
        ? normalizedToday.add(const Duration(days: 2))
        : (requestedDate.isBefore(normalizedToday)
              ? normalizedToday
              : requestedDate);
    _toDestId = widget.toDestId;
    if (widget.toDestName != null) {
      _toDestName = widget.toDestName!;
    } else {
      _toDestName = 'Hội An';
    }
    if (widget.initialDate != null) {
      _selectedDate = DateTime(
        widget.initialDate!.year,
        widget.initialDate!.month,
        widget.initialDate!.day,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final destProvider = context.read<DestinationProvider>();
      if (destProvider.destinations.isEmpty) {
        await destProvider.fetchDestinations(forceRefresh: true);
      }
      if (destProvider.destinations.isNotEmpty) {
        final fromMatch = destProvider.destinations.firstWhere(
          (d) =>
              d.name.toLowerCase().contains('đà nẵng') ||
              d.name.toLowerCase().contains('da nang'),
          orElse: () => destProvider.destinations.first,
        );
        final toMatch = destProvider.destinations.firstWhere(
          (d) =>
              d.name.toLowerCase() == _toDestName.toLowerCase() ||
              d.name.toLowerCase().contains(_toDestName.toLowerCase()),
          orElse: () => destProvider.destinations.length > 1
              ? destProvider.destinations[1]
              : destProvider.destinations.first,
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
    if (_fromDestId != _toDestId) {
      _loadSchedules();
    }
  }

  void _changeToDest(int id, String name) {
    setState(() {
      _toDestId = id;
      _toDestName = name;
    });
    if (_fromDestId != _toDestId) {
      _loadSchedules();
    }
  }

  void _swapDestinations() {
    setState(() {
      final tempId = _fromDestId;
      final tempName = _fromDestName;
      _fromDestId = _toDestId;
      _fromDestName = _toDestName;
      _toDestId = tempId;
      _toDestName = tempName;
    });
    if (_fromDestId != _toDestId) {
      _loadSchedules();
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kPrimary,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadSchedules();
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day} Tháng ${dt.month}, ${dt.year}';

  String _formatPrice(double price) {
    final fmt = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$fmtđ';
  }

  @override
  Widget build(BuildContext context) {
    final busProvider = context.watch<BusProvider>();
    final destProvider = context.watch<DestinationProvider>();

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _GradientHeader(
            fromName: _fromDestName,
            toName: _toDestName,
            onBack: () => Navigator.pop(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _SearchFormCard(
              fromDestName: _fromDestName,
              toDestName: _toDestName,
              selectedDate: _selectedDate,
              formattedDate: _formatDate(_selectedDate),
              onFromTap: () =>
                  _showDestSelector(context, destProvider, isFrom: true),
              onToTap: () =>
                  _showDestSelector(context, destProvider, isFrom: false),
              onSwap: _swapDestinations,
              onDateTap: () => _selectDate(context),
            ),
          ),
          const SizedBox(height: 16),
          // Filter chips
          SizedBox(
            height: 36,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (_, i) {
                final active = i == _selectedFilterIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilterIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? _kPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? _kPrimary : Colors.grey[300]!,
                        ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: _kPrimary.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      child: Text(
                        _filters[i],
                        style: TextStyle(
                          color: active ? Colors.white : Colors.grey[700],
                          fontWeight:
                              active ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Schedule list
          Expanded(
            child: _fromDestId == _toDestId
                ? const _EmptyOrError(
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.orange,
                    title: 'Tuyến đường không hợp lệ',
                    subtitle: 'Điểm đi và điểm đến không thể trùng nhau.',
                  )
                : busProvider.isLoadingSchedules
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_kPrimary),
                        ),
                      )
                    : busProvider.error != null
                        ? _EmptyOrError(
                            icon: Icons.error_outline_rounded,
                            iconColor: Colors.red[300]!,
                            title: 'Có lỗi xảy ra',
                            subtitle: busProvider.error!,
                          )
                        : busProvider.schedules.isEmpty
                            ? const _EmptyOrError(
                                icon: Icons.directions_bus_outlined,
                                iconColor: Color(0xFFCCCCCC),
                                title: 'Không tìm thấy chuyến xe',
                                subtitle:
                                    'Thử đổi ngày hoặc tuyến đường khác nhé',
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 24),
                                itemCount: busProvider.schedules.length,
                                itemBuilder: (ctx, i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _TransportCard(
                                    schedule: busProvider.schedules[i],
                                    formatPrice: _formatPrice,
                                    onSelectSeat: () =>
                                        _showSeatSelection(
                                            ctx, busProvider.schedules[i]),
                                  ),
                                ),
                              ),
          ),
        ],
      ),
    );
  }

  // ─── Destination Selector ─────────────────────────────────────────────────

  void _showDestSelector(
    BuildContext context,
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
      builder: (ctx) => _DestinationSelectorSheet(
        destinations: destProvider.destinations,
        isFrom: isFrom,
        onSelect: (id, name) {
          Navigator.pop(ctx);
          if (isFrom) {
            _changeFromDest(id, name);
          } else {
            _changeToDest(id, name);
          }
        },
      ),
    );
  }

  // ─── Seat Selection ───────────────────────────────────────────────────────

  void _showSeatSelection(
    BuildContext context,
    BusScheduleModel schedule,
  ) async {
    final busProvider = context.read<BusProvider>();
    busProvider.selectSchedule(schedule);
    await busProvider.fetchSeats(schedule.id);
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (sheetCtx) => Consumer<BusProvider>(
        builder: (ctx, provider, _) => _SeatSelectionSheet(
          schedule: schedule,
          provider: provider,
          formatPrice: _formatPrice,
          onConfirm: () {
            Navigator.pop(sheetCtx);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TransportCheckoutScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Gradient Header ──────────────────────────────────────────────────────────

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({
    required this.fromName,
    required this.toName,
    required this.onBack,
  });

  final String fromName;
  final String toName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A4F30), Color(0xFF0D6B42), Color(0xFF169655)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vé Xe Limousine',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.circle,
                        color: Color(0xFF80ED99), size: 8),
                    const SizedBox(width: 6),
                    Text(
                      '$fromName  →  $toName',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

// ─── Search Form Card ─────────────────────────────────────────────────────────

class _SearchFormCard extends StatelessWidget {
  const _SearchFormCard({
    required this.fromDestName,
    required this.toDestName,
    required this.selectedDate,
    required this.formattedDate,
    required this.onFromTap,
    required this.onToTap,
    required this.onSwap,
    required this.onDateTap,
  });

  final String fromDestName;
  final String toDestName;
  final DateTime selectedDate;
  final String formattedDate;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onSwap;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
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
            onTap: onFromTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(
                children: [
                  _FieldIcon(
                    icon: Icons.radio_button_checked,
                    color: _kPrimary,
                    bg: _kPrimary.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Điểm đi',
                            style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(fromDestName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87)),
                      ],
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey[400]),
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
                  Divider(color: Colors.grey[150] ?? Colors.grey[200]!, height: 1),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: onSwap,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _kPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _kPrimary.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.swap_vert_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // To
          GestureDetector(
            onTap: onToTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                children: [
                  _FieldIcon(
                    icon: Icons.location_on_rounded,
                    color: Colors.orange[600]!,
                    bg: Colors.orange.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Điểm đến',
                            style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(toDestName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87)),
                      ],
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey[400]),
                ],
              ),
            ),
          ),

          Divider(color: Colors.grey[100], height: 1, thickness: 1),

          // Date
          GestureDetector(
            onTap: onDateTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                children: [
                  _FieldIcon(
                    icon: Icons.calendar_today_rounded,
                    color: Colors.blue[600]!,
                    bg: Colors.blue.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ngày đi',
                            style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(formattedDate,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Đổi ngày',
                        style: TextStyle(
                            color: _kPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldIcon extends StatelessWidget {
  const _FieldIcon({
    required this.icon,
    required this.color,
    required this.bg,
  });

  final IconData icon;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

// ─── Transport Card ───────────────────────────────────────────────────────────

class _TransportCard extends StatelessWidget {
  const _TransportCard({
    required this.schedule,
    required this.formatPrice,
    required this.onSelectSeat,
  });

  final BusScheduleModel schedule;
  final String Function(double) formatPrice;
  final VoidCallback onSelectSeat;

  @override
  Widget build(BuildContext context) {
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
                                        _defaultLogo(),
                                  )
                                : _defaultLogo(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(schedule.companyName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5EE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${schedule.totalSeats} chỗ giường nằm',
                                    style: const TextStyle(
                                      color: _kPrimary,
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
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0D6B42),
                                  Color(0xFF1A9058)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.white, size: 12),
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
                              Text(dep,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      color: Colors.black87)),
                              Text(schedule.fromDestName,
                                  style:
                                      TextStyle(color: Colors.grey[500], fontSize: 12)),
                            ],
                          ),
                          // Line
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Column(
                                children: [
                                  Text(schedule.duration,
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: _kPrimary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                                height: 1.5,
                                                color: Colors.grey[200]),
                                            const Icon(
                                                Icons.directions_bus_rounded,
                                                color: _kPrimary,
                                                size: 18),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey[400]!,
                                              width: 1.5),
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
                              Text(arr,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      color: Colors.black87)),
                              Text(schedule.toDestName,
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 12)),
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
                                  formatPrice(schedule.price),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: _kPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.event_seat_rounded,
                                        color: Colors.red[400], size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Còn ${schedule.spotsLeft} ghế',
                                      style: TextStyle(
                                          color: Colors.red[400],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: onSelectSeat,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0D6B42),
                                    Color(0xFF1A9058)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _kPrimary.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text('Chọn ghế',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
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

  Widget _defaultLogo() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _kPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.directions_bus_rounded,
            color: _kPrimary, size: 24),
      );
}

// ─── Seat Selection Sheet ─────────────────────────────────────────────────────

class _SeatSelectionSheet extends StatelessWidget {
  const _SeatSelectionSheet({
    required this.schedule,
    required this.provider,
    required this.formatPrice,
    required this.onConfirm,
  });

  final BusScheduleModel schedule;
  final BusProvider provider;
  final String Function(double) formatPrice;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(schedule.companyName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17)),
                    Text('${schedule.fromDestName} → ${schedule.toDestName}',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${schedule.departureTime.hour.toString().padLeft(2, '0')}:${schedule.departureTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SeatLegend(bg: Colors.grey[100]!, fg: Colors.grey[500]!, label: 'Trống'),
              const SizedBox(width: 18),
              const _SeatLegend(bg: _kPrimary, fg: Colors.white, label: 'Chọn'),
              const SizedBox(width: 18),
              _SeatLegend(bg: Colors.red[50]!, fg: Colors.red[300]!, label: 'Đã đặt'),
            ],
          ),
          const SizedBox(height: 14),
          // Driver label
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.airline_seat_recline_normal_rounded,
                      color: Colors.grey[500], size: 14),
                  const SizedBox(width: 6),
                  Text('Đầu xe – Tài xế',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Grid
          Expanded(
            child: provider.isLoadingSeats
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
                    ),
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.88,
                    ),
                    itemCount: ((provider.seats.length / 4).ceil() * 5),
                    itemBuilder: (_, index) {
                      final col = index % 5;
                      final row = index ~/ 5;

                      // Aisle column
                      if (col == 2) {
                        return Center(
                          child: Container(
                            width: 2,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        );
                      }

                      final realCol = col > 2 ? col - 1 : col;
                      final seatIndex = row * 4 + realCol;

                      if (seatIndex >= provider.seats.length) {
                        return const SizedBox.shrink();
                      }

                      final seat = provider.seats[seatIndex];
                      final isSelected = provider.selectedSeatNumbers
                          .contains(seat.seatNumber);

                      Color bg;
                      Color fg;
                      if (seat.isBooked) {
                        bg = Colors.red[50]!;
                        fg = Colors.red[300]!;
                      } else if (isSelected) {
                        bg = _kPrimary;
                        fg = Colors.white;
                      } else {
                        bg = Colors.grey[100]!;
                        fg = Colors.grey[500]!;
                      }

                      return GestureDetector(
                        onTap: seat.isBooked
                            ? null
                            : () =>
                                provider.toggleSeatSelection(seat.seatNumber),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? _kPrimary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: _kPrimary.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2))
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_seat_rounded, color: fg, size: 18),
                              const SizedBox(height: 2),
                              Text(seat.seatNumber,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: fg)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom bar
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
            child: provider.selectedSeatNumbers.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('Chọn ít nhất 1 ghế để tiếp tục',
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.w500)),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ghế: ${provider.selectedSeatNumbers.join(', ')}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                            Text(
                              formatPrice(provider.selectedSeatNumbers.length *
                                  schedule.price),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: _kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onConfirm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D6B42), Color(0xFF1A9058)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _kPrimary.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text('Tiếp tục →',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
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

class _SeatLegend extends StatelessWidget {
  const _SeatLegend(
      {required this.bg, required this.fg, required this.label});

  final Color bg;
  final Color fg;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
              bottomLeft: Radius.circular(3),
              bottomRight: Radius.circular(3),
            ),
          ),
          child: Icon(Icons.event_seat_rounded, color: fg, size: 14),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─── Empty / Error State ─────────────────────────────────────────────────────

class _EmptyOrError extends StatelessWidget {
  const _EmptyOrError({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 64),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Destination Selector Sheet ──────────────────────────────────────────────

class _DestinationSelectorSheet extends StatefulWidget {
  final List<dynamic> destinations;
  final bool isFrom;
  final Function(int id, String name) onSelect;

  const _DestinationSelectorSheet({
    super.key,
    required this.destinations,
    required this.isFrom,
    required this.onSelect,
  });

  @override
  State<_DestinationSelectorSheet> createState() => _DestinationSelectorSheetState();
}

class _DestinationSelectorSheetState extends State<_DestinationSelectorSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.destinations.where((dest) {
      final name = dest.name.toLowerCase();
      final query = _searchQuery.toLowerCase();
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
                  widget.isFrom ? 'Chọn điểm khởi hành' : 'Chọn điểm đến',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm địa điểm...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: _kPrimary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final dest = filtered[idx];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _kPrimary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded,
                              color: _kPrimary, size: 18),
                        ),
                        title: Text(
                          dest.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        onTap: () {
                          widget.onSelect(dest.id, dest.name);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
