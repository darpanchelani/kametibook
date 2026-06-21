import '../../member/models/member_model.dart';

enum LuckyDrawType {
  luckyDraw('Lucky Draw'),
  manualSelection('Manual Selection');

  const LuckyDrawType(this.label);
  final String label;
}

enum LuckyDrawStatus {
  pending('Pending'),
  completed('Completed'),
  cancelled('Cancelled');

  const LuckyDrawStatus(this.label);
  final String label;
}

class LuckyDrawModel {
  const LuckyDrawModel({
    required this.id,
    required this.kametiId,
    required this.cycleId,
    required this.cycleNumber,
    required this.winnerMemberId,
    required this.winnerName,
    required this.drawType,
    required this.eligibleMemberIds,
    required this.excludedMemberIds,
    required this.exclusionReasons,
    required this.totalEligibleMembers,
    required this.totalExcludedMembers,
    required this.payoutAmount,
    required this.status,
    required this.drawDate,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.notes,
  });

  final String id;
  final String kametiId;
  final String cycleId;
  final int cycleNumber;
  final String winnerMemberId;
  final String winnerName;
  final LuckyDrawType drawType;
  final List<String> eligibleMemberIds;
  final List<String> excludedMemberIds;
  final Map<String, String> exclusionReasons;
  final int totalEligibleMembers;
  final int totalExcludedMembers;
  final double payoutAmount;
  final LuckyDrawStatus status;
  final DateTime drawDate;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String notes;
}

class DrawEligibilityResult {
  const DrawEligibilityResult({
    required this.eligibleMembers,
    required this.excludedMembers,
    required this.exclusionReasons,
  });

  final List<MemberModel> eligibleMembers;
  final List<MemberModel> excludedMembers;
  final Map<String, String> exclusionReasons;
}
