import '../models/resort_model.dart';
import 'api_service_base.dart';

class HotelService extends ApiService {
  /// Lấy danh sách khách sạn theo điểm đến (có thể null để lấy tất cả)
  Future<List<ResortModel>> getHotels({int? destinationId}) async {
    final path = destinationId != null
        ? '/hotel?destinationId=$destinationId'
        : '/hotel';
    final response = await getWithFallback(path, requireAuth: false);
    final data = handleResponse(response) as List<dynamic>;
    return data.map((e) => ResortModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Lấy chi tiết một khách sạn (ảnh, phòng, tiện nghi, đánh giá)
  Future<ResortModel> getHotelDetail(int hotelId) async {
    final response = await getWithFallback('/hotel/$hotelId', requireAuth: false);
    final data = handleResponse(response) as Map<String, dynamic>;
    return ResortModel.fromJson(data);
  }

  /// Lấy lịch giá động theo tháng — giống Booking.com / Agoda
  Future<List<HotelCalendarDay>> getCalendar(
    int hotelId, {
    required int year,
    required int month,
    int? roomId,
  }) async {
    final roomQuery = roomId == null ? '' : '&roomId=$roomId';
    final response = await getWithFallback(
      '/hotel/$hotelId/calendar?year=$year&month=$month$roomQuery',
      requireAuth: false,
    );
    final body = handleResponse(response) as Map<String, dynamic>;
    final List<dynamic> days = body['days'] ?? [];
    return days.map((e) => HotelCalendarDay.fromJson(e as Map<String, dynamic>)).toList();
  }
}
