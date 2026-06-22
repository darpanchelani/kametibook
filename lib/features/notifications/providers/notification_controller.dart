import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../bidding/models/bidding_models.dart';
import '../../kameti/models/kameti_model.dart';
import '../../member/models/member_model.dart';
import '../../payment/models/payment_models.dart';
import '../../receiver/models/receiver_allocation_model.dart';
import '../models/notification_model.dart';

class NotificationController extends StateNotifier<List<NotificationModel>> {
  NotificationController() : super(const []);

  final Map<String, UserNotificationPreferencesModel> _preferences = {};

  UserNotificationPreferencesModel preferencesFor(String userId) {
    return _preferences[userId] ?? UserNotificationPreferencesModel(userId: userId);
  }

  void updatePreferences(UserNotificationPreferencesModel preferences) {
    _preferences[preferences.userId] = preferences;
  }

  List<NotificationModel> getNotificationsForUser(String userId) {
    final items = state
        .where((item) => item.userId == userId && item.status != NotificationStatus.dismissed && item.status != NotificationStatus.scheduled)
        .toList();
    items.sort((a, b) => (b.triggeredAt ?? b.createdAt).compareTo(a.triggeredAt ?? a.createdAt));
    return items;
  }

  List<NotificationModel> getNotificationsByKametiId(String userId, String kametiId) {
    return getNotificationsForUser(userId).where((item) => item.kametiId == kametiId).toList();
  }

  int getUnreadCount(String userId) => getNotificationsForUser(userId).where((item) => item.isUnread).length;

  int getUrgentCount(String userId) {
    return getNotificationsForUser(userId).where((item) => item.isUnread && item.priority == NotificationPriority.urgent).length;
  }

  void createNotification(NotificationModel notification) {
    if (!_isAllowedByPreferences(notification)) return;
    if (_hasDuplicate(notification)) return;
    state = [notification, ...state];
  }

  void markNotificationRead(String notificationId) {
    final now = DateTime.now();
    state = [
      for (final item in state)
        if (item.id == notificationId) item.copyWith(status: NotificationStatus.read, readAt: now, updatedAt: now) else item,
    ];
  }

  void markAllNotificationsRead(String userId, {String? kametiId}) {
    final now = DateTime.now();
    state = [
      for (final item in state)
        if (item.userId == userId && (kametiId == null || item.kametiId == kametiId) && item.status != NotificationStatus.dismissed)
          item.copyWith(status: NotificationStatus.read, readAt: now, updatedAt: now)
        else
          item,
    ];
  }

  void dismissNotification(String notificationId) {
    final now = DateTime.now();
    state = [
      for (final item in state)
        if (item.id == notificationId) item.copyWith(status: NotificationStatus.dismissed, updatedAt: now) else item,
    ];
  }

  void processDueScheduledNotifications() {
    final now = DateTime.now();
    state = [
      for (final item in state)
        if (item.status == NotificationStatus.scheduled && item.scheduledAt != null && !item.scheduledAt!.isAfter(now))
          item.copyWith(status: NotificationStatus.unread, triggeredAt: now, updatedAt: now)
        else
          item,
    ];
  }

  void generateScheduledRemindersForKameti({
    required String userId,
    required KametiModel kameti,
    required List<PaymentCycleModel> cycles,
    required List<MemberPaymentModel> payments,
    required List<MemberModel> members,
  }) {
    if (!kameti.remindersEnabled || kameti.status != KametiStatus.active) return;
    for (final cycle in cycles.where((cycle) => cycle.kametiId == kameti.id)) {
      final cyclePayments = payments.where((payment) => payment.cycleId == cycle.id && !_isPaid(payment)).toList();
      if (cyclePayments.isEmpty) continue;
      final beforeDate = cycle.dueDate.subtract(Duration(days: kameti.paymentReminderDaysBefore));
      for (final payment in cyclePayments) {
        final member = _memberById(members, payment.memberId);
        _createPaymentDueReminder(userId, kameti, cycle, payment, member, beforeDate);
        if (kameti.paymentReminderOnDueDate) _createPaymentDueReminder(userId, kameti, cycle, payment, member, cycle.dueDate);
      }
    }
  }

  void checkOverduePayments({
    required String userId,
    required List<KametiModel> kametis,
    required List<PaymentCycleModel> cycles,
    required List<MemberPaymentModel> payments,
    required List<MemberModel> members,
  }) {
    final now = DateTime.now();
    for (final payment in payments.where((payment) => !_isPaid(payment))) {
      final cycle = _cycleById(cycles, payment.cycleId);
      if (cycle == null || cycle.dueDate.isAfter(now)) continue;
      final kameti = _kametiById(kametis, payment.kametiId);
      if (kameti == null || !kameti.overdueReminderEnabled) continue;
      final member = _memberById(members, payment.memberId);
      createNotification(
        buildNotification(
          userId: userId,
          kametiId: kameti.id,
          cycleId: cycle.id,
          memberId: payment.memberId,
          relatedPaymentId: payment.id,
          type: AppNotificationType.paymentOverdue,
          title: 'Payment Overdue',
          message: '${member?.fullName ?? 'Member'} payment is overdue for ${kameti.name} Cycle ${cycle.cycleNumber}.',
          priority: NotificationPriority.urgent,
          actionType: NotificationActionType.openPayment,
          actionRoute: AppRoutes.cyclePayments,
        ),
      );
    }
  }

