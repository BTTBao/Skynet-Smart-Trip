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
    int? usedCoins,
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
        'metadata': {
          'tripId': tripId,
          if (usedCoins != null) 'usedCoins': usedCoins,
          if (metadata != null) ...metadata
        },
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
    int? usedCoins,
  }) async {
    final response = await postWithFallback(
      '/payments/vnpay/create',
      requireAuth: true,
      body: jsonEncode({
        'amount': amount.round(),
        'description': description,
        'locale': locale,
        'metadata': {
          'tripId': tripId,
          if (usedCoins != null) 'usedCoins': usedCoins,
          if (metadata != null) ...metadata
        },
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

  Future<PaymentResult> createWalletDeposit({
    required double amount,
    String locale = 'vn',
    String paymentMethod = 'VNPAY',
    int? orderCode,
  }) async {
    final Map<String, dynamic> body = {
      'amount': amount.round(),
      'locale': locale,
      'paymentMethod': paymentMethod,
    };

    if (paymentMethod == 'PAYOS' && orderCode != null) {
      body['orderCode'] = orderCode;
      body['returnUrl'] = '$configuredBaseUrl/payments/payos/return?orderCode=$orderCode';
      body['cancelUrl'] = '$configuredBaseUrl/payments/payos/cancel?orderCode=$orderCode';
    }

    final response = await postWithFallback(
      '/payments/wallet/deposit',
      requireAuth: true,
      body: jsonEncode(body),
    );

    final data = Map<String, dynamic>.from(handleResponse(response));
    return PaymentResult.fromJson(data);
  }

  Future<Map<String, dynamic>> withdrawFromWallet({
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    final response = await postWithFallback(
      '/payments/wallet/withdraw',
      requireAuth: true,
      body: jsonEncode({
        'amount': amount,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountName': accountName,
      }),
    );

    return Map<String, dynamic>.from(handleResponse(response));
  }

  Future<Map<String, dynamic>> payWithWallet({
    required int tripId,
    required double amount,
    required bool isDeposit,
    int? usedCoins,
  }) async {
    final response = await postWithFallback(
      '/payments/wallet/pay',
      requireAuth: true,
      body: jsonEncode({
        'tripId': tripId,
        'amount': amount,
        'isDeposit': isDeposit,
        if (usedCoins != null) 'usedCoins': usedCoins,
      }),
    );

    return Map<String, dynamic>.from(handleResponse(response));
  }
}
