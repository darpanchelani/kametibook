import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_controller.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../models/notification_model.dart';
import '../providers/notification_controller.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_filter_chips.dart';

class KametiAlertsScreen extends ConsumerStatefulWidget {
  const KametiAlertsScreen({required this.kametiId, super.key});

  final String kametiId;

  @override
  ConsumerState<KametiAlertsScreen> createState() => _KametiAlertsScreenState();
}

class _KametiAlertsScreenState extends ConsumerState<KametiAlertsScreen> {
  NotificationFilter _filter = NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authControllerProvider).user?.id ?? 'mock-user';
    ref.watch(notificationControllerProvider);
    final controller = ref.read(notificationControllerProvider.notifier);
    final kameti = ref.read(kametiControllerProvider.notifier).byId(widget.kametiId);
    final alerts = controller.getNotificationsByKametiId(userId, widget.kametiId).where(_matchesFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kameti Alerts'),
        actions: [
          TextButton(
            onPressed: () => controller.markAllNotificationsRead(userId, kametiId: widget.kametiId),
            child: const Text('Mark read'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: NotificationFilterChips(selected: _filter, onChanged: (value) => setState(() => _filter = value)),
            ),
            Expanded(
              child: alerts.isEmpty
                  ? const Center(child: Text('No alerts for this kameti.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: alerts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return NotificationCard(
                          notification: alert,
                          kametiName: kameti?.name ?? '',
                          onTap: () => controller.markNotificationRead(alert.id),
                          onMarkRead: () => controller.markNotificationRead(alert.id),
                          onDismiss: () => controller.dismissNotification(alert.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesFilter(NotificationModel notification) {
    return switch (_filter) {
      NotificationFilter.all => true,
      NotificationFilter.unread => notification.isUnread,
      NotificationFilter.payments => notification.notificationType.name.startsWith('payment'),
      NotificationFilter.payouts => notification.notificationType.name.startsWith('payout'),
      NotificationFilter.bidding => notification.notificationType.name.startsWith('bidding'),
      NotificationFilter.draws => notification.notificationType.name.startsWith('luckyDraw'),
      NotificationFilter.reports => notification.notificationType == AppNotificationType.reportGenerated,
      NotificationFilter.warnings => notification.notificationType == AppNotificationType.ledgerWarning || notification.priority == NotificationPriority.urgent,
      NotificationFilter.receiver => notification.notificationType.name.startsWith('receiver'),
    };
  }
}
