import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InvoiceDetailView extends StatelessWidget {
  const InvoiceDetailView({
    super.key,
    required this.title,
    required this.serviceType,
    required this.providerName,
    required this.routeOrAddress,
    required this.dateText,
    required this.quantityText,
    required this.amount,
    required this.status,
    required this.invoiceNumber,
    this.transactionId,
    this.paymentMethod,
  });

  final String title;
  final String serviceType;
  final String providerName;
  final String routeOrAddress;
  final String dateText;
  final String quantityText;
  final double amount;
  final String status;
  final String? invoiceNumber;
  final String? transactionId;
  final String? paymentMethod;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Chi tiết hóa đơn'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F8EE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFF0D6B42),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoiceNumber?.isNotEmpty == true
                                ? invoiceNumber!
                                : 'Chưa có mã hóa đơn',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status,
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _InfoRow(label: 'Dịch vụ', value: serviceType),
                _InfoRow(label: 'Tiêu đề', value: title),
                _InfoRow(label: 'Đơn vị', value: providerName),
                _InfoRow(label: 'Địa điểm/Tuyến', value: routeOrAddress),
                _InfoRow(label: 'Thời gian', value: dateText),
                _InfoRow(label: 'Số lượng', value: quantityText),
                if ((paymentMethod ?? '').isNotEmpty)
                  _InfoRow(label: 'Thanh toán', value: paymentMethod!),
                if ((transactionId ?? '').isNotEmpty)
                  _InfoRow(label: 'Mã giao dịch', value: transactionId!),
                const Divider(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng cộng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      currency.format(amount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D6B42),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
