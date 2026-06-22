import 'package:flutter/material.dart';

import '../models/create_trip_itinerary_request.dart';
import '../models/create_fake_payment_request.dart';
import '../models/create_hotel_booking_request.dart';
import '../models/create_trip_request.dart';
import '../models/my_trip_summary.dart';
import '../models/trip_detail.dart';
import '../models/trip_service_option.dart';
import '../models/update_trip_itinerary_request.dart';
import '../models/update_trip_request.dart';
import '../services/trip_service.dart';

class TripProvider with ChangeNotifier {
  final TripService _tripService = TripService();
  static const String _bookingOnlyStatus = 'BOOKING_ONLY';
  static const List<String> _bookingOnlyTitlePrefixes = [
    'Hóa đơn đặt phòng - ',
    'Hóa đơn vé xe - ',
    'Đặt phòng - ',
    'Đặt vé xe - ',
  ];

  List<MyTripSummary> _trips = [];
  TripDetail? _currentTrip;
  int? _currentTripId;
  bool _isLoadingTrips = false;
  bool _isLoadingTripDetail = false;
  bool _isSubmitting = false;
  bool _isSearchingSharedTrip = false;
  String? _error;

  /// Itinerary IDs excluded from the map route per trip (persists while app runs).
  final Map<int, Set<int>> _mapRouteExcludedItineraryIdsByTrip = {};

  List<MyTripSummary> get trips => List.unmodifiable(_trips);
  TripDetail? get currentTrip => _currentTrip;
  int? get currentTripId => _currentTripId;
  bool get isLoadingTrips => _isLoadingTrips;
  bool get isLoadingTripDetail => _isLoadingTripDetail;
  bool get isSubmitting => _isSubmitting;
  bool get isSearchingSharedTrip => _isSearchingSharedTrip;
  String? get error => _error;

  Set<int> mapRouteExcludedItineraryIds(int tripId) {
    return Set.unmodifiable(
      _mapRouteExcludedItineraryIdsByTrip[tripId] ?? const <int>{},
    );
  }

  void setMapRouteItineraryExcluded(
    int tripId,
    int itineraryId,
    bool excluded,
  ) {
    final current = _mapRouteExcludedItineraryIdsByTrip.putIfAbsent(
      tripId,
      () => <int>{},
    );
    if (excluded) {
      current.add(itineraryId);
    } else {
      current.remove(itineraryId);
      if (current.isEmpty) {
        _mapRouteExcludedItineraryIdsByTrip.remove(tripId);
      }
    }
  }

  void _pruneMapRouteExcludedItineraryIds(
    int tripId,
    Iterable<int> validItineraryIds,
  ) {
    final validIds = validItineraryIds.toSet();
    final current = _mapRouteExcludedItineraryIdsByTrip[tripId];
    if (current == null) {
      return;
    }

    current.removeWhere((id) => !validIds.contains(id));
    if (current.isEmpty) {
      _mapRouteExcludedItineraryIdsByTrip.remove(tripId);
    }
  }

  bool _isBookingOnlyPlaceholder(MyTripSummary trip) {
    if (trip.status == _bookingOnlyStatus) {
      return true;
    }

    final normalizedTitle = trip.title.trim();
    return _bookingOnlyTitlePrefixes.any(
      (prefix) => normalizedTitle.startsWith(prefix),
    );
  }

  List<MyTripSummary> get upcomingTrips {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _trips
        .where(
          (trip) =>
              !_isBookingOnlyPlaceholder(trip) &&
              !DateTime(
                trip.endDate.year,
                trip.endDate.month,
                trip.endDate.day,
              ).isBefore(today) &&
              trip.status != 'CANCELLED',
        )
        .toList();
  }

  List<MyTripSummary> get completedTrips {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _trips
        .where(
          (trip) =>
              !_isBookingOnlyPlaceholder(trip) &&
              (DateTime(
                    trip.endDate.year,
                    trip.endDate.month,
                    trip.endDate.day,
                  ).isBefore(today) ||
                  trip.status == 'CANCELLED'),
        )
        .toList();
  }

  Future<void> fetchTrips({bool silent = false}) async {
    if (!silent) {
      _isLoadingTrips = true;
      _error = null;
      notifyListeners();
    }

    try {
      _trips = await _tripService.getTrips();
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
      final itineraryIds = _currentTrip?.itineraries
              .map((entry) => entry.itineraryId)
              .whereType<int>() ??
          const <int>[];
      _pruneMapRouteExcludedItineraryIds(tripId, itineraryIds);
      return _currentTrip;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoadingTripDetail = false;
      notifyListeners();
    }
  }

