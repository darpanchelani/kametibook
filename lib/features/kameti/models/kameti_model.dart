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
    this.ownerUserId = '',
    this.memberUserIds = const <String>[],
    this.requirePaymentBeforeDraw = true,
    this.requirePaymentBeforeBidding = true,
    this.discountDistributionType =
        DiscountDistributionType.equalToAllNonWinners,
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
  final String ownerUserId;
  final List<String> memberUserIds;
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
    String? ownerUserId,
    List<String>? memberUserIds,
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
      ownerUserId: ownerUserId ?? this.ownerUserId,
      memberUserIds: memberUserIds ?? this.memberUserIds,
      requirePaymentBeforeDraw:
          requirePaymentBeforeDraw ?? this.requirePaymentBeforeDraw,
      requirePaymentBeforeBidding:
          requirePaymentBeforeBidding ?? this.requirePaymentBeforeBidding,
      discountDistributionType:
          discountDistributionType ?? this.discountDistributionType,
      minimumBidAmount: minimumBidAmount ?? this.minimumBidAmount,
      biddingRules: biddingRules ?? this.biddingRules,
      requirePaymentBeforeReceiving:
          requirePaymentBeforeReceiving ?? this.requirePaymentBeforeReceiving,
      ownerReceivesFirstCycle:
          ownerReceivesFirstCycle ?? this.ownerReceivesFirstCycle,
      afterOwnerAllocationMode:
          afterOwnerAllocationMode ?? this.afterOwnerAllocationMode,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      paymentReminderDaysBefore:
          paymentReminderDaysBefore ?? this.paymentReminderDaysBefore,
      paymentReminderOnDueDate:
          paymentReminderOnDueDate ?? this.paymentReminderOnDueDate,
      overdueReminderEnabled:
          overdueReminderEnabled ?? this.overdueReminderEnabled,
      overdueReminderFrequency:
          overdueReminderFrequency ?? this.overdueReminderFrequency,
      payoutProofReminderEnabled:
          payoutProofReminderEnabled ?? this.payoutProofReminderEnabled,
      receiverPendingReminderEnabled:
          receiverPendingReminderEnabled ?? this.receiverPendingReminderEnabled,
      biddingReminderEnabled:
          biddingReminderEnabled ?? this.biddingReminderEnabled,
      luckyDrawReminderEnabled:
          luckyDrawReminderEnabled ?? this.luckyDrawReminderEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'monthlyAmount': monthlyAmount,
      'totalMembers': totalMembers,
      'durationMonths': durationMonths,
      'startDate': startDate.millisecondsSinceEpoch,
      'dueDay': dueDay,
      'organizerName': organizerName,
      'description': description,
      'totalPoolAmount': totalPoolAmount,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'ownerUserId': ownerUserId,
      'memberUserIds': memberUserIds,
      'requirePaymentBeforeDraw': requirePaymentBeforeDraw,
      'requirePaymentBeforeBidding': requirePaymentBeforeBidding,
      'discountDistributionType': discountDistributionType.name,
      'minimumBidAmount': minimumBidAmount,
      'biddingRules': biddingRules,
      'requirePaymentBeforeReceiving': requirePaymentBeforeReceiving,
      'ownerReceivesFirstCycle': ownerReceivesFirstCycle,
      'afterOwnerAllocationMode': afterOwnerAllocationMode.name,
      'remindersEnabled': remindersEnabled,
      'paymentReminderDaysBefore': paymentReminderDaysBefore,
      'paymentReminderOnDueDate': paymentReminderOnDueDate,
      'overdueReminderEnabled': overdueReminderEnabled,
      'overdueReminderFrequency': overdueReminderFrequency.name,
      'payoutProofReminderEnabled': payoutProofReminderEnabled,
      'receiverPendingReminderEnabled': receiverPendingReminderEnabled,
      'biddingReminderEnabled': biddingReminderEnabled,
      'luckyDrawReminderEnabled': luckyDrawReminderEnabled,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
    };
  }

  factory KametiModel.fromFirestore(Map<String, dynamic> data) {
    return KametiModel(
      id: _stringValue(data['id']),
      name: _stringValue(data['name'], fallback: 'Untitled Kameti'),
      type: _enumValue(KametiType.values, data['type'], KametiType.ownerFirst),
      monthlyAmount: _doubleValue(data['monthlyAmount']),
      totalMembers: _intValue(data['totalMembers']),
      durationMonths: _intValue(data['durationMonths']),
      startDate: _dateValue(data['startDate']),
      dueDay: _intValue(data['dueDay'], fallback: 1),
      organizerName: _stringValue(data['organizerName']),
      description: _stringValue(data['description']),
      totalPoolAmount: _doubleValue(data['totalPoolAmount']),
      status:
          _enumValue(KametiStatus.values, data['status'], KametiStatus.draft),
      createdAt: _dateValue(data['createdAt']),
      ownerUserId: _stringValue(data['ownerUserId']),
      memberUserIds: _stringListValue(data['memberUserIds']),
      requirePaymentBeforeDraw:
          _boolValue(data['requirePaymentBeforeDraw'], fallback: true),
      requirePaymentBeforeBidding:
          _boolValue(data['requirePaymentBeforeBidding'], fallback: true),
      discountDistributionType: _enumValue(
        DiscountDistributionType.values,
        data['discountDistributionType'],
        DiscountDistributionType.equalToAllNonWinners,
      ),
      minimumBidAmount: data['minimumBidAmount'] == null
          ? null
          : _doubleValue(data['minimumBidAmount']),
      biddingRules: _stringValue(data['biddingRules']),
      requirePaymentBeforeReceiving:
          _boolValue(data['requirePaymentBeforeReceiving'], fallback: true),
      ownerReceivesFirstCycle:
          _boolValue(data['ownerReceivesFirstCycle'], fallback: true),
      afterOwnerAllocationMode: _enumValue(
        AfterOwnerAllocationMode.values,
        data['afterOwnerAllocationMode'],
        AfterOwnerAllocationMode.manualSelection,
      ),
      remindersEnabled: _boolValue(data['remindersEnabled'], fallback: true),
      paymentReminderDaysBefore:
          _intValue(data['paymentReminderDaysBefore'], fallback: 2),
      paymentReminderOnDueDate:
          _boolValue(data['paymentReminderOnDueDate'], fallback: true),
      overdueReminderEnabled:
          _boolValue(data['overdueReminderEnabled'], fallback: true),
      overdueReminderFrequency: _enumValue(
        OverdueReminderFrequency.values,
        data['overdueReminderFrequency'],
        OverdueReminderFrequency.daily,
      ),
      payoutProofReminderEnabled:
          _boolValue(data['payoutProofReminderEnabled'], fallback: true),
      receiverPendingReminderEnabled:
          _boolValue(data['receiverPendingReminderEnabled'], fallback: true),
      biddingReminderEnabled:
          _boolValue(data['biddingReminderEnabled'], fallback: true),
      luckyDrawReminderEnabled:
          _boolValue(data['luckyDrawReminderEnabled'], fallback: true),
      quietHoursEnabled: _boolValue(data['quietHoursEnabled']),
      quietHoursStart: _stringValue(data['quietHoursStart'], fallback: '22:00'),
      quietHoursEnd: _stringValue(data['quietHoursEnd'], fallback: '08:00'),
    );
  }
}

String _stringValue(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value;
  return fallback;
}

double _doubleValue(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool _boolValue(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  return fallback;
}

DateTime _dateValue(Object? value) {
  if (value is DateTime) return value;
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

List<String> _stringListValue(Object? value) {
  if (value is Iterable) return value.map((item) => item.toString()).toList();
  return const <String>[];
}

T _enumValue<T extends Enum>(List<T> values, Object? value, T fallback) {
  final name = value?.toString();
  if (name == null || name.isEmpty) return fallback;
  for (final item in values) {
    if (item.name == name) return item;
  }
  return fallback;
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
