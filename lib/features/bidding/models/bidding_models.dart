import '../../kameti/models/kameti_model.dart';
import '../../member/models/member_model.dart';

enum BidStatus {
  active('Active'),
  withdrawn('Withdrawn'),
  winning('Winning'),
  lost('Lost'),
  rejected('Rejected');

  const BidStatus(this.label);
  final String label;
}

enum BiddingSessionStatus {
  notStarted('Not Started'),
  open('Open'),
  closed('Closed'),
  completed('Completed'),
  cancelled('Cancelled');

  const BiddingSessionStatus(this.label);
  final String label;
}

enum AdjustmentType {
  discountShare('Discount Share'),
  groupWallet('Group Wallet'),
  manual('Manual');

  const AdjustmentType(this.label);
  final String label;
}

enum AdjustmentStatus {
  pending('Pending'),
  applied('Applied'),
  cancelled('Cancelled');

  const AdjustmentStatus(this.label);
  final String label;
}

class BidModel {
  const BidModel({
    required this.id,
    required this.kametiId,
    required this.cycleId,
    required this.cycleNumber,
    required this.memberId,
    required this.memberName,
    required this.bidAmount,
    required this.status,
    required this.note,
    required this.submittedAt,
    required this.updatedAt,
  });

  final String id;
  final String kametiId;
  final String cycleId;
  final int cycleNumber;
  final String memberId;
  final String memberName;
  final double bidAmount;
  final BidStatus status;
  final String note;
  final DateTime submittedAt;
  final DateTime updatedAt;

  BidModel copyWith({
    double? bidAmount,
    BidStatus? status,
    String? note,
    DateTime? updatedAt,
  }) {
    return BidModel(
      id: id,
      kametiId: kametiId,
      cycleId: cycleId,
      cycleNumber: cycleNumber,
      memberId: memberId,
      memberName: memberName,
      bidAmount: bidAmount ?? this.bidAmount,
      status: status ?? this.status,
      note: note ?? this.note,
      submittedAt: submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BiddingSessionModel {
  const BiddingSessionModel({
    required this.id,
    required this.kametiId,
    required this.cycleId,
    required this.cycleNumber,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.createdBy,
    required this.totalPoolAmount,
    required this.minimumBidAmount,
    required this.maximumBidAmount,
    required this.winningBidId,
    required this.winnerMemberId,
    required this.winningAmount,
    required this.discountAmount,
    required this.discountDistributionType,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String kametiId;
  final String cycleId;
  final int cycleNumber;
  final BiddingSessionStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final String createdBy;
  final double totalPoolAmount;
  final double minimumBidAmount;
  final double maximumBidAmount;
  final String winningBidId;
  final String winnerMemberId;
  final double winningAmount;
  final double discountAmount;
  final DiscountDistributionType discountDistributionType;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  BiddingSessionModel copyWith({
    BiddingSessionStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    String? winningBidId,
    String? winnerMemberId,
    double? winningAmount,
    double? discountAmount,
    DiscountDistributionType? discountDistributionType,
    String? notes,
    DateTime? updatedAt,
  }) {
    return BiddingSessionModel(
      id: id,
      kametiId: kametiId,
      cycleId: cycleId,
      cycleNumber: cycleNumber,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdBy: createdBy,
      totalPoolAmount: totalPoolAmount,
      minimumBidAmount: minimumBidAmount,
      maximumBidAmount: maximumBidAmount,
      winningBidId: winningBidId ?? this.winningBidId,
      winnerMemberId: winnerMemberId ?? this.winnerMemberId,
      winningAmount: winningAmount ?? this.winningAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      discountDistributionType: discountDistributionType ?? this.discountDistributionType,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DiscountAdjustmentModel {
  const DiscountAdjustmentModel({
    required this.id,
    required this.kametiId,
    required this.cycleId,
    required this.biddingSessionId,
    required this.memberId,
    required this.memberName,
    required this.adjustmentAmount,
    required this.adjustmentType,
    required this.applyToCycleId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String kametiId;
  final String cycleId;
  final String biddingSessionId;
  final String memberId;
  final String memberName;
  final double adjustmentAmount;
  final AdjustmentType adjustmentType;
  final String applyToCycleId;
  final AdjustmentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class BiddingEligibilityResult {
  const BiddingEligibilityResult({
    required this.eligibleMembers,
    required this.excludedMembers,
    required this.exclusionReasons,
  });

  final List<MemberModel> eligibleMembers;
  final List<MemberModel> excludedMembers;
  final Map<String, String> exclusionReasons;
}
