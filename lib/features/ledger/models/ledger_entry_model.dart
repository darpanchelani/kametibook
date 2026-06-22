import '../../payment/models/payment_models.dart';

enum LedgerEntryType {
  contribution('Contribution'),
  payout('Payout'),
  discountGenerated('Discount Generated'),
  discountAdjustment('Discount Adjustment'),
  penalty('Penalty'),
  refund('Refund'),
  correction('Correction'),
  groupWallet('Group Wallet'),
  manualNote('Manual Note');

  const LedgerEntryType(this.label);
  final String label;
}

enum LedgerDirection {
  moneyIn('Money In'),
  moneyOut('Money Out'),
  neutral('Neutral');

  const LedgerDirection(this.label);
  final String label;
}

enum LedgerStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  cancelled('Cancelled'),
  reversed('Reversed');

  const LedgerStatus(this.label);
  final String label;
}

class LedgerEntryModel {
  const LedgerEntryModel({
    required this.id,
    required this.kametiId,
    required this.cycleId,
    required this.memberId,
    required this.relatedPaymentId,
    required this.relatedAllocationId,
    required this.relatedBiddingSessionId,
    required this.relatedDiscountAdjustmentId,
    required this.entryType,
    required this.direction,
    required this.amount,
    required this.title,
    required this.description,
    required this.paymentMethod,
    required this.proofPath,
    required this.status,
    required this.entryDate,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String kametiId;
  final String cycleId;
  final String memberId;
  final String relatedPaymentId;
  final String relatedAllocationId;
  final String relatedBiddingSessionId;
  final String relatedDiscountAdjustmentId;
  final LedgerEntryType entryType;
  final LedgerDirection direction;
  final double amount;
  final String title;
  final String description;
  final PaymentMethod? paymentMethod;
  final String proofPath;
  final LedgerStatus status;
  final DateTime entryDate;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  LedgerEntryModel copyWith({
    LedgerStatus? status,
    PaymentMethod? paymentMethod,
    String? proofPath,
    String? description,
    DateTime? entryDate,
    DateTime? updatedAt,
  }) {
    return LedgerEntryModel(
      id: id,
      kametiId: kametiId,
      cycleId: cycleId,
      memberId: memberId,
      relatedPaymentId: relatedPaymentId,
      relatedAllocationId: relatedAllocationId,
      relatedBiddingSessionId: relatedBiddingSessionId,
      relatedDiscountAdjustmentId: relatedDiscountAdjustmentId,
      entryType: entryType,
      direction: direction,
      amount: amount,
      title: title,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      proofPath: proofPath ?? this.proofPath,
      status: status ?? this.status,
      entryDate: entryDate ?? this.entryDate,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LedgerSummary {
  const LedgerSummary({
    required this.totalContributions,
    required this.totalPayouts,
    required this.totalDiscounts,
    required this.totalPenalties,
    required this.groupBalance,
  });

  final double totalContributions;
  final double totalPayouts;
  final double totalDiscounts;
  final double totalPenalties;
  final double groupBalance;
}
