import 'dart:convert';
import '../models/bus_schedule_model.dart';
import 'api_service_base.dart';

class BusService extends ApiService {
  Future<List<BusScheduleModel>> getSchedules({
    int? fromDestId,
    int? toDestId,
    String? date,
  }) async {
    final response = await getWithFallback(
      '/bus/schedules',
      queryParameters: {
        if (fromDestId != null) 'fromDestId': '$fromDestId',
        if (toDestId != null) 'toDestId': '$toDestId',
        if (date != null) 'date': date,
      },
    );
    final data = handleResponse(response) as List<dynamic>? ?? [];

    return data
        .map(
          (item) => BusScheduleModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<List<BusSeatModel>> getSeats(int scheduleId) async {
    final response = await getWithFallback('/bus/schedules/$scheduleId/seats');
    final data = handleResponse(response) as List<dynamic>? ?? [];

    return data
        .map((item) => BusSeatModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<bool> confirmPayment({
    required int tripId,
    required String paymentMethod,
    required String transactionId,
    required double amount,
    int? scheduleId,
    List<String>? selectedSeats,
    bool isDeposit = false,
    int? usedCoins,
  }) async {
    final response = await postWithFallback(
      '/trips/$tripId/pay',
      requireAuth: true,
      body: jsonEncode({
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'amount': amount,
        if (scheduleId != null) 'scheduleId': scheduleId,
        if (selectedSeats != null) 'selectedSeats': selectedSeats,
        'isDeposit': isDeposit,
        if (usedCoins != null) 'usedCoins': usedCoins,
      }),
    );

    final result = handleResponse(response) as Map<String, dynamic>? ?? {};
    return result['status'] == 'PAID';
  }
}
