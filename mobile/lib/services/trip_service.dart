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
import 'api_service.dart';

class TripService extends ApiService {
  Future<List<MyTripSummary>> getTripsByUser(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/trips?userId=$userId'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response) as List<dynamic>? ?? [];
    return data
        .map((item) => MyTripSummary.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<TripDetail> getTripDetail(int tripId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/trips/$tripId'),
      headers: await getHeaders(),
    );

    final data = Map<String, dynamic>.from(handleResponse(response));
    return TripDetail.fromJson(data);
  }

  Future<MyTripSummary> createTrip(CreateTripRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips'),
      headers: await getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    final data = Map<String, dynamic>.from(handleResponse(response));
    return MyTripSummary.fromJson(data);
  }

  Future<TripTimelineEntry> addItinerary(
    int tripId,
    CreateTripItineraryRequest request,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips/$tripId/itineraries'),
      headers: await getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    final data = Map<String, dynamic>.from(handleResponse(response));
    return TripTimelineEntry.fromJson(data);
  }

  Future<List<TripServiceOption>> getServiceOptions({
    required String serviceType,
    int? destinationId,
  }) async {
    final uri = Uri.parse('$baseUrl/trips/service-options').replace(
      queryParameters: {
        'serviceType': serviceType,
        if (destinationId != null) 'destinationId': '$destinationId',
      },
    );

    final response = await http.get(
      uri,
      headers: await getHeaders(),
    );

    final data = handleResponse(response) as List<dynamic>? ?? [];
    return data
        .map((item) => TripServiceOption.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<MyTripSummary> updateTrip(int tripId, UpdateTripRequest request) async {
    final response = await http.put(
      Uri.parse('$baseUrl/trips/$tripId'),
      headers: await getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    final data = Map<String, dynamic>.from(handleResponse(response));
    return MyTripSummary.fromJson(data);
  }

  Future<TripTimelineEntry> updateItinerary(
    int itineraryId,
    UpdateTripItineraryRequest request,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/trips/itineraries/$itineraryId'),
      headers: await getHeaders(),
      body: jsonEncode(request.toJson()),
    );

    final data = Map<String, dynamic>.from(handleResponse(response));
    return TripTimelineEntry.fromJson(data);
  }

  Future<void> deleteItinerary(int itineraryId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/trips/itineraries/$itineraryId'),
      headers: await getHeaders(),
    );

    handleResponse(response);
  }
}
