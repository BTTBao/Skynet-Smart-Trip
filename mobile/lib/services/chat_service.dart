import 'dart:convert';

import '../models/chat_history_result.dart';
import '../models/chat_response.dart';
import '../models/chat_session_summary.dart';
import 'api_service_base.dart';

class ChatService extends ApiService {
  Future<ChatResponse> sendMessage(
    String userMessage, {
    String? sessionId,
  }) async {
    final response = await postWithFallback(
      '/Chat/send',
      requireAuth: true,
      body: jsonEncode({
        'message': userMessage,
        if (sessionId case final sid?) 'sessionId': sid,
      }),
    );

    final data = handleResponse(response);
    return ChatResponse.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ChatHistoryResult> getHistory({
    String? sessionId,
    int limit = 50,
  }) async {
    final query = StringBuffer('/Chat/history?limit=$limit');
    if (sessionId != null && sessionId.trim().isNotEmpty) {
      query.write('&sessionId=${Uri.encodeQueryComponent(sessionId.trim())}');
    }

    final response = await getWithFallback(
      query.toString(),
      requireAuth: true,
    );

    final data = handleResponse(response);
    return ChatHistoryResult.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<ChatSessionSummary>> getSessions({int limit = 20}) async {
    final response = await getWithFallback(
      '/Chat/sessions?limit=$limit',
      requireAuth: true,
    );

    final data = handleResponse(response);
    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(ChatSessionSummary.fromJson)
        .where((session) => session.sessionId.isNotEmpty)
        .toList();
  }

  Future<void> clearHistory({String? sessionId}) async {
    final query = StringBuffer('/Chat/history');
    if (sessionId != null && sessionId.trim().isNotEmpty) {
      query.write('?sessionId=${Uri.encodeQueryComponent(sessionId.trim())}');
    }

    final response = await deleteWithFallback(
      query.toString(),
      requireAuth: true,
    );

    handleResponse(response);
  }

  Future<List<QuickAction>> getSuggestions() async {
    try {
      final response = await getWithFallback('/Chat/suggestions');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data
            .whereType<Map<String, dynamic>>()
            .map(QuickAction.fromJson)
            .toList();
      }
    } catch (_) {}

    return _getDefaultQuickActions();
  }

  List<QuickAction> _getDefaultQuickActions() {
    return const [
      QuickAction(
        label: 'Gợi ý điểm đến',
        icon: 'explore',
        actionPayload: 'Gợi ý cho tôi 3 điểm đến đẹp ở Việt Nam',
      ),
      QuickAction(
        label: 'Lập lịch trình',
        icon: 'calendar',
        actionPayload: 'Lập lịch trình du lịch Đà Lạt 3 ngày 2 đêm',
      ),
      QuickAction(
        label: 'Tìm khách sạn',
        icon: 'hotel',
        actionPayload: 'Tìm khách sạn tốt ở Phú Quốc',
      ),
      QuickAction(
        label: 'Xem thời tiết',
        icon: 'weather',
        actionPayload: 'Thời tiết Đà Nẵng hôm nay thế nào?',
      ),
    ];
  }
}



