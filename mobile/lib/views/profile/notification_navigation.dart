import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../explore/explore_post_detail_view.dart';
import '../trip/trip_itinerary_detail_view.dart';

class NotificationNavigation {
  const NotificationNavigation._();

  static Future<bool> open(
    BuildContext context,
    AppNotification notification, {
    bool markAsRead = true,
  }) async {
    var target = notification;

    if (markAsRead && notification.id > 0) {
      final updated = await context.read<NotificationProvider>().markAsRead(
        notification,
      );
      if (!context.mounted || updated == null) {
        return false;
      }
      target = updated;
    }

    final actionUrl = target.actionUrl ?? '';
    final tripId = _extractId(actionUrl, '/trips/');
    if (tripId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TripItineraryDetailView(tripId: tripId),
        ),
      );
      return true;
    }

    final postId =
        _extractId(actionUrl, '/explore/posts/') ??
        (target.referenceType == 'explore_post' ? target.referenceId : null);
    if (postId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ExplorePostDetailView(postId: postId),
        ),
      );
      return true;
    }

    if ((target.referenceType == 'trip' || target.referenceType == 'booking') &&
        target.referenceId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TripItineraryDetailView(tripId: target.referenceId!),
        ),
      );
      return true;
    }

    return false;
  }

  static AppNotification fromFcmData(Map<String, dynamic> data) {
    final referenceId = int.tryParse(
      (data['relatedEntityId'] ?? data['referenceId'] ?? '').toString(),
    );

    return AppNotification(
      id: int.tryParse((data['notificationId'] ?? '').toString()) ?? 0,
      title: (data['title'] ?? '').toString(),
      message: (data['body'] ?? data['message'] ?? '').toString(),
      type: (data['type'] ?? 'general').toString(),
      referenceType: (data['relatedEntityType'] ?? data['referenceType'])
          ?.toString(),
      referenceId: referenceId,
      actionUrl: data['actionUrl']?.toString(),
      isRead: false,
      createdAt: DateTime.now(),
    );
  }

  static int? _extractId(String value, String prefix) {
    final index = value.indexOf(prefix);
    if (index < 0) {
      return null;
    }

    final raw = value.substring(index + prefix.length).split('/').first;
    return int.tryParse(raw);
  }
}
