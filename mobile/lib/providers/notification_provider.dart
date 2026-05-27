import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/api_service_base.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<AppNotification> _notifications = const [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isRefreshingCount = false;
  String? _error;
  int? _lastStatusCode;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isRefreshingCount => _isRefreshingCount;
  String? get error => _error;
  bool get hasSessionExpired => _lastStatusCode == 401;

  Future<void> fetchNotifications({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _clearError();
      notifyListeners();
    }

    try {
      final result = await _notificationService.getNotifications();
      _notifications = result.items;
      _unreadCount = result.unreadCount;
      _clearError();
    } catch (error) {
      _setError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    if (_isRefreshingCount) {
      return;
    }

    _isRefreshingCount = true;
    _clearError();
    notifyListeners();

    try {
      _unreadCount = await _notificationService.getUnreadCount();
    } catch (error) {
      _setError(error);
    } finally {
      _isRefreshingCount = false;
      notifyListeners();
    }
  }

  Future<AppNotification?> markAsRead(AppNotification notification) async {
    if (notification.isRead) {
      return notification;
    }

    try {
      final updated = await _notificationService.markAsRead(notification.id);
      _notifications = _notifications
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      _unreadCount = _notifications.where((item) => !item.isRead).length;
      _clearError();
      notifyListeners();
      return updated;
    } catch (error) {
      _setError(error);
      notifyListeners();
      return null;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      _notifications =
          _notifications.map((item) => item.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      _clearError();
      notifyListeners();
    } catch (error) {
      _setError(error);
      notifyListeners();
    }
  }

  void reset() {
    _notifications = const [];
    _unreadCount = 0;
    _isLoading = false;
    _isRefreshingCount = false;
    _clearError();
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    _lastStatusCode = null;
  }

  void _setError(Object error) {
    if (error is ApiException) {
      _lastStatusCode = error.statusCode;
      _error = error.isUnauthorized
          ? 'Phien dang nhap da het han. Vui long dang nhap lai.'
          : error.message;
      return;
    }

    _lastStatusCode = null;
    _error = error.toString().replaceFirst('Exception: ', '');
  }
}
