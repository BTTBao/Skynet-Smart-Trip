import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Xin chào! Tôi là Sky - trợ lý du lịch thông minh của Skynet. Tôi có thể giúp gì cho bạn hôm nay?',
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    ),
  ];

  bool _isTyping = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Thêm tin nhắn của người dùng
    _messages.add(ChatMessage(
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    // Trạng thái Bot đang trả lời
    _isTyping = true;
    notifyListeners();

    // Gọi API thật từ Backend
    String botResponse = await _chatService.getBotResponse(text);

    _messages.add(ChatMessage(
      text: botResponse,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    ));

    _isTyping = false;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _messages.add(ChatMessage(
      text: 'Cuộc trò chuyện đã được làm mới. Sky có thể giúp gì thêm cho bạn?',
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
}
