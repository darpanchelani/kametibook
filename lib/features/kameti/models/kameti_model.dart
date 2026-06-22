enum KametiType {
  ownerFirst('Owner First'),
  luckyDraw('Lucky Draw / Khulli Chhutti'),
  bidding('Bidding / Auction'),
  fixedOrder('Fixed Order'),
  mutualDecision('Mutual Decision');

  const KametiType(this.label);
  final String label;
}

enum KametiStatus {
  draft('Draft'),
  active('Active'),
  completed('Completed'),
  cancelled('Cancelled');

  const KametiStatus(this.label);
  final String label;
}

class KametiModel {
  const KametiModel({
    required this.id,
    required this.name,
    required this.type,
    required this.monthlyAmount,
    required this.totalMembers,
    required this.durationMonths,
    required this.startDate,
    required this.dueDay,
    required this.organizerName,
    required this.description,
    required this.totalPoolAmount,
    required this.status,
    required this.createdAt,
    this.requirePaymentBeforeDraw = true,
    this.requirePaymentBeforeBidding = true,
    this.discountDistributionType = DiscountDistributionType.equalToAllNonWinners,
    this.minimumBidAmount,
    this.biddingRules = '',
    this.requirePaymentBeforeReceiving = true,
    this.ownerReceivesFirstCycle = true,
    this.afterOwnerAllocationMode = AfterOwnerAllocationMode.manualSelection,
    this.remindersEnabled = true,
    this.paymentReminderDaysBefore = 2,
    this.paymentReminderOnDueDate = true,
    this.overdueReminderEnabled = true,
    this.overdueReminderFrequency = OverdueReminderFrequency.daily,
    this.payoutProofReminderEnabled = true,
    this.receiverPendingReminderEnabled = true,
    this.biddingReminderEnabled = true,
    this.luckyDrawReminderEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
  });

  final String id;
  final String name;
  final KametiType type;
  final double monthlyAmount;
  final int totalMembers;
  final int durationMonths;
  final DateTime startDate;
  final int dueDay;
  final String organizerName;
  final String description;
  final double totalPoolAmount;
  final KametiStatus status;
  final DateTime createdAt;
  final bool requirePaymentBeforeDraw;
  final bool requirePaymentBeforeBidding;
  final DiscountDistributionType discountDistributionType;
  final double? minimumBidAmount;
  final String biddingRules;
  final bool requirePaymentBeforeReceiving;
  final bool ownerReceivesFirstCycle;
  final AfterOwnerAllocationMode afterOwnerAllocationMode;
  final bool remindersEnabled;
  final int paymentReminderDaysBefore;
  final bool paymentReminderOnDueDate;
  final bool overdueReminderEnabled;
  final OverdueReminderFrequency overdueReminderFrequency;
  final bool payoutProofReminderEnabled;
  final bool receiverPendingReminderEnabled;
  final bool biddingReminderEnabled;
  final bool luckyDrawReminderEnabled;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;

  KametiModel copyWith({
    String? id,
    String? name,
    KametiType? type,
    double? monthlyAmount,
    int? totalMembers,
    int? durationMonths,
    DateTime? startDate,
    int? dueDay,
    String? organizerName,
    String? description,
    double? totalPoolAmount,
    KametiStatus? status,
    DateTime? createdAt,
    bool? requirePaymentBeforeDraw,
    bool? requirePaymentBeforeBidding,
    DiscountDistributionType? discountDistributionType,
    double? minimumBidAmount,
    String? biddingRules,
    bool? requirePaymentBeforeReceiving,
    bool? ownerReceivesFirstCycle,
    AfterOwnerAllocationMode? afterOwnerAllocationMode,
    bool? remindersEnabled,
    int? paymentReminderDaysBefore,
    bool? paymentReminderOnDueDate,
    bool? overdueReminderEnabled,
    OverdueReminderFrequency? overdueReminderFrequency,
    bool? payoutProofReminderEnabled,
    bool? receiverPendingReminderEnabled,
    bool? biddingReminderEnabled,
    bool? luckyDrawReminderEnabled,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return KametiModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      totalMembers: totalMembers ?? this.totalMembers,
      durationMonths: durationMonths ?? this.durationMonths,
      startDate: startDate ?? this.startDate,
      dueDay: dueDay ?? this.dueDay,
      organizerName: organizerName ?? this.organizerName,
      description: description ?? this.description,
      totalPoolAmount: totalPoolAmount ?? this.totalPoolAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      requirePaymentBeforeDraw: requirePaymentBeforeDraw ?? this.requirePaymentBeforeDraw,
      requirePaymentBeforeBidding: requirePaymentBeforeBidding ?? this.requirePaymentBeforeBidding,
      discountDistributionType: discountDistributionType ?? this.discountDistributionType,
      minimumBidAmount: minimumBidAmount ?? this.minimumBidAmount,
      biddingRules: biddingRules ?? this.biddingRules,
      requirePaymentBeforeReceiving: requirePaymentBeforeReceiving ?? this.requirePaymentBeforeReceiving,
      ownerReceivesFirstCycle: ownerReceivesFirstCycle ?? this.ownerReceivesFirstCycle,
      afterOwnerAllocationMode: afterOwnerAllocationMode ?? this.afterOwnerAllocationMode,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      paymentReminderDaysBefore: paymentReminderDaysBefore ?? this.paymentReminderDaysBefore,
      paymentReminderOnDueDate: paymentReminderOnDueDate ?? this.paymentReminderOnDueDate,
      overdueReminderEnabled: overdueReminderEnabled ?? this.overdueReminderEnabled,
      overdueReminderFrequency: overdueReminderFrequency ?? this.overdueReminderFrequency,
      payoutProofReminderEnabled: payoutProofReminderEnabled ?? this.payoutProofReminderEnabled,
      receiverPendingReminderEnabled: receiverPendingReminderEnabled ?? this.receiverPendingReminderEnabled,
      biddingReminderEnabled: biddingReminderEnabled ?? this.biddingReminderEnabled,
      luckyDrawReminderEnabled: luckyDrawReminderEnabled ?? this.luckyDrawReminderEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}

enum OverdueReminderFrequency {
  daily('Daily'),
  weekly('Weekly'),
  manual('Manual only');

  const OverdueReminderFrequency(this.label);
  final String label;
}

enum DiscountDistributionType {
  equalToAllNonWinners('Equal to all non-winners'),
  equalToAllMembers('Equal to all members'),
  groupWallet('Group wallet'),
  manualLater('Manual later');

  const DiscountDistributionType(this.label);
  final String label;
}

enum AfterOwnerAllocationMode {
  manualSelection('Manual Selection'),
  fixedOrder('Fixed Order'),
  mutualDecision('Mutual Decision');

  const AfterOwnerAllocationMode(this.label);
  final String label;
}