  void checkPendingPayoutProofs({
    required String userId,
    required List<KametiModel> kametis,
    required List<ReceiverAllocationModel> allocations,
  }) {
    for (final allocation in allocations.where((item) => item.payoutStatus != PayoutStatus.confirmed || item.payoutProofPath.isEmpty)) {
      final kameti = _kametiById(kametis, allocation.kametiId);
      if (kameti == null || !kameti.payoutProofReminderEnabled) continue;
      createNotification(
        buildNotification(
          userId: userId,
          kametiId: allocation.kametiId,
          cycleId: allocation.cycleId,
          memberId: allocation.memberId,
          relatedAllocationId: allocation.id,
          type: AppNotificationType.payoutPending,
          title: 'Payout Proof Pending',
          message: 'Payout proof is pending for ${allocation.memberName} in Cycle ${allocation.cycleNumber}.',
          priority: NotificationPriority.high,
          actionType: NotificationActionType.openPayout,
          actionRoute: AppRoutes.kametiDetails,
        ),
      );
    }
  }

  void checkPendingReceivers({
    required String userId,
    required List<KametiModel> kametis,
    required List<PaymentCycleModel> cycles,
    required List<ReceiverAllocationModel> allocations,
  }) {
    for (final kameti in kametis.where((item) => item.status == KametiStatus.active && item.receiverPendingReminderEnabled)) {
      final cycle = cycles.where((item) => item.kametiId == kameti.id && item.status == PaymentCycleStatus.current).firstOrNull;
      if (cycle == null) continue;
      final hasAllocation = allocations.any((item) => item.cycleId == cycle.id && item.status == ReceiverAllocationStatus.confirmed);
      if (hasAllocation) continue;
      createNotification(
        buildNotification(
          userId: userId,
          kametiId: kameti.id,
          cycleId: cycle.id,
          type: AppNotificationType.receiverPending,
          title: 'Receiver Pending',
          message: 'Receiver is not selected for ${kameti.name} Cycle ${cycle.cycleNumber}.',
          priority: NotificationPriority.high,
          actionType: NotificationActionType.openKameti,
          actionRoute: AppRoutes.kametiDetails,
        ),
      );
      if (kameti.type == KametiType.luckyDraw && kameti.luckyDrawReminderEnabled) {
        createNotification(
          buildNotification(
            userId: userId,
            kametiId: kameti.id,
            cycleId: cycle.id,
            type: AppNotificationType.luckyDrawPending,
            title: 'Lucky Draw Pending',
            message: 'Lucky draw is pending for ${kameti.name} Cycle ${cycle.cycleNumber}.',
            priority: NotificationPriority.high,
            actionType: NotificationActionType.openLuckyDraw,
            actionRoute: AppRoutes.luckyDraw,
          ),
        );
      }
    }
  }

  void checkPendingBiddings({
    required String userId,
    required List<KametiModel> kametis,
    required List<PaymentCycleModel> cycles,
    required List<BiddingSessionModel> sessions,
  }) {
    for (final kameti in kametis.where((item) => item.status == KametiStatus.active && item.type == KametiType.bidding && item.biddingReminderEnabled)) {
      final cycle = cycles.where((item) => item.kametiId == kameti.id && item.status == PaymentCycleStatus.current).firstOrNull;
      if (cycle == null) continue;
      final session = sessions.where((item) => item.cycleId == cycle.id).firstOrNull;
      if (session == null) {
        createNotification(
          buildNotification(
            userId: userId,
            kametiId: kameti.id,
            cycleId: cycle.id,
            type: AppNotificationType.biddingClosingSoon,
            title: 'Bidding Pending',
            message: 'Bidding is not started for ${kameti.name} Cycle ${cycle.cycleNumber}.',
            priority: NotificationPriority.normal,
            actionType: NotificationActionType.openBidding,
            actionRoute: AppRoutes.bidding,
          ),
        );
      } else if (session.status == BiddingSessionStatus.closed) {
        createNotification(
          buildNotification(
            userId: userId,
            kametiId: kameti.id,
            cycleId: cycle.id,
            relatedBiddingSessionId: session.id,
            type: AppNotificationType.biddingClosed,
            title: 'Bidding Closed',
            message: 'Bidding is closed. Please complete the result.',
            priority: NotificationPriority.high,
            actionType: NotificationActionType.openBidding,
            actionRoute: AppRoutes.bidding,
          ),
        );
      }
    }
  }

