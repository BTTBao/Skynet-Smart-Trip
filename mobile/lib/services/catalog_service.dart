import 'package:http/http.dart' as http;

import '../models/catalog_models.dart';
import 'api_service_base.dart';

class CatalogService extends ApiService {
  Future<CatalogHomeData> getHome() async {
    final response = await getWithFallback('/catalog/home');
    final data = Map<String, dynamic>.from(handleResponse(response));
    return CatalogHomeData.fromJson(data);
  }

  Future<CatalogHotelSearchResult> searchHotels({
    String? query,
    int? destinationId,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<int>? starRatings,
    String? sort,
  }) async {
    final response = await _get(
      '/catalog/hotels',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
        if (destinationId != null) 'destinationId': '$destinationId',
        if (minPrice != null) 'minPrice': minPrice.round().toString(),
        if (maxPrice != null) 'maxPrice': maxPrice.round().toString(),
        if (minRating != null) 'minRating': minRating.toString(),
        if (starRatings != null && starRatings.isNotEmpty)
          'starRatings': starRatings.join(','),
        if (sort != null && sort.isNotEmpty) 'sort': sort,
      },
    );
    final data = Map<String, dynamic>.from(handleResponse(response));
    return CatalogHotelSearchResult.fromJson(data);
  }

  Future<CatalogHotelDetail> getHotelDetail(int hotelId) async {
    final response = await getWithFallback('/catalog/hotels/$hotelId');
    final data = Map<String, dynamic>.from(handleResponse(response));
    return CatalogHotelDetail.fromJson(data);
  }

  Future<CatalogRoomAvailability> getRoomAvailability({
    required int roomId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int quantity,
  }) async {
    final response = await _get(
      '/catalog/rooms/$roomId/availability',
      queryParameters: {
        'checkInDate': _formatDate(checkInDate),
        'checkOutDate': _formatDate(checkOutDate),
        'quantity': '$quantity',
      },
    );
    final data = Map<String, dynamic>.from(handleResponse(response));
    return CatalogRoomAvailability.fromJson(data);
  }

  Future<CatalogBusSearchResult> searchBuses({
    String? query,
    int? fromDestinationId,
    int? toDestinationId,
    double? minPrice,
    double? maxPrice,
    String? sort,
  }) async {
    final response = await _get(
      '/catalog/buses',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
        if (fromDestinationId != null)
          'fromDestinationId': '$fromDestinationId',
        if (toDestinationId != null) 'toDestinationId': '$toDestinationId',
        if (minPrice != null) 'minPrice': minPrice.round().toString(),
        if (maxPrice != null) 'maxPrice': maxPrice.round().toString(),
        if (sort != null && sort.isNotEmpty) 'sort': sort,
      },
    );
    final data = Map<String, dynamic>.from(handleResponse(response));
    return CatalogBusSearchResult.fromJson(data);
  }

  Future<CatalogBusDetail> getBusDetail(int scheduleId) async {
    final response = await getWithFallback('/catalog/buses/$scheduleId');
    final data = Map<String, dynamic>.from(handleResponse(response));
    return CatalogBusDetail.fromJson(data);
  }

  Future<CatalogVehicleRentalSearchResult> searchVehicleRentalShops({
    String? query,
    int? destinationId,
    double? minPrice,
    double? maxPrice,
    String? vehicleType,
    String? sort,
  }) async {
    final response = await _get(
      '/catalog/vehicle-rentals',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
        if (destinationId != null) 'destinationId': '$destinationId',
        if (minPrice != null) 'minPrice': minPrice.round().toString(),
        if (maxPrice != null) 'maxPrice': maxPrice.round().toString(),
        if (vehicleType != null && vehicleType.isNotEmpty)
          'vehicleType': vehicleType,
        if (sort != null && sort.isNotEmpty) 'sort': sort,
      },
    );
    final data = Map<String, dynamic>.from(handleResponse(response));
    return CatalogVehicleRentalSearchResult.fromJson(data);
  }

  Future<CatalogVehicleRentalShopDetail> getVehicleRentalShopDetail(
    int shopId,
  ) async {
    final response = await getWithFallback('/catalog/vehicle-rentals/$shopId');
    final data = Map<String, dynamic>.from(handleResponse(response));
    return CatalogVehicleRentalShopDetail.fromJson(data);
  }

  Future<http.Response> _get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    return getWithFallback(path, queryParameters: queryParameters);
  }

  Future<Map<String, dynamic>?> validatePromotion(String code) async {
    try {
      final response = await _get('/catalog/promotions/validate/$code');
      if (response.statusCode != 200) {
        return null;
      }
      final data = Map<String, dynamic>.from(handleResponse(response));
      return data;
    } catch (e) {
      return null;
    }
  }

  Future<List<CatalogPromotion>> getPromotions() async {
    final response = await _get('/catalog/promotions');
    final rawList = List<dynamic>.from(handleResponse(response));
    return rawList
        .map((item) => CatalogPromotion.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  String _formatDate(DateTime date) => DateTime(
        date.year,
        date.month,
        date.day,
      ).toIso8601String().split('T').first;
}

 