  Future<TripDetail?> fetchSharedTripDetail(String shareCode) async {
    final normalizedCode = shareCode.trim();
    if (normalizedCode.isEmpty) {
      _error = 'Nhập mã chuyến đi để tìm kiếm.';
      notifyListeners();
      return null;
    }

    _isSearchingSharedTrip = true;
    _error = null;
    notifyListeners();

    try {
      final sharedTrip = await _tripService.getSharedTripDetail(normalizedCode);
      _currentTripId = sharedTrip.tripId;
      _currentTrip = sharedTrip;
      return sharedTrip;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isSearchingSharedTrip = false;
      notifyListeners();
    }
  }

  Future<MyTripSummary?> saveSharedTrip(String shareCode) async {
    final normalizedCode = shareCode.trim();
    if (normalizedCode.isEmpty) {
      _error = 'Nhập mã chuyến đi để lưu.';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final savedTrip = await _tripService.saveSharedTrip(normalizedCode);
      _trips = [
        savedTrip,
        ..._trips.where((trip) => trip.tripId != savedTrip.tripId),
      ];
      await fetchTripDetail(savedTrip.tripId);
      return savedTrip;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  MyTripSummary? findTripByShareCode(String shareCode) {
    final normalized = shareCode.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }

    for (final trip in _trips) {
      if (trip.shareCode.trim().toUpperCase() == normalized) {
        return trip;
      }
    }
    return null;
  }

  MyTripSummary? findSavedCopyOfTrip(int sourceTripId) {
    for (final trip in _trips) {
      if (trip.sharedFromTripId == sourceTripId) {
        return trip;
      }
    }
    return null;
  }

  Future<MyTripSummary?> createTrip(CreateTripRequest request) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final createdTrip = await _tripService.createTrip(request);
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

  Future<MyTripSummary?> createHotelBooking(
    CreateHotelBookingRequest request,
  ) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final createdTrip = await _tripService.createHotelBooking(request);
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

  Future<MyTripSummary?> completeFakePayment(
    int tripId,
    CreateFakePaymentRequest request,
  ) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final updatedTrip = await _tripService.completeFakePayment(
        tripId,
        request,
      );
      final index = _trips.indexWhere((trip) => trip.tripId == tripId);
      if (index != -1) {
        _trips[index] = updatedTrip;
      } else {
        _trips = [updatedTrip, ..._trips];
      }

      if (_currentTripId == tripId) {
        await fetchTripDetail(tripId);
      } else {
        notifyListeners();
      }

      return updatedTrip;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<int?> addItinerary(
    int tripId,
    CreateTripItineraryRequest request,
  ) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final entry = await _tripService.addItinerary(tripId, request);
      await fetchTripDetail(tripId);
      await fetchTrips(silent: true);
      return entry.itineraryId;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return null;
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

  Future<MyTripSummary?> updateTrip(int tripId, UpdateTripRequest request) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final updatedTrip = await _tripService.updateTrip(tripId, request);
      final index = _trips.indexWhere((t) => t.tripId == tripId);
      if (index != -1) {
        _trips[index] = updatedTrip;
      }

      if (_currentTripId == tripId) {
        await fetchTripDetail(tripId);
      } else {
        notifyListeners();
      }
      return updatedTrip;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTrip(int tripId) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _tripService.deleteTrip(tripId);
      _trips.removeWhere((trip) => trip.tripId == tripId);
      _mapRouteExcludedItineraryIdsByTrip.remove(tripId);
      if (_currentTripId == tripId) {
        _currentTrip = null;
        _currentTripId = null;
      }
      return true;
    } catch (e) {
      _error = e.toString();
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
        await fetchTrips(silent: true);
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
        final tripId = _currentTripId!;
        _mapRouteExcludedItineraryIdsByTrip[tripId]?.remove(itineraryId);
        if (_mapRouteExcludedItineraryIdsByTrip[tripId]?.isEmpty ?? false) {
          _mapRouteExcludedItineraryIdsByTrip.remove(tripId);
        }
        await fetchTripDetail(tripId);
        await fetchTrips(silent: true);
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

  Future<bool> cancelBooking(int tripId) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _tripService.cancelBooking(tripId);
      await fetchTrips(silent: true);
      if (_currentTripId == tripId) {
        await fetchTripDetail(tripId);
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
