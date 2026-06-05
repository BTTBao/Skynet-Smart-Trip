import 'package:flutter/material.dart';
import '../models/bus_schedule_model.dart';
import '../services/bus_service.dart';

class BusProvider with ChangeNotifier {
  final BusService _busService = BusService();

  List<BusScheduleModel> _schedules = [];
  List<BusSeatModel> _seats = [];

  bool _isLoadingSchedules = false;
  bool _isLoadingSeats = false;
  bool _isSubmitting = false;
  String? _error;
  String? _scheduleError;
  String? _seatError;

  BusScheduleModel? _selectedSchedule;
  List<String> _selectedSeatNumbers = [];

  List<BusScheduleModel> get schedules => List.unmodifiable(_schedules);
  List<BusSeatModel> get seats => List.unmodifiable(_seats);

  bool get isLoadingSchedules => _isLoadingSchedules;
  bool get isLoadingSeats => _isLoadingSeats;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  String? get scheduleError => _scheduleError;
  String? get seatError => _seatError;

  BusScheduleModel? get selectedSchedule => _selectedSchedule;
  List<String> get selectedSeatNumbers => _selectedSeatNumbers;

  void selectSchedule(BusScheduleModel? schedule) {
    _selectedSchedule = schedule;
    _seats = [];
    _selectedSeatNumbers = [];
    notifyListeners();
  }

  bool toggleSeatSelection(String seatNumber) {
    if (_selectedSeatNumbers.contains(seatNumber)) {
      _selectedSeatNumbers.remove(seatNumber);
    } else if (_selectedSeatNumbers.length >= 5) {
      notifyListeners();
      return false;
    } else {
      _selectedSeatNumbers.add(seatNumber);
    }
    notifyListeners();
    return true;
  }

  void clearSeatSelection() {
    _selectedSeatNumbers = [];
    notifyListeners();
  }

  Future<void> fetchSchedules({
    int? fromDestId,
    int? toDestId,
    String? date,
  }) async {
    _isLoadingSchedules = true;
    _error = null;
    _scheduleError = null;
    notifyListeners();

    try {
      _schedules = await _busService.getSchedules(
        fromDestId: fromDestId,
        toDestId: toDestId,
        date: date,
      );
      _error = null;
      _scheduleError = null;
    } catch (e) {
      _error = e.toString();
      _scheduleError = e.toString();
    } finally {
      _isLoadingSchedules = false;
      notifyListeners();
    }
  }

  Future<List<BusSeatModel>> fetchSeats(int scheduleId) async {
    _isLoadingSeats = true;
    _error = null;
    _seatError = null;
    notifyListeners();

    try {
      _seats = await _busService.getSeats(scheduleId);
      _error = null;
      _seatError = null;
      return _seats;
    } catch (e) {
      _error = e.toString();
      _seatError = e.toString();
      return [];
    } finally {
      _isLoadingSeats = false;
      notifyListeners();
    }
  }

  Future<bool> confirmCheckoutPayment({
    required int tripId,
    required int scheduleId,
    required String paymentMethod,
    required String transactionId,
    required double amount,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _busService.confirmPayment(
        tripId: tripId,
        scheduleId: scheduleId,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        amount: amount,
        selectedSeats: _selectedSeatNumbers,
      );
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
