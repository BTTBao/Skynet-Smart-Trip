import 'package:flutter/material.dart';

import '../models/catalog_models.dart';
import '../services/catalog_service.dart';

class CatalogProvider extends ChangeNotifier {
  final CatalogService _catalogService = CatalogService();

  CatalogHomeData? _homeData;
  CatalogHotelSearchResult _hotelSearchResult = const CatalogHotelSearchResult(
    total: 0,
    items: [],
  );
  CatalogBusSearchResult _busSearchResult = const CatalogBusSearchResult(
    total: 0,
    items: [],
  );
  CatalogHotelDetail? _selectedHotel;
  CatalogBusDetail? _selectedBus;
  bool _isLoadingHome = false;
  bool _isSearchingHotels = false;
  bool _isSearchingBuses = false;
  bool _isLoadingHotelDetail = false;
  bool _isLoadingBusDetail = false;
  String? _error;

  CatalogHomeData? get homeData => _homeData;
  CatalogHotelSearchResult get hotelSearchResult => _hotelSearchResult;
  CatalogBusSearchResult get busSearchResult => _busSearchResult;
  CatalogHotelDetail? get selectedHotel => _selectedHotel;
  CatalogBusDetail? get selectedBus => _selectedBus;
  bool get isLoadingHome => _isLoadingHome;
  bool get isSearchingHotels => _isSearchingHotels;
  bool get isSearchingBuses => _isSearchingBuses;
  bool get isLoadingHotelDetail => _isLoadingHotelDetail;
  bool get isLoadingBusDetail => _isLoadingBusDetail;
  String? get error => _error;

  Future<void> loadHome({bool forceRefresh = false}) async {
    if (_homeData != null && !forceRefresh) {
      return;
    }

    _isLoadingHome = true;
    _error = null;
    notifyListeners();

    try {
      _homeData = await _catalogService.getHome();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingHome = false;
      notifyListeners();
    }
  }

  Future<void> searchHotels({
    String? query,
    int? destinationId,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<int>? starRatings,
    String? sort,
  }) async {
    _isSearchingHotels = true;
    _error = null;
    notifyListeners();

    try {
      _hotelSearchResult = await _catalogService.searchHotels(
        query: query,
        destinationId: destinationId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
        starRatings: starRatings,
        sort: sort,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSearchingHotels = false;
      notifyListeners();
    }
  }

  Future<void> searchBuses({
    String? query,
    int? fromDestinationId,
    int? toDestinationId,
    double? minPrice,
    double? maxPrice,
    String? sort,
  }) async {
    _isSearchingBuses = true;
    _error = null;
    notifyListeners();

    try {
      _busSearchResult = await _catalogService.searchBuses(
        query: query,
        fromDestinationId: fromDestinationId,
        toDestinationId: toDestinationId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sort: sort,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSearchingBuses = false;
      notifyListeners();
    }
  }

  Future<CatalogHotelDetail?> loadHotelDetail(int hotelId) async {
    _isLoadingHotelDetail = true;
    _error = null;
    notifyListeners();

    try {
      _selectedHotel = await _catalogService.getHotelDetail(hotelId);
      return _selectedHotel;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoadingHotelDetail = false;
      notifyListeners();
    }
  }

  Future<CatalogBusDetail?> loadBusDetail(int scheduleId) async {
    _isLoadingBusDetail = true;
    _error = null;
    notifyListeners();

    try {
      _selectedBus = await _catalogService.getBusDetail(scheduleId);
      return _selectedBus;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoadingBusDetail = false;
      notifyListeners();
    }
  }
}
