import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../services/api_service_base.dart';
import '../services/destination_service.dart';

class DestinationProvider with ChangeNotifier {
  final DestinationService _apiService = DestinationService();

  List<Destination> _destinations = const [];
  bool _isLoading = false;
  String? _error;
  int? _lastStatusCode;

  List<Destination> get destinations => List.unmodifiable(_destinations);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDestinations({bool forceRefresh = false}) async {
    if (!forceRefresh && _destinations.isNotEmpty && !_isLoading) {
      return;
    }

    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      _destinations = await _apiService.getDestinations();
    } catch (error) {
      _setError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _clearError() {
    _error = null;
    _lastStatusCode = null;
  }

  void _setError(Object error) {
    if (error is ApiException) {
      _lastStatusCode = error.statusCode;
      _error = error.message;
      return;
    }

    _lastStatusCode = null;
    _error = error.toString().replaceFirst('Exception: ', '');
  }
}
