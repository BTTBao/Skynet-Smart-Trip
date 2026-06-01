class PaymentResult {
  final int paymentId;
  final int? orderCode;
  final String? checkoutUrl;
  final String status;
  final DateTime? paidAt;

  const PaymentResult({
    required this.paymentId,
    required this.orderCode,
    required this.checkoutUrl,
    required this.status,
    this.paidAt,
  });

  bool get isPaid => status.toUpperCase() == 'PAID';

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      paymentId: json['paymentId'] as int? ?? 0,
      orderCode: int.tryParse((json['orderCode'] ?? '').toString()),
      checkoutUrl: (json['checkoutUrl'] ?? json['paymentLink'])?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      paidAt: DateTime.tryParse(json['paidAt']?.toString() ?? ''),
    );
  }
}
