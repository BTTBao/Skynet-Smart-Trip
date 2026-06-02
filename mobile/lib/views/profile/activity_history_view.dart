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
import 'package:url_launcher/url_launcher.dart';
import '../../services/payment_service.dart';
import '../../services/bus_service.dart';
import '../../providers/trip_provider.dart';
import '../../services/trip_service.dart';

enum _HistorySection { bookings, hotels, buses, payments }

class ActivityHistoryView extends StatefulWidget {
  const ActivityHistoryView({super.key});

  @override
  State<ActivityHistoryView> createState() => _ActivityHistoryViewState();
}

class _ActivityHistoryViewState extends State<ActivityHistoryView> {
  static const primaryColor = Color(0xFF80ED99);

  final ActivityHistoryService _service = ActivityHistoryService();
  final TripService _tripService = TripService();
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
      actionLabel: item.status.toUpperCase() == 'PENDING' ? 'Thanh toán' : null,
      onActionTap: item.status.toUpperCase() == 'PENDING'
          ? () => _showPaymentModal(item.tripId, item.totalAmount, 'Thanh toán ${item.tripId}', 'HOTEL')
          : null,
      extraLines: [
        if ((item.invoiceNumber ?? '').isNotEmpty)
          '${context.tr(vi: 'Hoa don', en: 'Invoice')}: ${item.invoiceNumber}',
        if ((item.createdAt ?? '').isNotEmpty)
          '${context.tr(vi: 'Tao luc', en: 'Created at')}: ${_formatDateTime(item.createdAt)}',
      ],
    );
  }

  Widget _buildHotelCard(HotelHistoryItem item) {
    final canReview = !item.isReviewed && (item.status.toUpperCase() == 'PAID' || item.status.toUpperCase() == 'SUCCESS' || item.status.toUpperCase() == 'COMPLETED');
    final isReviewed = item.isReviewed;

    return _HistoryCard(
      title: item.hotelName,
      subtitle: '${item.destinationName} - ${item.address}',
      amount: _currency(item.bookedPrice),
      status: item.status,
      dateText: _joinDateRange(item.checkInDate, item.checkOutDate),
      onTap: item.tripId > 0 ? () => _openTrip(item.tripId, item.tripTitle) : null,
      actionLabel: isReviewed 
          ? 'Đã đánh giá'
          : canReview 
              ? 'Viết đánh giá' 
              : (item.status.toUpperCase() == 'PENDING' ? 'Thanh toán' : null),
      onActionTap: isReviewed
          ? null
          : canReview
              ? () => _showReviewDialog(item.tripId, 'Hotel', item.serviceId, item.hotelName)
              : (item.status.toUpperCase() == 'PENDING'
                  ? () => _showPaymentModal(item.tripId, item.bookedPrice, 'Thanh toán ${item.tripId}', 'HOTEL')
                  : null),
      extraLines: [
        '${context.tr(vi: 'Chuyen di', en: 'Trip')}: ${item.tripTitle}',
        '${context.tr(vi: 'So luong', en: 'Quantity')}: ${item.quantity}',
      ],
    );
  }

  Future<void> _repayBusTicket(BusHistoryItem item) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    try {
      await _tripService.reLockSeats(item.tripId);
      
      if (mounted) Navigator.pop(context);

      if (mounted) {
        await _showPaymentModal(
          item.tripId,
          item.bookedPrice,
          'Thanh toán vé xe ${item.companyName}',
          'BUS',
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      if (mounted) {
        final errorMsg = e is ApiException
            ? e.message
            : e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể thanh toán: $errorMsg'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildBusCard(BusHistoryItem item) {
    final canReview = !item.isReviewed && (item.status.toUpperCase() == 'PAID' || item.status.toUpperCase() == 'SUCCESS' || item.status.toUpperCase() == 'COMPLETED');
    final isReviewed = item.isReviewed;
    final isPending = item.status.toUpperCase() == 'PENDING';

    return _HistoryCard(
      title: item.companyName,
      subtitle: '${item.fromDestination} -> ${item.toDestination}',
      amount: _currency(item.bookedPrice),
      status: item.status,
      dateText: _joinDateRange(item.departureTime, item.arrivalTime),
      onTap: item.tripId > 0 ? () => _openTrip(item.tripId, item.tripTitle) : null,
      actionLabel: isReviewed 
          ? 'Đã đánh giá'
          : canReview 
              ? 'Viết đánh giá' 
              : isPending
                  ? 'Thanh toán'
                  : null,
      onActionTap: isReviewed
          ? null
          : canReview
              ? () => _showReviewDialog(item.tripId, 'BusCompany', item.companyId, item.companyName)
              : isPending
                  ? () => _repayBusTicket(item)
                  : null,
      extraLines: [
        '${context.tr(vi: 'Chuyen di', en: 'Trip')}: ${item.tripTitle}',
        '${context.tr(vi: 'So luong', en: 'Quantity')}: ${item.quantity}',
        if (item.selectedSeats != null && item.selectedSeats!.isNotEmpty)
          'Số ghế: ${item.selectedSeats}',
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

  void _showReviewDialog(int tripId, String targetType, int targetId, String name) {
    int selectedRating = 5;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Đánh giá $name',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Hãy chia sẻ trải nghiệm của bạn về dịch vụ này nhé!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starRating = index + 1;
                        return IconButton(
                          icon: Icon(
                            starRating <= selectedRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 36,
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  setDialogState(() {
                                    selectedRating = starRating;
                                  });
                                },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        hintText: 'Nhập ý kiến đánh giá của bạn tại đây...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0D6B42)),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() {
                            isSubmitting = true;
                          });

                          try {
                            await _tripService.submitReview(
                              tripId: tripId,
                              targetType: targetType,
                              targetId: targetId,
                              rating: selectedRating,
                              comment: commentController.text.trim(),
                            );

                            if (mounted) {
                              Navigator.pop(context); // Close dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cảm ơn bạn đã gửi đánh giá!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _fetchHistory(); // Refresh list to update button
                            }
                          } catch (e) {
                            if (mounted) {
                              setDialogState(() {
                                isSubmitting = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6B42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Gửi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
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

  Future<void> _showPaymentModal(int tripId, double amount, String description, String type) async {
    double finalAmount = amount;
    if (finalAmount <= 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      try {
        final tripProvider = context.read<TripProvider>();
        final tripDetail = await tripProvider.fetchTripDetail(tripId);
        if (tripDetail != null && tripDetail.totalAmount != null) {
          finalAmount = tripDetail.totalAmount!;
        }
      } finally {
        if (mounted) Navigator.pop(context);
      }
    }

    if (finalAmount <= 0) {
      _processInternalPayment(tripId, 0, 4); // Tự động duyệt đơn 0đ thông qua index 4 'Promotion'
      return;
    }

    final method = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Chọn phương thức thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.qr_code_2, color: Colors.blue),
                  title: const Text('Thẻ tín dụng/Ghi nợ (PayOS)'),
                  subtitle: Text('Tổng tiền: ${_currency(finalAmount)}'),
                  onTap: () => Navigator.pop(context, 0),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet, color: Colors.pink),
                  title: const Text('Ví MoMo'),
                  subtitle: Text('Tổng tiền: ${_currency(finalAmount)}'),
                  onTap: () => Navigator.pop(context, 1),
                ),
                ListTile(
                  leading: const Icon(Icons.payment, color: Colors.blueAccent),
                  title: const Text('ZaloPay'),
                  subtitle: Text('Tổng tiền: ${_currency(finalAmount)}'),
                  onTap: () => Navigator.pop(context, 2),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance, color: Colors.green),
                  title: const Text('Chuyển khoản ngân hàng'),
                  subtitle: Text('Tổng tiền: ${_currency(finalAmount)}'),
                  onTap: () => Navigator.pop(context, 3),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (method == null) return;

    if (method == 0) {
      _processPayOs(tripId, finalAmount, description, type);
    } else {
      _processInternalPayment(tripId, finalAmount, method);
    }
  }

  int _generateOrderCode(int tripId) {
    final timePart = DateTime.now().millisecondsSinceEpoch % 10000000000;
    return (timePart * 1000) + (tripId % 1000);
  }

  Future<void> _processPayOs(int tripId, double amount, String description, String type) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      
      final orderCode = _generateOrderCode(tripId);
      final payment = await PaymentService().createPayOsPayment(
        tripId: tripId,
        amount: amount,
        description: description,
        orderCode: orderCode,
        metadata: {
          'type': type,
        },
      );

      if (mounted) Navigator.pop(context); // close loading

      final checkoutUrl = payment.checkoutUrl;
      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
        
        if (mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Hoàn tất thanh toán PayOS'),
                content: const Text(
                  'Trang PayOS đã được mở. Sau khi thanh toán xong, quay lại app và bấm kiểm tra.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _fetchHistory();
                    },
                    child: const Text('Xong'),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _processInternalPayment(int tripId, double amount, int methodIndex) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final methods = ['PayOS', 'Momo', 'Zalopay', 'BankTransfer', 'Promotion'];
      final methodName = methods[methodIndex];

      final payService = BusService();
      final success = await payService.confirmPayment(
        tripId: tripId,
        paymentMethod: methodName,
        transactionId: 'TXN-REPAY-$tripId-${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
      );

      if (mounted) Navigator.pop(context); // close loading
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanh toán thành công!')));
        }
        _fetchHistory();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanh toán thất bại.')));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
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
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String status;
  final String dateText;
  final List<String> extraLines;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onActionTap;

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
              if (onTap != null || actionLabel != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (onTap != null)
                      Expanded(
                        child: InkWell(
                          onTap: onTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
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
                          ),
                        ),
                      ),
                    if (actionLabel != null)
                      ElevatedButton(
                        onPressed: onActionTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          actionLabel!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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

