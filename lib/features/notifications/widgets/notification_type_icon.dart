import 'package:flutter/material.dart';

import '../models/notification_model.dart';

class NotificationTypeIcon extends StatelessWidget {
  const NotificationTypeIcon({required this.type, super.key});

  final AppNotificationType type;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      AppNotificationType.paymentDueReminder ||
      AppNotificationType.paymentOverdue ||
      AppNotificationType.paymentMarkedPaid ||
      AppNotificationType.paymentRejected ||
      AppNotificationType.paymentApproved =>
        Icons.payments_outlined,
      AppNotificationType.payoutPending ||
      AppNotificationType.payoutPaid =>
        Icons.outbound_outlined,
      AppNotificationType.receiverPending ||
      AppNotificationType.receiverConfirmed =>
        Icons.person_pin_circle_outlined,
      AppNotificationType.luckyDrawPending ||
      AppNotificationType.luckyDrawCompleted =>
        Icons.casino_outlined,
      AppNotificationType.biddingStarted ||
      AppNotificationType.biddingClosingSoon ||
      AppNotificationType.biddingClosed ||
      AppNotificationType.biddingCompleted =>
        Icons.gavel_outlined,
      AppNotificationType.reportGenerated => Icons.description_outlined,
      AppNotificationType.ledgerWarning => Icons.warning_amber_outlined,
      AppNotificationType.memberAdded => Icons.person_add_alt_outlined,
      AppNotificationType.kametiStarted => Icons.play_circle_outline,
      _ => Icons.notifications_outlined,
    };
    return CircleAvatar(
      backgroundColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary),
    );
  }
}
