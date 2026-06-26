import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firebase_bootstrap.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_controller.dart';
import '../../kameti/models/kameti_model.dart';
import '../../kameti/providers/kameti_controller.dart';
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
  MemberController(this._ref) : super(const []) {
    _ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated ||
          next.status == AuthStatus.profileMissing ||
          next.status == AuthStatus.blocked) {
        clearUserData();
      }
    });
    _ref.listen<List<KametiModel>>(kametiControllerProvider, (previous, next) {
      _syncVisibleKametiMembers(next);
    });
    _syncVisibleKametiMembers(_ref.read(kametiControllerProvider));
  }

  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _memberSubscriptions = {};

  List<MemberModel> getMembersByKametiId(String kametiId) {
    final members =
        state.where((member) => member.kametiId == kametiId).toList();
    members.sort((a, b) {
      if (a.role != b.role) return a.role == MemberRole.organizer ? -1 : 1;
      if (a.status != b.status) {
        return a.status == MemberStatus.removed ? 1 : -1;
      }
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
    return getMembersByKametiId(kametiId)
        .where((member) => member.isActiveForCount)
        .length;
  }

  bool hasDuplicatePhone(String kametiId, String phone,
      {String? ignoreMemberId}) {
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
    final organizerId = currentUser?.id.isNotEmpty == true
        ? currentUser!.id
        : '${kameti.id}-organizer';
    final hasOrganizer = state.any(
      (member) =>
          member.kametiId == kameti.id && member.role == MemberRole.organizer,
    );
    if (hasOrganizer) return;

    final now = DateTime.now();
    addMember(
      MemberModel(
        id: organizerId,
        kametiId: kameti.id,
        fullName: currentUser?.fullName.trim().isNotEmpty == true
            ? currentUser!.fullName
            : kameti.organizerName,
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
        userId: currentUser?.id ?? '',
        joinedByApp: currentUser != null,
        linkedAt: currentUser == null ? null : now,
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
    _upsertMember(member);
  }

  String? updateMember({
    required String kametiId,
    required String memberId,
    required MemberModel updatedMember,
  }) {
    if (hasDuplicatePhone(kametiId, updatedMember.phone,
        ignoreMemberId: memberId)) {
      return 'A member with this phone number already exists.';
    }
    state = [
      for (final member in state)
        if (member.id == memberId)
          updatedMember.copyWith(updatedAt: DateTime.now())
        else
          member,
    ];
    return null;
  }

  String? removeMember({
    required KametiModel kameti,
    required String memberId,
  }) {
    final member = getMember(memberId);
    if (member == null) return 'Member not found.';
    if (member.role == MemberRole.organizer) {
      return 'Organizer cannot be removed.';
    }
    if (kameti.status != KametiStatus.draft) {
      return 'Cannot remove members after kameti has started.';
    }

    state = [
      for (final item in state)
        if (item.id == memberId)
          item.copyWith(status: MemberStatus.removed, updatedAt: DateTime.now())
        else
          item,
    ];
    return null;
  }

  String? blockMember({
    required KametiModel kameti,
    required String memberId,
    required String reason,
  }) {
    final member = getMember(memberId);
    if (member == null) return 'Member not found.';
    if (member.role == MemberRole.organizer) {
      return 'Organizer cannot be blocked.';
    }
    state = [
      for (final item in state)
        if (item.id == memberId)
          item.copyWith(
              status: MemberStatus.blocked,
              notes: reason.isEmpty
                  ? item.notes
                  : '${item.notes}\nBlocked: $reason',
              updatedAt: DateTime.now())
        else
          item,
    ];
    return null;
  }

  String? unblockMember({
    required String memberId,
  }) {
    final member = getMember(memberId);
    if (member == null) return 'Member not found.';
    state = [
      for (final item in state)
        if (item.id == memberId)
          item.copyWith(status: MemberStatus.active, updatedAt: DateTime.now())
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
    String receivedVia = 'luckyDraw',
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
            receivedVia: receivedVia,
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
        message:
            'Please add $remaining more members before starting this kameti.',
      );
    }
    return StartKametiCheck(
      canStart: true,
      activeMembersCount: activeMembersCount,
      remainingMembersCount: 0,
    );
  }

  static String _normalizePhone(String phone) =>
      phone.replaceAll(RegExp(r'\D'), '');

  Future<void> clearUserData() async {
    for (final subscription in _memberSubscriptions.values) {
      await subscription.cancel();
    }
    _memberSubscriptions.clear();
    state = const [];
  }

  void _syncVisibleKametiMembers(List<KametiModel> kametis) {
    if (!FirebaseBootstrap.isInitialized) return;
    final visibleIds = kametis.map((kameti) => kameti.id).toSet();

    for (final kametiId in _memberSubscriptions.keys.toList()) {
      if (!visibleIds.contains(kametiId)) {
        _memberSubscriptions.remove(kametiId)?.cancel();
        state = state.where((member) => member.kametiId != kametiId).toList();
      }
    }

    for (final kametiId in visibleIds) {
      if (_memberSubscriptions.containsKey(kametiId)) continue;
      _memberSubscriptions[kametiId] = _firestore
          .collection('kametis')
          .doc(kametiId)
          .collection('members')
          .snapshots()
          .listen(
        (snapshot) {
          final incomingMembers = snapshot.docs.map((doc) {
            return MemberModel.fromFirestore({
              ...doc.data(),
              'id': doc.data()['id'] ?? doc.id,
              'kametiId': doc.data()['kametiId'] ?? kametiId,
            });
          }).toList();
          final incomingIds =
              incomingMembers.map((member) => member.id).toSet();
          state = [
            for (final member in state)
              if (member.kametiId != kametiId ||
                  !incomingIds.contains(member.id))
                member,
            ...incomingMembers,
          ];
        },
        onError: (Object error) {
          debugPrint('KametiBook member sync failed for $kametiId: $error');
        },
      );
    }
  }

  void _upsertMember(MemberModel member) {
    state = [
      member,
      for (final item in state)
        if (item.kametiId != member.kametiId || item.id != member.id) item,
    ];
  }

  @override
  void dispose() {
    unawaited(clearUserData());
    super.dispose();
  }
}

final memberControllerProvider =
    StateNotifierProvider<MemberController, List<MemberModel>>((ref) {
  return MemberController(ref);
});
