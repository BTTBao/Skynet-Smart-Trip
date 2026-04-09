import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/activity_history.dart';
import '../../providers/app_settings_provider.dart';
import '../../services/activity_history_service.dart';
import '../../services/api_service_base.dart';
import '../../utils/app_text.dart';
import '../../widgets/widgets.dart';
import '../trip/trip_itinerary_detail_view.dart';
import 'profile_session_helper.dart';

enum _HistorySection { bookings, hotels, buses, payments }

class ActivityHistoryView extends StatefulWidget {
  const ActivityHistoryView({super.key});

  @override
  State<ActivityHistoryView> createState() => _ActivityHistoryViewState();
}

class _ActivityHistoryViewState extends State<ActivityHistoryView> {
  static const primaryColor = Color(0xFF80ED99);

  final ActivityHistoryService _service = ActivityHistoryService();
  ActivityHistory? _history;
  bool _isLoading = true;
  String? _error;
  bool _handledSessionExpired = false;
  _HistorySection _selectedSection = _HistorySection.bookings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHistory();
    });
  }

  Future<void> _fetchHistory() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final history = await _service.getActivityHistory();
      if (!mounted) {
        return;
      }

      setState(() {
        _history = history;
      });
    } catch (error) {
      final message = error is ApiException
          ? error.message
          : error.toString().replaceFirst('Exception: ', '');

      if (!mounted) {
        return;
      }

      setState(() {
        _error = message;
      });

      if (error is ApiException && error.isUnauthorized) {
        await _handleSessionExpired(message);
      }
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          context.tr(vi: 'Lich su hoat dong', en: 'Activity history'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _history == null) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (_error != null && _history == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _fetchHistory,
                child: Text(context.tr(vi: 'Thu lai', en: 'Retry')),
              ),
            ],
          ),
        ),
      );
    }

    final history = _history;
    if (history == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSectionChip(
                  _HistorySection.bookings,
                  'Booking',
                  Icons.receipt_long_outlined,
                ),
                const SizedBox(width: 8),
                _buildSectionChip(
                  _HistorySection.hotels,
                  'Khach san',
                  Icons.hotel_outlined,
                ),
                const SizedBox(width: 8),
                _buildSectionChip(
                  _HistorySection.buses,
                  'Xe',
                  Icons.directions_bus_outlined,
                ),
                const SizedBox(width: 8),
                _buildSectionChip(
                  _HistorySection.payments,
                  'Thanh toan',
                  Icons.payments_outlined,
                ),
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

  Widget _buildSectionChip(
    _HistorySection section,
    String label,
    IconData icon,
  ) {
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      labelStyle: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w700,
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
          emptyTitle: context.tr(vi: 'Chua co booking', en: 'No bookings yet'),
          emptySubtitle: context.tr(
            vi: 'Cac booking cua ban se hien thi tai day.',
            en: 'Your bookings will appear here.',
          ),
          itemBuilder: _buildBookingCard,
        );
      case _HistorySection.hotels:
        return _buildListOrEmpty<HotelHistoryItem>(
          items: history.hotels,
          emptyTitle: context.tr(
            vi: 'Chua co lich su khach san',
            en: 'No hotel history yet',
          ),
          emptySubtitle: context.tr(
            vi: 'Dat phong cua ban se hien thi tai day.',
            en: 'Your hotel bookings will appear here.',
          ),
          itemBuilder: _buildHotelCard,
        );
      case _HistorySection.buses:
        return _buildListOrEmpty<BusHistoryItem>(
          items: history.buses,
          emptyTitle: context.tr(
            vi: 'Chua co lich su ve xe',
            en: 'No bus history yet',
          ),
          emptySubtitle: context.tr(
            vi: 'Thong tin ve xe va hanh trinh se hien thi tai day.',
            en: 'Your bus tickets and routes will appear here.',
          ),
          itemBuilder: _buildBusCard,
        );
      case _HistorySection.payments:
        return _buildListOrEmpty<PaymentHistoryItem>(
          items: history.payments,
          emptyTitle: context.tr(
            vi: 'Chua co lich su thanh toan',
            en: 'No payment history yet',
          ),
          emptySubtitle: context.tr(
            vi: 'Giao dich cua ban se hien thi tai day.',
            en: 'Your transactions will appear here.',
          ),
          itemBuilder: _buildPaymentCard,
        );
    }
  }

  Widget _buildListOrEmpty<T>({
    required List<T> items,
    required String emptyTitle,
    required String emptySubtitle,
    required Widget Function(T item) itemBuilder,
  }) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          EmptyStatePlaceholder(
            icon: Icons.history,
            title: emptyTitle,
            subtitle: emptySubtitle,
            buttonText: context.tr(vi: 'Lam moi', en: 'Refresh'),
            onButtonPressed: _fetchHistory,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) => itemBuilder(items[index]),
    );
  }

  Widget _buildBookingCard(BookingHistoryItem item) {
    return _HistoryCard(
      title: item.title,
      subtitle: item.destinationName,
      amount: _currency(item.totalAmount),
      status: item.status,
      dateText: _joinDateRange(item.startDate, item.endDate),
      onTap: item.tripId > 0 ? () => _openTrip(item.tripId, item.title) : null,
      extraLines: [
        if ((item.invoiceNumber ?? '').isNotEmpty)
          '${context.tr(vi: 'Hoa don', en: 'Invoice')}: ${item.invoiceNumber}',
        if ((item.createdAt ?? '').isNotEmpty)
          '${context.tr(vi: 'Tao luc', en: 'Created at')}: ${_formatDateTime(item.createdAt)}',
      ],
    );
  }

  Widget _buildHotelCard(HotelHistoryItem item) {
    return _HistoryCard(
      title: item.hotelName,
      subtitle: '${item.destinationName} - ${item.address}',
      amount: _currency(item.bookedPrice),
      status: item.status,
      dateText: _joinDateRange(item.checkInDate, item.checkOutDate),
      onTap: item.tripId > 0 ? () => _openTrip(item.tripId, item.tripTitle) : null,
      extraLines: [
        '${context.tr(vi: 'Chuyen di', en: 'Trip')}: ${item.tripTitle}',
        '${context.tr(vi: 'So luong', en: 'Quantity')}: ${item.quantity}',
      ],
    );
  }

  Widget _buildBusCard(BusHistoryItem item) {
    return _HistoryCard(
      title: item.companyName,
      subtitle: '${item.fromDestination} -> ${item.toDestination}',
      amount: _currency(item.bookedPrice),
      status: item.status,
      dateText: _joinDateRange(item.departureTime, item.arrivalTime),
      onTap: item.tripId > 0 ? () => _openTrip(item.tripId, item.tripTitle) : null,
      extraLines: [
        '${context.tr(vi: 'Chuyen di', en: 'Trip')}: ${item.tripTitle}',
        '${context.tr(vi: 'So luong', en: 'Quantity')}: ${item.quantity}',
      ],
    );
  }

  Widget _buildPaymentCard(PaymentHistoryItem item) {
    return _HistoryCard(
      title: item.tripTitle,
      subtitle:
          '${context.tr(vi: 'Phuong thuc', en: 'Method')}: ${item.paymentMethod}',
      amount: _currency(item.amount),
      status: item.status,
      dateText: _formatDateTime(item.paidAt),
      onTap: item.tripId > 0 ? () => _openTrip(item.tripId, item.tripTitle) : null,
      extraLines: [
        if ((item.invoiceNumber ?? '').isNotEmpty)
          '${context.tr(vi: 'Hoa don', en: 'Invoice')}: ${item.invoiceNumber}',
        if ((item.transactionId ?? '').isNotEmpty)
          '${context.tr(vi: 'Ma giao dich', en: 'Transaction ID')}: ${item.transactionId}',
      ],
    );
  }

  void _openTrip(int tripId, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripItineraryDetailView(
          tripId: tripId,
          tripTitle: title,
        ),
      ),
    );
  }

  String _joinDateRange(String? start, String? end) {
    final startText = _formatDate(start);
    final endText = _formatDate(end);

    if (startText == '-' && endText == '-') {
      return '-';
    }
    if (startText == '-' || endText == '-') {
      return startText == '-' ? endText : startText;
    }
    return '$startText - $endText';
  }

  String _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    return DateFormat('dd/MM/yyyy').format(parsed.toLocal());
  }

  String _formatDateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    return DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
  }

  String _currency(double amount) {
    return context.read<AppSettingsProvider>().formatCurrency(amount);
  }

  Future<void> _handleSessionExpired(String? message) async {
    if (_handledSessionExpired || !mounted) {
      return;
    }

    _handledSessionExpired = true;
    await showSessionExpiredDialog(context, message: message);
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.dateText,
    required this.extraLines,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String status;
  final String dateText;
  final List<String> extraLines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusChip(label: status),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(icon: Icons.schedule_outlined, label: dateText),
                  _MetaChip(icon: Icons.payments_outlined, label: amount),
                ],
              ),
              if (extraLines.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...extraLines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Xem chi tiet chuyen di',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.green.shade700,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF80ED99).withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

