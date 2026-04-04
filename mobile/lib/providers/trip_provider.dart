import 'package:flutter/material.dart';

import '../models/create_trip_itinerary_request.dart';
import '../models/create_trip_request.dart';
import '../models/my_trip_summary.dart';
import '../models/trip_detail.dart';
import '../models/trip_service_option.dart';
import '../models/update_trip_itinerary_request.dart';
import '../models/update_trip_request.dart';
import '../services/trip_service.dart';

class TripProvider with ChangeNotifier {
  final TripService _tripService = TripService();

  List<MyTripSummary> _trips = [];
  TripDetail? _currentTrip;
  int? _currentTripId;
  int _currentUserId = 1;
  bool _isLoadingTrips = false;
  bool _isLoadingTripDetail = false;
  bool _isSubmitting = false;
  String? _error;

  List<MyTripSummary> get trips => List.unmodifiable(_trips);
  TripDetail? get currentTrip => _currentTrip;
  int? get currentTripId => _currentTripId;
  bool get isLoadingTrips => _isLoadingTrips;
  bool get isLoadingTripDetail => _isLoadingTripDetail;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  List<MyTripSummary> get upcomingTrips {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _trips
        .where((trip) =>
            !DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day)
                .isBefore(today) &&
            trip.status != 'CANCELLED')
        .toList();
  }

  List<MyTripSummary> get completedTrips {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _trips
        .where((trip) =>
            DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day)
                    .isBefore(today) ||
            trip.status == 'CANCELLED')
        .toList();
  }

  Future<void> fetchTrips({int userId = 1, bool silent = false}) async {
    _currentUserId = userId;
    if (!silent) {
      _isLoadingTrips = true;
      _error = null;
      notifyListeners();
    }

    try {
      _trips = await _tripService.getTripsByUser(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingTrips = false;
      notifyListeners();
    }
  }

  Future<TripDetail?> fetchTripDetail(int tripId) async {
    _currentTripId = tripId;
    _isLoadingTripDetail = true;
    _error = null;
    notifyListeners();

    try {
      _currentTrip = await _tripService.getTripDetail(tripId);
      return _currentTrip;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoadingTripDetail = false;
      notifyListeners();
    }
  }

  Future<MyTripSummary?> createTrip(CreateTripRequest request) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final createdTrip = await _tripService.createTrip(request);
      _currentUserId = request.userId;
      _trips = [
        createdTrip,
        ..._trips.where((trip) => trip.tripId != createdTrip.tripId),
      ];
      return createdTrip;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> addItinerary(
    int tripId,
    CreateTripItineraryRequest request,
  ) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _tripService.addItinerary(tripId, request);
      await fetchTripDetail(tripId);
      await fetchTrips(userId: _currentUserId, silent: true);
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<List<TripServiceOption>> getServiceOptions({
    required String serviceType,
    int? destinationId,
  }) {
    return _tripService.getServiceOptions(
      serviceType: serviceType,
      destinationId: destinationId,
    );
  }

  Future<bool> updateTrip(int tripId, UpdateTripRequest request) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final updatedTrip = await _tripService.updateTrip(tripId, request);
      // Update local trips list
      final index = _trips.indexWhere((t) => t.tripId == tripId);
      if (index != -1) {
        _trips[index] = updatedTrip;
      }

      // If updating current trip, refresh detail
      if (_currentTripId == tripId) {
        await fetchTripDetail(tripId);
      } else {
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateItinerary(
    int itineraryId,
    UpdateTripItineraryRequest request,
  ) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _tripService.updateItinerary(itineraryId, request);
      if (_currentTripId != null) {
        await fetchTripDetail(_currentTripId!);
        await fetchTrips(userId: _currentUserId, silent: true);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteItinerary(int itineraryId) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _tripService.deleteItinerary(itineraryId);
      if (_currentTripId != null) {
        await fetchTripDetail(_currentTripId!);
        await fetchTrips(userId: _currentUserId, silent: true);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
