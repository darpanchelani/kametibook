import '../../member/models/member_model.dart';

enum ReceiverAllocationType {
  ownerFirst('Owner First'),
  luckyDraw('Lucky Draw'),
  bidding('Bidding'),
  fixedOrder('Fixed Order'),
  mutualDecision('Mutual Decision'),
  manual('Manual');

  const ReceiverAllocationType(this.label);
  final String label;
}

enum ReceiverAllocationStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  cancelled('Cancelled');

  const ReceiverAllocationStatus(this.label);
  final String label;
}

enum FixedOrderSlotStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  skipped('Skipped');

  const FixedOrderSlotStatus(this.label);
  final String label;
}

class ReceiverAllocationModel {
  const ReceiverAllocationModel({
    required this.id,
    required this.kametiId,
    required this.cycleId,
    required this.cycleNumber,
    required this.memberId,
    required this.memberName,
    required this.memberPhone,
    required this.allocationType,
    required this.amount,
    required this.status,
    required this.selectedBy,
    required this.selectedAt,
    required this.confirmedAt,
    required this.notes,
    required this.sourceId,
    required this.createdAt,
    required this.updatedAt,
    this.payoutStatus = PayoutStatus.pending,
    this.payoutMethod,
    this.payoutProofPath = '',
    this.payoutNote = '',
    this.payoutPaidAt,
    this.payoutConfirmedBy = '',
  });

  final String id;
  final String kametiId;
  final String cycleId;
  final int cycleNumber;
  final String memberId;
  final String memberName;
  final String memberPhone;
  final ReceiverAllocationType allocationType;
  final double amount;
  final ReceiverAllocationStatus status;
  final String selectedBy;
  final DateTime selectedAt;
  final DateTime? confirmedAt;
  final String notes;
  final String sourceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PayoutStatus payoutStatus;
  final PayoutMethod? payoutMethod;
  final String payoutProofPath;
  final String payoutNote;
  final DateTime? payoutPaidAt;
  final String payoutConfirmedBy;
}

enum PayoutStatus {
  pending('Pending'),
  paid('Paid'),
  proofUploaded('Proof Uploaded'),
  confirmed('Confirmed'),
  rejected('Rejected');

  const PayoutStatus(this.label);
  final String label;
}

enum PayoutMethod {
  cash('Cash'),
  bankTransfer('Bank Transfer'),
  easypaisa('Easypaisa'),
  jazzcash('JazzCash'),
  sadapay('SadaPay'),
  nayapay('NayaPay'),
  other('Other');

  const PayoutMethod(this.label);
  final String label;
}

class FixedOrderSlotModel {
  const FixedOrderSlotModel({
    required this.id,
    required this.kametiId,
    required this.cycleNumber,
    required this.memberId,
    required this.memberName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String kametiId;
  final int cycleNumber;
  final String memberId;
  final String memberName;
  final FixedOrderSlotStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ReceiverEligibilityResult {
  const ReceiverEligibilityResult({
    required this.eligibleMembers,
    required this.excludedMembers,
    required this.exclusionReasons,
  });

  final List<MemberModel> eligibleMembers;
  final List<MemberModel> excludedMembers;
  final Map<String, String> exclusionReasons;
}
