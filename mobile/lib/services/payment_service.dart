import 'dart:convert';

import '../models/payment_result.dart';
import 'api_service_base.dart';

class PaymentService extends ApiService {
  Future<PaymentResult> createPayOsPayment({
    required int tripId,
    required double amount,
    required String description,
    required int orderCode,
    Map<String, dynamic>? metadata,
  }) async {
    final returnUrl =
        '$configuredBaseUrl/payments/payos/return?orderCode=$orderCode';
    final cancelUrl =
        '$configuredBaseUrl/payments/payos/cancel?orderCode=$orderCode';

    final response = await postWithFallback(
      '/payments',
      requireAuth: true,
      body: jsonEncode({
        'amount': amount.round(),
        'description': description,
        'orderCode': orderCode,
        'returnUrl': returnUrl,
        'cancelUrl': cancelUrl,
        'metadata': {'tripId': tripId, if (metadata != null) ...metadata},
      }),
    );

    final data = Map<String, dynamic>.from(handleResponse(response));
    return PaymentResult.fromJson(data);
  }

  Future<PaymentResult> createVnPayPayment({
    required int tripId,
    required double amount,
    required String description,
    String locale = 'vn',
    Map<String, dynamic>? metadata,
  }) async {
    final response = await postWithFallback(
      '/payments/vnpay/create',
      requireAuth: true,
      body: jsonEncode({
        'amount': amount.round(),
        'description': description,
        'locale': locale,
        'metadata': {'tripId': tripId, if (metadata != null) ...metadata},
      }),
    );

    final data = Map<String, dynamic>.from(handleResponse(response));
    return PaymentResult.fromJson(data);
  }

  Future<PaymentResult> getPaymentByOrderCode(int orderCode) async {
    final response = await getWithFallback(
      '/payments/order/$orderCode',
      requireAuth: true,
    );

    final data = Map<String, dynamic>.from(handleResponse(response));
    return PaymentResult.fromJson(data);
  }
}
