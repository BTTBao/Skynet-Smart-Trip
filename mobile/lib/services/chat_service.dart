import 'dart:convert';
import 'api_service_base.dart';
import '../models/chat_response.dart';

class ChatService extends ApiService {
  /// Send message and get structured AI response
  Future<ChatResponse> sendMessage(String userMessage, {int? userId, String? sessionId}) async {
    try {
      final response = await postWithFallback(
        '/Chat/send',
        body: jsonEncode({
          'message': userMessage,
          if (userId case final id?) 'userId': id,
          if (sessionId case final sid?) 'sessionId': sid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatResponse.fromJson(data);
      } else {
        return ChatResponse(
          text: "Sky đang gặp chút lỗi kết nối (Status: ${response.statusCode}). Bạn thử lại sau nhé! 😅",
          responseType: 'text',
          quickActions: _getDefaultQuickActions(),
        );
      }
    } catch (e) {
      return ChatResponse(
        text: "Không thể kết nối tới máy chủ. Hãy kiểm tra kết nối mạng và thử lại nhé! 🔌",
        responseType: 'text',
        quickActions: _getDefaultQuickActions(),
      );
    }
  }

  /// Get quick suggestions
  Future<List<QuickAction>> getSuggestions() async {
    try {
      final response = await getWithFallback('/Chat/suggestions');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((e) => QuickAction.fromJson(e)).toList();
      }
    } catch (_) {}

    return _getDefaultQuickActions();
  }

  List<QuickAction> _getDefaultQuickActions() {
    return [
      QuickAction(label: '🏖 Gợi ý điểm đến', icon: 'explore', actionPayload: 'Gợi ý cho tôi 3 điểm đến đẹp ở Việt Nam'),
      QuickAction(label: '📋 Lập lịch trình', icon: 'calendar', actionPayload: 'Lập lịch trình du lịch Đà Lạt 3 ngày 2 đêm'),
      QuickAction(label: '🏨 Tìm khách sạn', icon: 'hotel', actionPayload: 'Tìm khách sạn tốt nhất ở Phú Quốc'),
      QuickAction(label: '☀️ Xem thời tiết', icon: 'weather', actionPayload: 'Thời tiết Đà Nẵng hôm nay thế nào?'),
    ];
  }
}
