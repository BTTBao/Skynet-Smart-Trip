class CreateFakePaymentRequest {
  const CreateFakePaymentRequest({required this.paymentMethod, this.amount});

  final String paymentMethod;
  final double? amount;

  Map<String, dynamic> toJson() {
    return {
      'paymentMethod': paymentMethod,
      if (amount != null) 'amount': amount,
    };
  }
}
