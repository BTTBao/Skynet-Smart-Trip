import '../models/app_notification.dart';
import 'api_service_base.dart';

class NotificationService extends ApiService {
  Future<NotificationListResult> getNotifications() async {
    final response = await getWithFallback('/notifications', requireAuth: true);
    final data = Map<String, dynamic>.from(handleResponse(response));
    return NotificationListResult.fromJson(data);
  }

  Future<int> getUnreadCount() async {
    final response = await getWithFallback(
      '/notifications/unread-count',
      requireAuth: true,
    );
    final data = Map<String, dynamic>.from(handleResponse(response));
    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  }

  Future<AppNotification> markAsRead(int notificationId) async {
    final response = await postWithFallback(
      '/notifications/$notificationId/read',
      requireAuth: true,
    );
    final data = Map<String, dynamic>.from(handleResponse(response));
    return AppNotification.fromJson(data);
  }

  Future<void> markAllAsRead() async {
    final response = await postWithFallback(
      '/notifications/mark-all-read',
      requireAuth: true,
    );
    handleResponse(response);
  }
}
