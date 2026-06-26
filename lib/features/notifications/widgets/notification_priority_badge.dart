import 'package:flutter/material.dart';

import '../models/notification_model.dart';

class NotificationPriorityBadge extends StatelessWidget {
  const NotificationPriorityBadge({required this.priority, super.key});

  final NotificationPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      NotificationPriority.low => Colors.blueGrey,
      NotificationPriority.normal => Colors.teal,
      NotificationPriority.high => Colors.orange,
      NotificationPriority.urgent => Colors.red,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999)),
      child: Text(priority.label,
          style: TextStyle(
              color: color.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w800)),
    );
  }
}
