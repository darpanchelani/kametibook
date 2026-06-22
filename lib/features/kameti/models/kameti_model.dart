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
    );
  }
}

enum DiscountDistributionType {
  equalToAllNonWinners('Equal to all non-winners'),
  equalToAllMembers('Equal to all members'),
  groupWallet('Group wallet'),
  manualLater('Manual later');

  const DiscountDistributionType(this.label);
  final String label;
}
