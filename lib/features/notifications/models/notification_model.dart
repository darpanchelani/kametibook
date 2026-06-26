enum AppNotificationType {
  paymentDueReminder('Payment Reminder'),
  paymentOverdue('Payment Overdue'),
  paymentMarkedPaid('Payment Received'),
  paymentRejected('Payment Rejected'),
  paymentApproved('Payment Approved'),
  payoutPending('Payout Pending'),
  payoutPaid('Payout Paid'),
  receiverPending('Receiver Pending'),
  receiverConfirmed('Receiver Confirmed'),
  luckyDrawPending('Lucky Draw Pending'),
  luckyDrawCompleted('Lucky Draw Completed'),
  biddingStarted('Bidding Started'),
  biddingClosingSoon('Bidding Closing Soon'),
  biddingClosed('Bidding Closed'),
  biddingCompleted('Bidding Completed'),
  cycleCompleted('Cycle Completed'),
  reportGenerated('Report Generated'),
  ledgerWarning('Ledger Warning'),
  memberAdded('Member Added'),
  kametiStarted('Kameti Started'),
  general('General');

  const AppNotificationType(this.label);
  final String label;
}

enum NotificationPriority {
  low('Low'),
  normal('Normal'),
  high('High'),
  urgent('Urgent');

  const NotificationPriority(this.label);
  final String label;
}

enum NotificationStatus {
  unread('Unread'),
  read('Read'),
  dismissed('Dismissed'),
  scheduled('Scheduled'),
  sent('Sent'),
  failed('Failed');

  const NotificationStatus(this.label);
  final String label;
}

enum NotificationActionType {
  openKameti,
  openCycle,
  openPayment,
  openPayout,
  openBidding,
  openLuckyDraw,
  openReport,
  openLedger,
  none;
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.kametiId,
    required this.cycleId,
    required this.memberId,
    required this.relatedPaymentId,
    required this.relatedAllocationId,
    required this.relatedBiddingSessionId,
    required this.relatedDrawId,
    required this.relatedReportId,
    required this.notificationType,
    required this.title,
    required this.message,
    required this.priority,
    required this.status,
    required this.actionType,
    required this.actionRoute,
    required this.scheduledAt,
    required this.triggeredAt,
    required this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String kametiId;
  final String cycleId;
  final String memberId;
  final String relatedPaymentId;
  final String relatedAllocationId;
  final String relatedBiddingSessionId;
  final String relatedDrawId;
  final String relatedReportId;
  final AppNotificationType notificationType;
  final String title;
  final String message;
  final NotificationPriority priority;
  final NotificationStatus status;
  final NotificationActionType actionType;
  final String actionRoute;
  final DateTime? scheduledAt;
  final DateTime? triggeredAt;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isUnread =>
      status == NotificationStatus.unread || status == NotificationStatus.sent;

  NotificationModel copyWith({
    NotificationStatus? status,
    DateTime? triggeredAt,
    DateTime? readAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      kametiId: kametiId,
      cycleId: cycleId,
      memberId: memberId,
      relatedPaymentId: relatedPaymentId,
      relatedAllocationId: relatedAllocationId,
      relatedBiddingSessionId: relatedBiddingSessionId,
      relatedDrawId: relatedDrawId,
      relatedReportId: relatedReportId,
      notificationType: notificationType,
      title: title,
      message: message,
      priority: priority,
      status: status ?? this.status,
      actionType: actionType,
      actionRoute: actionRoute,
      scheduledAt: scheduledAt,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserNotificationPreferencesModel {
  const UserNotificationPreferencesModel({
    required this.userId,
    this.inAppEnabled = true,
    this.paymentNotifications = true,
    this.payoutNotifications = true,
    this.receiverNotifications = true,
    this.biddingNotifications = true,
    this.luckyDrawNotifications = true,
    this.reportNotifications = true,
    this.ledgerWarningNotifications = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.localPushEnabled = false,
    this.hideAmountOnLockScreen = true,
  });

  final String userId;
  final bool inAppEnabled;
  final bool paymentNotifications;
  final bool payoutNotifications;
  final bool receiverNotifications;
  final bool biddingNotifications;
  final bool luckyDrawNotifications;
  final bool reportNotifications;
  final bool ledgerWarningNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool localPushEnabled;
  final bool hideAmountOnLockScreen;

  UserNotificationPreferencesModel copyWith({
    bool? inAppEnabled,
    bool? paymentNotifications,
    bool? payoutNotifications,
    bool? receiverNotifications,
    bool? biddingNotifications,
    bool? luckyDrawNotifications,
    bool? reportNotifications,
    bool? ledgerWarningNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? localPushEnabled,
    bool? hideAmountOnLockScreen,
  }) {
    return UserNotificationPreferencesModel(
      userId: userId,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      paymentNotifications: paymentNotifications ?? this.paymentNotifications,
      payoutNotifications: payoutNotifications ?? this.payoutNotifications,
      receiverNotifications:
          receiverNotifications ?? this.receiverNotifications,
      biddingNotifications: biddingNotifications ?? this.biddingNotifications,
      luckyDrawNotifications:
          luckyDrawNotifications ?? this.luckyDrawNotifications,
      reportNotifications: reportNotifications ?? this.reportNotifications,
      ledgerWarningNotifications:
          ledgerWarningNotifications ?? this.ledgerWarningNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      localPushEnabled: localPushEnabled ?? this.localPushEnabled,
      hideAmountOnLockScreen:
          hideAmountOnLockScreen ?? this.hideAmountOnLockScreen,
    );
  }
}
