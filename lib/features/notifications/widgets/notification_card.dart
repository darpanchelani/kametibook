import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../models/notification_model.dart';
import 'notification_priority_badge.dart';
import 'notification_type_icon.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    required this.notification,
    required this.kametiName,
    required this.onTap,
    required this.onMarkRead,
    required this.onDismiss,
    super.key,
  });

  final NotificationModel notification;
  final String kametiName;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.isUnread
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NotificationTypeIcon(type: notification.notificationType),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notification.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                        if (notification.isUnread)
                          Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                  color: Colors.teal, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notification.message),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        NotificationPriorityBadge(
                            priority: notification.priority),
                        Text(kametiName.isEmpty ? 'General' : kametiName,
                            style: const TextStyle(color: Colors.black54)),
                        Text(
                            DateFormatter.display(notification.triggeredAt ??
                                notification.createdAt),
                            style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                            onPressed:
                                notification.isUnread ? onMarkRead : null,
                            child: const Text('Mark read')),
                        TextButton(
                            onPressed: onDismiss, child: const Text('Dismiss')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
