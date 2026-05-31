import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bus_schedule_model.dart';
import 'api_service_base.dart';

class BusService extends ApiService {
  Future<List<BusScheduleModel>> getSchedules({
    int? fromDestId,
    int? toDestId,
    String? date,
  }) async {
    final uri = buildUri(configuredBaseUrl, '/bus/schedules').replace(
      queryParameters: {
        if (fromDestId != null) 'fromDestId': '$fromDestId',
        if (toDestId != null) 'toDestId': '$toDestId',
        if (date != null) 'date': date,
      },
    );

    final response = await http.get(uri, headers: headers);
    final data = handleResponse(response) as List<dynamic>? ?? [];
    
    return data
        .map((item) => BusScheduleModel.fromJson(Map<String, dynamic>.from(item)))
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
    List<String>? selectedSeats,
  }) async {
    final response = await postWithFallback(
      '/trips/$tripId/pay',
      body: jsonEncode({
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'amount': amount,
        if (selectedSeats != null) 'selectedSeats': selectedSeats,
      }),
    );
    
    final result = handleResponse(response) as Map<String, dynamic>? ?? {};
    return result['status'] == 'PAID';
  }
}
