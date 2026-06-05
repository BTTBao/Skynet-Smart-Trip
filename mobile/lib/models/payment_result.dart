class PaymentResult {
  final int paymentId;
  final int? orderCode;
  final String? checkoutUrl;
  final String status;
  final DateTime? paidAt;
  final String? message;
  final String? providerResponseCode;
  final String? providerTransactionStatus;

  const PaymentResult({
    required this.paymentId,
    required this.orderCode,
    required this.checkoutUrl,
    required this.status,
    this.paidAt,
    this.message,
    this.providerResponseCode,
    this.providerTransactionStatus,
  });

  bool get isPaid => status.toUpperCase() == 'PAID';
  bool get isFailed => const {
    'FAILED',
    'CANCELLED',
    'EXPIRED',
    'INVALID_SIGNATURE',
  }.contains(status.toUpperCase());
  bool get isPending => status.toUpperCase() == 'PENDING';

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      paymentId: json['paymentId'] as int? ?? 0,
      orderCode: int.tryParse((json['orderCode'] ?? '').toString()),
      checkoutUrl: (json['checkoutUrl'] ?? json['paymentLink'])?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      paidAt: DateTime.tryParse(json['paidAt']?.toString() ?? ''),
      message: json['message']?.toString(),
      providerResponseCode: json['providerResponseCode']?.toString(),
      providerTransactionStatus: json['providerTransactionStatus']?.toString(),
    );
  }
}
