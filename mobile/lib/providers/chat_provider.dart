import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatProvider with ChangeNotifier {
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

    // Giả lập trạng thái Bot đang trả lời
    _isTyping = true;
    notifyListeners();

    // Giả lập delay từ AI
    await Future.delayed(const Duration(seconds: 2));

    // Phản hồi giả lập (Sẽ thay bằng API thật sau)
    String botResponse = _getMockResponse(text);

    _messages.add(ChatMessage(
      text: botResponse,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    ));

    _isTyping = false;
    notifyListeners();
  }

  String _getMockResponse(String userText) {
    userText = userText.toLowerCase();
    if (userText.contains('đà lạt')) {
      return 'Đà Lạt mùa này rất đẹp! Bạn nên ghé thăm Thung lũng Tình yêu và thưởng thức lẩu gà lá é nhé.';
    } else if (userText.contains('thời tiết')) {
      return 'Hiện tại thời tiết ở các điểm du lịch chính đang khá thuận lợi. Bạn muốn kiểm tra cụ thể ở đâu?';
    } else if (userText.contains('khách sạn')) {
      return 'Tôi có thể giúp bạn tìm khách sạn phù hợp. Bạn dự định đi vào ngày nào và ngân sách khoảng bao nhiêu?';
    } else {
      return 'Cảm ơn bạn! Tôi đang xử lý thông tin. Bạn có muốn biết thêm về các tour du lịch hot nhất hiện nay không?';
    }
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
