import 'package:flutter/material.dart';

import '../main_shell.dart';

class PaymentFailedScreen extends StatefulWidget {
  const PaymentFailedScreen({
    super.key,
    required this.totalPrice,
    this.status = 'FAILED',
    this.message,
    this.onRetry,
  });

  final double totalPrice;
  final String status;
  final String? message;
  final Future<void> Function()? onRetry;

  @override
  State<PaymentFailedScreen> createState() => _PaymentFailedScreenState();
}

class _PaymentFailedScreenState extends State<PaymentFailedScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    final retry = widget.onRetry;
    if (retry == null || _retrying) return;
    setState(() => _retrying = true);
    Navigator.pop(context);
    await retry();
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status.toUpperCase();
    final cancelled = status == 'CANCELLED' || status == 'EXPIRED';
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toan'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 32),
          CircleAvatar(
            radius: 56,
            backgroundColor: Colors.red[50],
            child: Icon(
              cancelled ? Icons.timer_off_outlined : Icons.close,
              color: Colors.red[400],
              size: 48,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            cancelled
                ? 'Giao dich da huy hoac het han'
                : 'Thanh toan khong thanh cong',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            widget.message ??
                'Chua co khoan tien nao duoc ghi nhan. Ban co the thu lai hoac chon phuong thuc thanh toan khac.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TONG CONG',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      _formatPrice(widget.totalPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                Chip(label: Text(cancelled ? 'DA HUY' : 'CHO THANH TOAN')),
              ],
            ),
          ),
          const SizedBox(height: 36),
          FilledButton.icon(
            onPressed: widget.onRetry == null || _retrying ? null : _retry,
            icon: _retrying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: const Text('Thu lai'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Doi phuong thuc thanh toan'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainShell()),
              (_) => false,
            ),
            child: const Text('Ve trang chu'),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double value) =>
      '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}d';
}