  NotificationModel buildNotification({
    required String userId,
    required String kametiId,
    required AppNotificationType type,
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.normal,
    NotificationActionType actionType = NotificationActionType.none,
    String actionRoute = '',
    String cycleId = '',
    String memberId = '',
    String relatedPaymentId = '',
    String relatedAllocationId = '',
    String relatedBiddingSessionId = '',
    String relatedDrawId = '',
    String relatedReportId = '',
    DateTime? scheduledAt,
  }) {
    final now = DateTime.now();
    final status = scheduledAt != null && scheduledAt.isAfter(now) ? NotificationStatus.scheduled : NotificationStatus.unread;
    return NotificationModel(
      id: 'notification-${type.name}-$kametiId-$cycleId-$memberId-$relatedPaymentId-$relatedAllocationId-$relatedBiddingSessionId-$relatedDrawId-$relatedReportId-${_dateKey(scheduledAt ?? now)}',
      userId: userId,
      kametiId: kametiId,
      cycleId: cycleId,
      memberId: memberId,
      relatedPaymentId: relatedPaymentId,
      relatedAllocationId: relatedAllocationId,
      relatedBiddingSessionId: relatedBiddingSessionId,
      relatedDrawId: relatedDrawId,
      relatedReportId: relatedReportId,
      notificationType: type,
      title: title,
      message: message,
      priority: priority,
      status: status,
      actionType: actionType,
      actionRoute: actionRoute,
      scheduledAt: scheduledAt,
      triggeredAt: status == NotificationStatus.unread ? now : null,
      readAt: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  void createKametiStartedNotification({required String userId, required KametiModel kameti}) {
    createNotification(buildNotification(
      userId: userId,
      kametiId: kameti.id,
      type: AppNotificationType.kametiStarted,
      title: 'Kameti Started',
      message: '${kameti.name} has started successfully.',
      actionType: NotificationActionType.openKameti,
      actionRoute: AppRoutes.kametiDetails,
    ));
  }

  void createMemberAddedNotification({required String userId, required KametiModel kameti, required MemberModel member}) {
    createNotification(buildNotification(
      userId: userId,
      kametiId: kameti.id,
      memberId: member.id,
      type: AppNotificationType.memberAdded,
      title: 'Member Added',
      message: '${member.fullName} has been added to ${kameti.name}.',
      actionType: NotificationActionType.openKameti,
      actionRoute: AppRoutes.members,
    ));
  }

  bool _hasDuplicate(NotificationModel notification) => state.any((item) => item.id == notification.id);

  bool _isAllowedByPreferences(NotificationModel notification) {
    final preferences = preferencesFor(notification.userId);
    if (!preferences.inAppEnabled) return false;
    return switch (notification.notificationType) {
      AppNotificationType.paymentDueReminder ||
      AppNotificationType.paymentOverdue ||
      AppNotificationType.paymentMarkedPaid ||
      AppNotificationType.paymentRejected ||
      AppNotificationType.paymentApproved => preferences.paymentNotifications,
      AppNotificationType.payoutPending || AppNotificationType.payoutPaid => preferences.payoutNotifications,
      AppNotificationType.receiverPending || AppNotificationType.receiverConfirmed => preferences.receiverNotifications,
      AppNotificationType.biddingStarted ||
      AppNotificationType.biddingClosingSoon ||
      AppNotificationType.biddingClosed ||
      AppNotificationType.biddingCompleted => preferences.biddingNotifications,
      AppNotificationType.luckyDrawPending || AppNotificationType.luckyDrawCompleted => preferences.luckyDrawNotifications,
      AppNotificationType.reportGenerated => preferences.reportNotifications,
      AppNotificationType.ledgerWarning => preferences.ledgerWarningNotifications,
      _ => true,
    };
  }

  void _createPaymentDueReminder(
    String userId,
    KametiModel kameti,
    PaymentCycleModel cycle,
    MemberPaymentModel payment,
    MemberModel? member,
    DateTime scheduledAt,
  ) {
    createNotification(buildNotification(
      userId: userId,
      kametiId: kameti.id,
      cycleId: cycle.id,
      memberId: payment.memberId,
      relatedPaymentId: payment.id,
      type: AppNotificationType.paymentDueReminder,
      title: 'Payment Due Soon',
      message: '${CurrencyFormatter.pkr(payment.amountDue)} payment for ${member?.fullName ?? 'member'} in ${kameti.name} Cycle ${cycle.cycleNumber} is due on ${DateFormatter.display(cycle.dueDate)}.',
      priority: NotificationPriority.normal,
      actionType: NotificationActionType.openPayment,
      actionRoute: AppRoutes.cyclePayments,
      scheduledAt: scheduledAt,
    ));
  }

  bool _isPaid(MemberPaymentModel payment) => payment.paymentStatus == PaymentStatus.paid || payment.paymentStatus == PaymentStatus.waived;
  String _dateKey(DateTime date) => '${date.year}${date.month}${date.day}';

  KametiModel? _kametiById(List<KametiModel> kametis, String id) {
    for (final kameti in kametis) {
      if (kameti.id == id) return kameti;
    }
    return null;
  }

  PaymentCycleModel? _cycleById(List<PaymentCycleModel> cycles, String id) {
    for (final cycle in cycles) {
      if (cycle.id == id) return cycle;
    }
    return null;
  }

  MemberModel? _memberById(List<MemberModel> members, String id) {
    for (final member in members) {
      if (member.id == id) return member;
    }
    return null;
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, List<NotificationModel>>((ref) => NotificationController());

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
