import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/user_model.dart';
import '../../kameti/models/kameti_model.dart';
import '../models/member_model.dart';

class StartKametiCheck {
  const StartKametiCheck({
    required this.canStart,
    required this.activeMembersCount,
    required this.remainingMembersCount,
    this.message,
  });

  final bool canStart;
  final int activeMembersCount;
  final int remainingMembersCount;
  final String? message;
}

class MemberController extends StateNotifier<List<MemberModel>> {
  MemberController() : super(const []);

  List<MemberModel> getMembersByKametiId(String kametiId) {
    final members = state.where((member) => member.kametiId == kametiId).toList();
    members.sort((a, b) {
      if (a.role != b.role) return a.role == MemberRole.organizer ? -1 : 1;
      if (a.status != b.status) return a.status == MemberStatus.removed ? 1 : -1;
      return a.joinedAt.compareTo(b.joinedAt);
    });
    return members;
  }

  MemberModel? getMember(String memberId) {
    for (final member in state) {
      if (member.id == memberId) return member;
    }
    return null;
  }

  int getActiveMembersCount(String kametiId) {
    return getMembersByKametiId(kametiId).where((member) => member.isActiveForCount).length;
  }

  bool hasDuplicatePhone(String kametiId, String phone, {String? ignoreMemberId}) {
    final normalized = _normalizePhone(phone);
    return state.any(
      (member) =>
          member.kametiId == kametiId &&
          member.id != ignoreMemberId &&
          member.status != MemberStatus.removed &&
          _normalizePhone(member.phone) == normalized,
    );
  }

  void ensureOrganizerMember({
    required KametiModel kameti,
    required UserModel? currentUser,
  }) {
    final hasOrganizer = state.any(
      (member) => member.kametiId == kameti.id && member.role == MemberRole.organizer,
    );
    if (hasOrganizer) return;

    final now = DateTime.now();
    addMember(
      MemberModel(
        id: '${kameti.id}-organizer',
        kametiId: kameti.id,
        fullName: currentUser?.fullName.trim().isNotEmpty == true ? currentUser!.fullName : kameti.organizerName,
        phone: currentUser?.phone ?? '',
        city: currentUser?.city ?? 'Pakistan',
        cnic: '',
        whatsappNumber: currentUser?.phone ?? '',
        email: '',
        notes: 'Organizer/admin member',
        role: MemberRole.organizer,
        status: MemberStatus.active,
        hasReceivedKameti: false,
        joinedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  String? addMemberForKameti({
    required KametiModel kameti,
    required MemberModel member,
  }) {
    if (getActiveMembersCount(kameti.id) >= kameti.totalMembers) {
      return 'All member slots are filled.';
    }
    if (hasDuplicatePhone(kameti.id, member.phone)) {
      return 'A member with this phone number already exists.';
    }
    addMember(member);
    return null;
  }

  void addMember(MemberModel member) {
    state = [member, ...state];
  }

  String? updateMember({
    required String kametiId,
    required String memberId,
    required MemberModel updatedMember,
  }) {
    if (hasDuplicatePhone(kametiId, updatedMember.phone, ignoreMemberId: memberId)) {
      return 'A member with this phone number already exists.';
    }
    state = [
      for (final member in state)
        if (member.id == memberId) updatedMember.copyWith(updatedAt: DateTime.now()) else member,
    ];
    return null;
  }

  String? removeMember({
    required KametiModel kameti,
    required String memberId,
  }) {
    final member = getMember(memberId);
    if (member == null) return 'Member not found.';
    if (member.role == MemberRole.organizer) return 'Organizer cannot be removed.';
    if (kameti.status != KametiStatus.draft) return 'Cannot remove members after kameti has started.';

    state = [
      for (final item in state)
        if (item.id == memberId)
          item.copyWith(status: MemberStatus.removed, updatedAt: DateTime.now())
        else
          item,
    ];
    return null;
  }

  void markMemberReceived({
    required String memberId,
    required String cycleId,
    required int cycleNumber,
    required DateTime receivedAt,
    required double receivedAmount,
  }) {
    state = [
      for (final member in state)
        if (member.id == memberId)
          member.copyWith(
            hasReceivedKameti: true,
            receivedCycleId: cycleId,
            receivedCycleNumber: cycleNumber,
            receivedAt: receivedAt,
            receivedAmount: receivedAmount,
            updatedAt: DateTime.now(),
          )
        else
          member,
    ];
  }

  StartKametiCheck canStartKameti(KametiModel kameti) {
    final activeMembersCount = getActiveMembersCount(kameti.id);
    final remaining = kameti.totalMembers - activeMembersCount;
    final hasOrganizer = state.any(
      (member) =>
          member.kametiId == kameti.id &&
          member.role == MemberRole.organizer &&
          member.status != MemberStatus.removed,
    );

    if (kameti.status != KametiStatus.draft) {
      return StartKametiCheck(
        canStart: false,
        activeMembersCount: activeMembersCount,
        remainingMembersCount: remaining,
        message: 'Only draft kametis can be started.',
      );
    }
    if (!hasOrganizer) {
      return StartKametiCheck(
        canStart: false,
        activeMembersCount: activeMembersCount,
        remainingMembersCount: remaining,
        message: 'Organizer member is required before starting this kameti.',
      );
    }
    if (kameti.monthlyAmount <= 0 || kameti.durationMonths <= 0) {
      return StartKametiCheck(
        canStart: false,
        activeMembersCount: activeMembersCount,
        remainingMembersCount: remaining,
        message: 'Kameti amount and duration must be valid before starting.',
      );
    }
    if (remaining > 0) {
      return StartKametiCheck(
        canStart: false,
        activeMembersCount: activeMembersCount,
        remainingMembersCount: remaining,
        message: 'Please add $remaining more members before starting this kameti.',
      );
    }
    return StartKametiCheck(
      canStart: true,
      activeMembersCount: activeMembersCount,
      remainingMembersCount: 0,
    );
  }

  static String _normalizePhone(String phone) => phone.replaceAll(RegExp(r'\D'), '');
}

final memberControllerProvider =
    StateNotifierProvider<MemberController, List<MemberModel>>((ref) {
  return MemberController();
});
