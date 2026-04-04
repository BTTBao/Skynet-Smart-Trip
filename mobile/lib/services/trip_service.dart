import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/create_trip_itinerary_request.dart';
import '../models/create_trip_request.dart';
import '../models/my_trip_summary.dart';
import '../models/trip_detail.dart';
import '../models/trip_service_option.dart';
import '../models/trip_timeline_entry.dart';
import '../models/update_trip_itinerary_request.dart';
import '../models/update_trip_request.dart';
import 'api_service_base.dart';

class TripService extends ApiService {
  Future<List<MyTripSummary>> getTripsByUser(int userId) async {
    final uri = buildUri(configuredBaseUrl, '/trips').replace(
      queryParameters: {'userId': '$userId'},
    );
    final response = await http.get(uri, headers: headers);

    final data = handleResponse(response) as List<dynamic>? ?? [];
    return data
        .map((item) => MyTripSummary.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<TripDetail> getTripDetail(int tripId) async {
    final response = await getWithFallback('/trips/$tripId');

    final data = Map<String, dynamic>.from(handleResponse(response));
    return TripDetail.fromJson(data);
  }

  Future<MyTripSummary> createTrip(CreateTripRequest request) async {
    final response = await postWithFallback(
      '/trips',
      body: jsonEncode(request.toJson()),
    );

    final data = Map<String, dynamic>.from(handleResponse(response));
    return MyTripSummary.fromJson(data);
  }

  Future<TripTimelineEntry> addItinerary(
    int tripId,
    CreateTripItineraryRequest request,
  ) async {
    final response = await postWithFallback(
      '/trips/$tripId/itineraries',
      body: jsonEncode(request.toJson()),
    );

    final data = Map<String, dynamic>.from(handleResponse(response));
    return TripTimelineEntry.fromJson(data);
  }

  Future<List<TripServiceOption>> getServiceOptions({
    required String serviceType,
    int? destinationId,
  }) async {
    final uri = buildUri(configuredBaseUrl, '/trips/service-options').replace(
      queryParameters: {
        'serviceType': serviceType,
        if (destinationId != null) 'destinationId': '$destinationId',
      },
    );

    final response = await http.get(uri, headers: headers);

    final data = handleResponse(response) as List<dynamic>? ?? [];
    return data
        .map((item) => TripServiceOption.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<MyTripSummary> updateTrip(int tripId, UpdateTripRequest request) async {
    final response = await putWithFallback(
      '/trips/$tripId',
      body: jsonEncode(request.toJson()),
    );

    final data = Map<String, dynamic>.from(handleResponse(response));
    return MyTripSummary.fromJson(data);
  }

  Future<TripTimelineEntry> updateItinerary(
    int itineraryId,
    UpdateTripItineraryRequest request,
  ) async {
    final response = await putWithFallback(
      '/trips/itineraries/$itineraryId',
      body: jsonEncode(request.toJson()),
    );

    final data = Map<String, dynamic>.from(handleResponse(response));
    return TripTimelineEntry.fromJson(data);
  }

  Future<void> deleteItinerary(int itineraryId) async {
    final response = await deleteWithFallback('/trips/itineraries/$itineraryId');

    handleResponse(response);
  }
}
