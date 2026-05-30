import 'chat_response.dart';

class ChatHistoryResult {
  final String? sessionId;
  final List<ChatHistoryItem> messages;

  const ChatHistoryResult({
    required this.sessionId,
    required this.messages,
  });

  factory ChatHistoryResult.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];

    return ChatHistoryResult(
      sessionId: json['sessionId']?.toString(),
      messages: rawMessages is List
          ? rawMessages
              .whereType<Map<String, dynamic>>()
              .map(ChatHistoryItem.fromJson)
              .toList()
          : const [],
    );
  }
}

class ChatHistoryItem {
  final String role;
  final String content;
  final String? sessionId;
  final String? responseType;
  final DateTime timestamp;
  final ChatResponse? responsePayload;

  const ChatHistoryItem({
    required this.role,
    required this.content,
    required this.timestamp,
    this.sessionId,
    this.responseType,
    this.responsePayload,
  });

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) {
    final responsePayload = json['responsePayload'];

    return ChatHistoryItem(
      role: json['role']?.toString() ?? 'bot',
      content: json['content']?.toString() ?? '',
      sessionId: json['sessionId']?.toString(),
      responseType: json['responseType']?.toString(),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      responsePayload: responsePayload is Map<String, dynamic>
          ? ChatResponse.fromJson(responsePayload)
          : null,
    );
  }
}
