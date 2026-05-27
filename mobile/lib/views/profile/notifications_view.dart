import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../../utils/app_text.dart';
import '../explore/explore_post_detail_view.dart';
import '../trip/trip_itinerary_detail_view.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  static const primaryColor = Color(0xFF80ED99);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              context.tr(vi: 'Thong bao', en: 'Notifications'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              if (provider.unreadCount > 0)
                TextButton(
                  onPressed: provider.markAllAsRead,
                  child: Text(context.tr(vi: 'Da doc het', en: 'Read all')),
                ),
            ],
          ),
          body: RefreshIndicator(
            color: primaryColor,
            onRefresh: () => provider.fetchNotifications(silent: true),
            child: _buildBody(provider),
          ),
        );
      },
    );
  }

  Widget _buildBody(NotificationProvider provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (provider.error != null && provider.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 160),
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(
            provider.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: () => provider.fetchNotifications(),
              child: Text(context.tr(vi: 'Thu lai', en: 'Retry')),
            ),
          ),
        ],
      );
    }

    if (provider.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 160),
          Icon(
            Icons.notifications_none_rounded,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr(
              vi: 'Chua co thong bao nao',
              en: 'No notifications yet',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(
              vi: 'Nhung cap nhat quan trong se xuat hien tai day.',
              en: 'Important updates will appear here.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: provider.notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final notification = provider.notifications[index];
        return _NotificationTile(
          notification: notification,
          onTap: () => _openNotification(notification),
        );
      },
    );
  }

  Future<void> _openNotification(AppNotification notification) async {
    final provider = context.read<NotificationProvider>();
    final updated = await provider.markAsRead(notification);
    if (!mounted || updated == null) {
      return;
    }

    final actionUrl = updated.actionUrl ?? '';
    final tripId = _extractId(actionUrl, '/trips/');
    if (tripId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TripItineraryDetailView(tripId: tripId),
        ),
      );
      return;
    }

    final postId = _extractId(actionUrl, '/explore/posts/') ??
        (updated.referenceType == 'explore_post' ? updated.referenceId : null);
    if (postId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ExplorePostDetailView(postId: postId),
        ),
      );
      return;
    }

    if ((updated.referenceType == 'trip' || updated.referenceType == 'booking') &&
        updated.referenceId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TripItineraryDetailView(tripId: updated.referenceId!),
        ),
      );
    }
  }

  int? _extractId(String value, String prefix) {
    final index = value.indexOf(prefix);
    if (index < 0) {
      return null;
    }

    final raw = value.substring(index + prefix.length).split('/').first;
    return int.tryParse(raw);
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final createdAt = notification.createdAt;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread
                ? const Color(0xFFEFFFF4)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnread ? const Color(0xFF80ED99) : Colors.grey.shade200,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isUnread
                      ? const Color(0xFF80ED99).withValues(alpha: 0.22)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconForType(notification.type),
                  size: 21,
                  color: isUnread ? const Color(0xFF15803D) : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isUnread ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Colors.grey.shade700,
                        fontWeight:
                            isUnread ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toLocal()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    if (type.startsWith('payment')) {
      return Icons.payments_outlined;
    }
    if (type.startsWith('booking')) {
      return Icons.hotel_outlined;
    }
    if (type.startsWith('trip')) {
      return Icons.map_outlined;
    }
    if (type.startsWith('explore')) {
      return Icons.mode_comment_outlined;
    }
    if (type.startsWith('account')) {
      return Icons.security_outlined;
    }
    return Icons.notifications_outlined;
  }
}
