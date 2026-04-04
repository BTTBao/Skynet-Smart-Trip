import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/activity_history.dart';
import '../../services/activity_history_service.dart';
import '../../widgets/widgets.dart';

enum _HistorySection { bookings, hotels, buses, payments }

class ActivityHistoryView extends StatefulWidget {
  final String userId;

  const ActivityHistoryView({
    super.key,
    required this.userId,
  });

  @override
  State<ActivityHistoryView> createState() => _ActivityHistoryViewState();
}

class _ActivityHistoryViewState extends State<ActivityHistoryView> {
  static const primaryColor = Color(0xFF80ed99);

  final ActivityHistoryService _service = ActivityHistoryService();
  ActivityHistory? _history;
  bool _isLoading = true;
  String? _error;
  _HistorySection _selectedSection = _HistorySection.bookings;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = widget.userId.isNotEmpty ? widget.userId : '1';
      final history = await _service.getActivityHistory(userId);

      if (!mounted) return;
      setState(() {
        _history = history;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lich su hoat dong',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(
                'Da xay ra loi: $_error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchHistory,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text(
                  'Thu lai',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final history = _history;
    if (history == null) {
      return const Center(child: Text('Khong co du lieu lich su'));
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSectionChip(_HistorySection.bookings, 'Booking', Icons.receipt_long_outlined),
                const SizedBox(width: 8),
                _buildSectionChip(_HistorySection.hotels, 'Khach san', Icons.hotel_outlined),
                const SizedBox(width: 8),
                _buildSectionChip(_HistorySection.buses, 'Xe', Icons.directions_bus_outlined),
                const SizedBox(width: 8),
                _buildSectionChip(_HistorySection.payments, 'Thanh toan', Icons.payments_outlined),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: primaryColor,
            onRefresh: _fetchHistory,
            child: _buildSectionContent(history),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionChip(_HistorySection section, String label, IconData icon) {
    final isSelected = _selectedSection == section;

    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedSection = section;
        });
      },
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.black : Colors.grey.shade600,
      ),
      label: Text(label),
      selectedColor: primaryColor.withOpacity(0.25),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: Colors.black87,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isSelected ? primaryColor : Colors.grey.shade300,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    );
  }

  Widget _buildSectionContent(ActivityHistory history) {
    switch (_selectedSection) {
      case _HistorySection.bookings:
        return _buildListOrEmpty<BookingHistoryItem>(
          items: history.bookings,
          emptyIcon: Icons.receipt_long_outlined,
          emptyTitle: 'Chua co booking',
          emptySubtitle: 'Cac booking cua ban se hien thi tai day.',
          emptyButtonText: 'Kham pha ngay',
          itemBuilder: _buildBookingCard,
        );
      case _HistorySection.hotels:
        return _buildListOrEmpty<HotelHistoryItem>(
          items: history.hotels,
          emptyIcon: Icons.hotel_outlined,
          emptyTitle: 'Chua co lich su khach san',
          emptySubtitle: 'Booking khach san cua ban se hien thi tai day.',
          emptyButtonText: 'Dat phong ngay',
          itemBuilder: _buildHotelCard,
        );
      case _HistorySection.buses:
        return _buildListOrEmpty<BusHistoryItem>(
          items: history.buses,
          emptyIcon: Icons.directions_bus_outlined,
          emptyTitle: 'Chua co lich su ve xe',
          emptySubtitle: 'Cac ve xe va hanh trinh se hien thi tai day.',
          emptyButtonText: 'Dat xe ngay',
          itemBuilder: _buildBusCard,
        );
      case _HistorySection.payments:
        return _buildListOrEmpty<PaymentHistoryItem>(
          items: history.payments,
          emptyIcon: Icons.payments_outlined,
          emptyTitle: 'Chua co lich su thanh toan',
          emptySubtitle: 'Giao dich va hoa don cua ban se hien thi tai day.',
          emptyButtonText: 'Bat dau ngay',
          itemBuilder: _buildPaymentCard,
        );
    }
  }

  Widget _buildListOrEmpty<T>({
    required List<T> items,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required String emptyButtonText,
    required Widget Function(T item) itemBuilder,
  }) {
    if (items.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 500,
          child: Center(
            child: EmptyStatePlaceholder(
              icon: emptyIcon,
              title: emptyTitle,
              subtitle: emptySubtitle,
              buttonText: emptyButtonText,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => itemBuilder(items[index]),
    );
  }

  Widget _buildBookingCard(BookingHistoryItem item) {
    return _buildCard(
      icon: Icons.receipt_long_outlined,
      title: item.title,
      badgeText: item.status,
      lines: [
        'Diem den: ${item.destinationName}',
        'Thoi gian: ${_formatDateRange(item.startDate, item.endDate)}',
        'Tong tien: ${_formatCurrency(item.totalAmount)}',
        if (item.invoiceNumber != null && item.invoiceNumber!.isNotEmpty)
          'Ve dien tu: ${item.invoiceNumber}',
      ],
    );
  }

  Widget _buildHotelCard(HotelHistoryItem item) {
    return _buildCard(
      icon: Icons.hotel_outlined,
      title: item.hotelName,
      badgeText: item.status,
      lines: [
        'Chuyen di: ${item.tripTitle}',
        'Dia chi: ${item.address}',
        'Ngay o: ${_formatDateRange(item.checkInDate, item.checkOutDate)}',
        'So luong: ${item.quantity}',
        'Gia dat: ${_formatCurrency(item.bookedPrice)}',
      ],
    );
  }

  Widget _buildBusCard(BusHistoryItem item) {
    return _buildCard(
      icon: Icons.directions_bus_outlined,
      title: item.companyName,
      badgeText: item.status,
      lines: [
        'Chuyen di: ${item.tripTitle}',
        'Tuyen: ${item.fromDestination} -> ${item.toDestination}',
        'Khoi hanh: ${_formatDateTime(item.departureTime)}',
        'Den noi: ${_formatDateTime(item.arrivalTime)}',
        'Gia dat: ${_formatCurrency(item.bookedPrice)}',
      ],
    );
  }

  Widget _buildPaymentCard(PaymentHistoryItem item) {
    return _buildCard(
      icon: Icons.payments_outlined,
      title: item.tripTitle,
      badgeText: item.status,
      lines: [
        'So tien: ${_formatCurrency(item.amount)}',
        'Phuong thuc: ${item.paymentMethod}',
        'Thanh toan luc: ${_formatDateTime(item.paidAt)}',
        if (item.transactionId != null && item.transactionId!.isNotEmpty)
          'Ma giao dich: ${item.transactionId}',
        if (item.invoiceNumber != null && item.invoiceNumber!.isNotEmpty)
          'Hoa don: ${item.invoiceNumber}',
      ],
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String badgeText,
    required List<String> lines,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.green.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusColor(badgeText).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: _statusColor(badgeText),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                line,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'd',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDateRange(String? start, String? end) {
    if (start == null && end == null) return 'Chua cap nhat';
    if (start == null) return _formatDate(end);
    if (end == null) return _formatDate(start);
    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return 'Chua cap nhat';
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatDateTime(String? value) {
    if (value == null || value.isEmpty) return 'Chua cap nhat';
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }
}


