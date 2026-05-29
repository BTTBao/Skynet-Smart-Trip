class CreateFakePaymentRequest {
  const CreateFakePaymentRequest({required this.paymentMethod});

  final String paymentMethod;

  Map<String, dynamic> toJson() {
    return {
      'paymentMethod': paymentMethod,
    };
  }
}
