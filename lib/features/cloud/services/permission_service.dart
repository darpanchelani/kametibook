import '../../member/models/member_model.dart';

class KametiPermissionService {
  const KametiPermissionService();

  bool canManageKameti(MemberModel? member) => member?.role == MemberRole.organizer || member?.role == MemberRole.coOrganizer;
  bool canViewKameti(MemberModel? member) => member != null && member.status != MemberStatus.removed;
  bool canSubmitPayment(MemberModel? member, String paymentMemberId) => member != null && member.id == paymentMemberId && member.status == MemberStatus.active;
  bool canApprovePayment(MemberModel? member) => canManageKameti(member);
  bool canRunDraw(MemberModel? member) => canManageKameti(member);
  bool canManageBidding(MemberModel? member) => canManageKameti(member);
  bool canSubmitBid(MemberModel? member) => member != null && member.status == MemberStatus.active && !member.hasReceivedKameti;
  bool canViewLedger(MemberModel? member) => canViewKameti(member);
  bool canGenerateReports(MemberModel? member) => canManageKameti(member);
}
