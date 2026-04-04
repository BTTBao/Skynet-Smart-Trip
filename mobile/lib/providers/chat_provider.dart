import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/chat_response.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  List<QuickAction> _suggestions = [];
  bool _isInitialized = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  List<QuickAction> get suggestions => _suggestions;
  bool get isInitialized => _isInitialized;
  bool get hasMessages => _messages.isNotEmpty;

  /// Initialize with welcome message and load suggestions
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _messages.add(ChatMessage(
      text: 'Xin chào! 👋 Tôi là Sky — trợ lý du lịch thông minh của Skynet.\n\nTôi có thể giúp bạn khám phá điểm đến, lập lịch trình, tìm khách sạn và nhiều hơn nữa. Hãy hỏi tôi bất cứ điều gì!',
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    ));

    // Load default suggestions
    _suggestions = [
      QuickAction(label: '🏖 Gợi ý điểm đến', icon: 'explore', actionPayload: 'Gợi ý cho tôi 3 điểm đến đẹp ở Việt Nam'),
      QuickAction(label: '📋 Lập lịch trình', icon: 'calendar', actionPayload: 'Lập lịch trình du lịch Đà Lạt 3 ngày 2 đêm'),
      QuickAction(label: '🏨 Tìm khách sạn', icon: 'hotel', actionPayload: 'Tìm khách sạn tốt nhất ở Phú Quốc'),
      QuickAction(label: '☀️ Thời tiết', icon: 'weather', actionPayload: 'Thời tiết Đà Nẵng hôm nay thế nào?'),
    ];

    notifyListeners();

    // Try to load suggestions from backend
    try {
      final serverSuggestions = await _chatService.getSuggestions();
      if (serverSuggestions.isNotEmpty) {
        _suggestions = serverSuggestions;
        notifyListeners();
      }
    } catch (_) {
      // Use defaults
    }
  }

  /// Send a message and get structured AI response
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    _messages.add(ChatMessage(
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    // Show typing indicator
    _isTyping = true;
    notifyListeners();

    // Get AI response
    ChatResponse botResponse = await _chatService.sendMessage(text);

    // Create message from structured response
    _messages.add(ChatMessage.fromResponse(botResponse));

    // Update suggestions from response
    if (botResponse.quickActions != null && botResponse.quickActions!.isNotEmpty) {
      _suggestions = botResponse.quickActions!;
    }

    _isTyping = false;
    notifyListeners();
  }

  /// Handle quick action tap
  void onQuickActionTap(QuickAction action) {
    sendMessage(action.actionPayload);
  }

  /// Clear chat and reset
  void clearChat() {
    _messages.clear();
    _isInitialized = false;
    initialize();
  }
}
