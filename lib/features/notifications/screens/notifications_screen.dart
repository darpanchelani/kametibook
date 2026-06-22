import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/providers/auth_controller.dart';
import '../../bidding/providers/bidding_controller.dart';
import '../../kameti/models/kameti_model.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../../member/providers/member_controller.dart';
import '../../payment/providers/payment_controller.dart';
import '../../receiver/providers/receiver_controller.dart';
import '../models/notification_model.dart';
import '../providers/notification_controller.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_filter_chips.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationFilter _filter = NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authControllerProvider).user?.id ?? '';
    ref.watch(notificationControllerProvider);
    ref.watch(kametiControllerProvider);
    ref.watch(paymentControllerProvider);
    ref.watch(receiverControllerProvider);
    ref.watch(biddingControllerProvider);
    _refreshChecks(userId);

    final controller = ref.read(notificationControllerProvider.notifier);
    final notifications = controller.getNotificationsForUser(userId).where(_matchesFilter).toList();
    final unreadCount = controller.getUnreadCount(userId);
    final kametis = ref.read(kametiControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Preferences',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.notificationPreferences),
            icon: const Icon(Icons.tune_outlined),
          ),
          TextButton(
            onPressed: unreadCount == 0 ? null : () => controller.markAllNotificationsRead(userId),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Text('$unreadCount unread', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: NotificationFilterChips(selected: _filter, onChanged: (value) => setState(() => _filter = value)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: notifications.isEmpty
                  ? const EmptyState(icon: Icons.notifications_none_outlined, title: 'No notifications yet.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return NotificationCard(
                          notification: notification,
                          kametiName: _kametiName(kametis, notification.kametiId),
                          onTap: () => _openNotification(notification),
                          onMarkRead: () => controller.markNotificationRead(notification.id),
                          onDismiss: () => controller.dismissNotification(notification.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshChecks(String userId) {
    final notificationController = ref.read(notificationControllerProvider.notifier);
    notificationController.processDueScheduledNotifications();
    notificationController.checkOverduePayments(
      userId: userId,
      kametis: ref.read(kametiControllerProvider),
      cycles: ref.read(paymentControllerProvider).cycles,
      payments: ref.read(paymentControllerProvider).payments,
      members: ref.read(memberControllerProvider),
    );
    notificationController.checkPendingPayoutProofs(
      userId: userId,
      kametis: ref.read(kametiControllerProvider),
      allocations: ref.read(receiverControllerProvider).allocations,
    );
    notificationController.checkPendingReceivers(
      userId: userId,
      kametis: ref.read(kametiControllerProvider),
      cycles: ref.read(paymentControllerProvider).cycles,
      allocations: ref.read(receiverControllerProvider).allocations,
    );
    notificationController.checkPendingBiddings(
      userId: userId,
      kametis: ref.read(kametiControllerProvider),
      cycles: ref.read(paymentControllerProvider).cycles,
      sessions: ref.read(biddingControllerProvider).sessions,
    );
  }

  bool _matchesFilter(NotificationModel notification) {
    return switch (_filter) {
      NotificationFilter.all => true,
      NotificationFilter.unread => notification.isUnread,
      NotificationFilter.payments => {
          AppNotificationType.paymentDueReminder,
          AppNotificationType.paymentOverdue,
          AppNotificationType.paymentMarkedPaid,
          AppNotificationType.paymentRejected,
          AppNotificationType.paymentApproved,
        }.contains(notification.notificationType),
      NotificationFilter.payouts => {
          AppNotificationType.payoutPending,
          AppNotificationType.payoutPaid,
        }.contains(notification.notificationType),
      NotificationFilter.bidding => notification.notificationType.name.startsWith('bidding'),
      NotificationFilter.draws => notification.notificationType.name.startsWith('luckyDraw'),
      NotificationFilter.reports => notification.notificationType == AppNotificationType.reportGenerated,
      NotificationFilter.warnings => notification.priority == NotificationPriority.urgent || notification.notificationType == AppNotificationType.ledgerWarning,
      NotificationFilter.receiver => notification.notificationType == AppNotificationType.receiverPending || notification.notificationType == AppNotificationType.receiverConfirmed,
    };
  }

  void _openNotification(NotificationModel notification) {
    ref.read(notificationControllerProvider.notifier).markNotificationRead(notification.id);
    if (notification.actionRoute.isEmpty || notification.actionType == NotificationActionType.none) return;
    final argument = switch (notification.actionType) {
      NotificationActionType.openCycle || NotificationActionType.openPayment => notification.cycleId,
      NotificationActionType.openBidding || NotificationActionType.openLuckyDraw || NotificationActionType.openLedger || NotificationActionType.openKameti || NotificationActionType.openPayout => notification.kametiId,
      NotificationActionType.openReport => notification.kametiId,
      NotificationActionType.none => null,
    };
    if (argument == null || argument.isEmpty) return;
    Navigator.of(context).pushNamed(notification.actionRoute, arguments: argument);
  }

  String _kametiName(List<KametiModel> kametis, String id) {
    for (final kameti in kametis) {
      if (kameti.id == id) return kameti.name;
    }
    return '';
  }
}
