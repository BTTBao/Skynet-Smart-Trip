class ChatSessionSummary {
  final String sessionId;
  final String previewText;
  final DateTime lastUpdatedAt;
  final int messageCount;

  const ChatSessionSummary({
    required this.sessionId,
    required this.previewText,
    required this.lastUpdatedAt,
    required this.messageCount,
  });

  factory ChatSessionSummary.fromJson(Map<String, dynamic> json) {
    return ChatSessionSummary(
      sessionId: json['sessionId']?.toString() ?? '',
      previewText: json['previewText']?.toString() ?? '',
      lastUpdatedAt:
          DateTime.tryParse(json['lastUpdatedAt']?.toString() ?? '') ??
              DateTime.now(),
      messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
    );
  }
}
