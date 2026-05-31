class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.referenceType,
    this.referenceId,
    this.actionUrl,
    this.createdAt,
  });

  final int id;
  final String title;
  final String message;
  final String type;
  final String? referenceType;
  final int? referenceId;
  final String? actionUrl;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      referenceType: referenceType,
      referenceId: referenceId,
      actionUrl: actionUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      type: (json['type'] ?? 'general').toString(),
      referenceType: json['referenceType']?.toString(),
      referenceId: (json['referenceId'] as num?)?.toInt(),
      actionUrl: json['actionUrl']?.toString(),
      isRead: json['isRead'] == true,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

class NotificationListResult {
  const NotificationListResult({
    required this.items,
    required this.unreadCount,
  });

  final List<AppNotification> items;
  final int unreadCount;

  factory NotificationListResult.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((item) => AppNotification.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return NotificationListResult(
      items: items,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ??
          items.where((item) => !item.isRead).length,
    );
  }
}
