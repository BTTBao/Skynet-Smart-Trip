import 'package:flutter/material.dart';

import '../../models/activity_history.dart';
import '../../services/activity_history_service.dart';
import '../../services/api_service_base.dart';
import 'invoice_detail_view.dart';

class InvoiceLookupView extends StatefulWidget {
  const InvoiceLookupView({super.key, required this.tripId});

  final int tripId;

  @override
  State<InvoiceLookupView> createState() => _InvoiceLookupViewState();
}

class _InvoiceLookupViewState extends State<InvoiceLookupView> {
  final ActivityHistoryService _service = ActivityHistoryService();
  ActivityHistory? _history;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await _service.getActivityHistory();
      if (!mounted) {
        return;
      }
      setState(() {
        _history = history;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error is ApiException
            ? error.message
            : error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final history = _history;
    final error = _error;
    if (history == null || error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết hóa đơn')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error ?? 'Không tìm thấy hóa đơn.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _load,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final payment = _findPayment(history);
    final hotel = _findHotel(history);
    final bus = _findBus(history);
    final booking = _findBooking(history);

    if (hotel != null) {
      return InvoiceDetailView(
        title: _hotelServiceTitle(hotel),
        serviceType: 'Khách sạn',
        providerName: hotel.hotelName,
        routeOrAddress: '${hotel.destinationName} - ${hotel.address}',
        dateText: _joinDateRange(hotel.checkInDate, hotel.checkOutDate),
        quantityText: '${hotel.quantity} phòng',
        amount: payment?.amount ?? hotel.bookedPrice,
        status: payment?.status ?? hotel.status,
        invoiceNumber: hotel.invoiceNumber ?? payment?.invoiceNumber,
        transactionId: payment?.transactionId,
        paymentMethod: payment?.paymentMethod,
        usedCoins: payment?.usedCoins,
      );
    }

    if (bus != null) {
      return InvoiceDetailView(
        title: _busServiceTitle(bus),
        serviceType: 'Vé xe',
        providerName: bus.companyName,
        routeOrAddress: '${bus.fromDestination} -> ${bus.toDestination}',
        dateText: _joinDateRange(bus.departureTime, bus.arrivalTime),
        quantityText: bus.selectedSeats?.isNotEmpty == true
            ? 'Ghế ${bus.selectedSeats}'
            : '${bus.quantity} vé',
        amount: payment?.amount ?? bus.bookedPrice,
        status: payment?.status ?? bus.status,
        invoiceNumber: bus.invoiceNumber ?? payment?.invoiceNumber,
        transactionId: payment?.transactionId,
        paymentMethod: payment?.paymentMethod,
        usedCoins: payment?.usedCoins,
      );
    }

    if (booking != null || payment != null) {
      return InvoiceDetailView(
        title: booking?.title ?? payment?.tripTitle ?? 'Hóa đơn',
        serviceType: 'Booking',
        providerName: booking?.destinationName ?? payment?.paymentMethod ?? '',
        routeOrAddress: booking?.destinationName ?? 'Mã booking #${widget.tripId}',
        dateText: booking != null
            ? _joinDateRange(booking.startDate, booking.endDate)
            : _formatDateTime(payment?.paidAt),
        quantityText: '1 booking',
        amount: payment?.amount ?? booking?.totalAmount ?? 0,
        status: payment?.status ?? booking?.status ?? '',
        invoiceNumber: booking?.invoiceNumber ?? payment?.invoiceNumber,
        transactionId: payment?.transactionId,
        paymentMethod: payment?.paymentMethod,
        usedCoins: payment?.usedCoins,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết hóa đơn')),
      body: const Center(child: Text('Không tìm thấy hóa đơn.')),
    );
  }

  BookingHistoryItem? _findBooking(ActivityHistory history) {
    for (final item in history.bookings) {
      if (item.tripId == widget.tripId) {
        return item;
      }
    }
    return null;
  }

  HotelHistoryItem? _findHotel(ActivityHistory history) {
    for (final item in history.hotels) {
      if (item.tripId == widget.tripId) {
        return item;
      }
    }
    return null;
  }

  BusHistoryItem? _findBus(ActivityHistory history) {
    for (final item in history.buses) {
      if (item.tripId == widget.tripId) {
        return item;
      }
    }
    return null;
  }

  PaymentHistoryItem? _findPayment(ActivityHistory history) {
    for (final item in history.payments) {
      if (item.tripId == widget.tripId) {
        return item;
      }
    }
    return null;
  }

  String _joinDateRange(String? start, String? end) {
    final startText = _formatDate(start);
    final endText = _formatDate(end);
    if (startText.isEmpty) {
      return endText;
    }
    if (endText.isEmpty || endText == startText) {
      return startText;
    }
    return '$startText - $endText';
  }

  String _formatDate(String? value) {
    final parsed = DateTime.tryParse(value ?? '');
    if (parsed == null) {
      return value ?? '';
    }
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  String _formatDateTime(String? value) {
    final parsed = DateTime.tryParse(value ?? '');
    if (parsed == null) {
      return value ?? '';
    }
    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _hotelServiceTitle(HotelHistoryItem item) {
    final roomType = item.roomType.trim();
    if (roomType.isEmpty) {
      return item.hotelName;
    }

    return '${item.hotelName} - $roomType';
  }

  String _busServiceTitle(BusHistoryItem item) {
    final from = item.fromDestination.trim();
    final to = item.toDestination.trim();
    if (from.isEmpty || to.isEmpty) {
      return item.companyName;
    }

    return '${item.companyName} - $from -> $to';
  }
}
