import 'package:flutter/material.dart';
import '../models/resort_model.dart';
import '../services/api_service_base.dart';
import '../services/hotel_service.dart';

class HotelProvider with ChangeNotifier {
  final HotelService _service = HotelService();

  // Danh sách hotels
  List<ResortModel> _hotels = const [];
  bool _isLoadingList = false;
  String? _listError;

  // Chi tiết hotel đang xem
  ResortModel? _selectedHotel;
  bool _isLoadingDetail = false;
  String? _detailError;

  // Lịch giá động
  List<HotelCalendarDay> _calendarDays = const [];
  bool _isLoadingCalendar = false;
  String? _calendarError;
  int _calendarYear = 0;
  int _calendarMonth = 0;
  int? _calendarRoomId;

  // Getters
  List<ResortModel> get hotels => List.unmodifiable(_hotels);
  bool get isLoadingList => _isLoadingList;
  String? get listError => _listError;

  ResortModel? get selectedHotel => _selectedHotel;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get detailError => _detailError;

  List<HotelCalendarDay> get calendarDays => List.unmodifiable(_calendarDays);
  bool get isLoadingCalendar => _isLoadingCalendar;
  String? get calendarError => _calendarError;

  /// Lấy danh sách hotels theo destinationId
  Future<void> fetchHotels({int? destinationId, bool forceRefresh = false}) async {
    if (!forceRefresh && _hotels.isNotEmpty && !_isLoadingList) return;

    _isLoadingList = true;
    _listError = null;
    notifyListeners();

    try {
      _hotels = await _service.getHotels(destinationId: destinationId);
    } catch (e) {
      _listError = _extractError(e);
    } finally {
      _isLoadingList = false;
      notifyListeners();
    }
  }

  /// Lấy chi tiết một hotel
  Future<void> fetchHotelDetail(int hotelId, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _selectedHotel?.id == hotelId &&
        _selectedHotel != null &&
        !_isLoadingDetail) {
      return;
    }

    _selectedHotel = null;
    _isLoadingDetail = true;
    _detailError = null;
    notifyListeners();

    try {
      _selectedHotel = await _service.getHotelDetail(hotelId);
    } catch (e) {
      _detailError = _extractError(e);
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Lấy lịch giá của một tháng — giống Agoda/Booking.com
  Future<void> fetchCalendar(
    int hotelId, {
    required int year,
    required int month,
    int? roomId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _calendarYear == year &&
        _calendarMonth == month &&
        _calendarRoomId == roomId &&
        _calendarDays.isNotEmpty &&
        !_isLoadingCalendar) {
      return;
    }

    _isLoadingCalendar = true;
    _calendarError = null;
    _calendarYear = year;
    _calendarMonth = month;
    _calendarRoomId = roomId;
    notifyListeners();

    try {
      _calendarDays = await _service.getCalendar(
        hotelId,
        year: year,
        month: month,
        roomId: roomId,
      );
    } catch (e) {
      _calendarError = _extractError(e);
    } finally {
      _isLoadingCalendar = false;
      notifyListeners();
    }
  }

  void clearCalendar() {
    _calendarDays = const [];
    _calendarYear = 0;
    _calendarMonth = 0;
    _calendarRoomId = null;
  }

  String _extractError(Object e) {
    if (e is ApiException) return e.message;
    return e.toString().replaceFirst('Exception: ', '');
  }
}
