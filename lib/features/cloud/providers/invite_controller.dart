import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cloud/models/kameti_invite_model.dart';
import '../../kameti/models/kameti_model.dart';
import '../../member/models/member_model.dart';

class InviteController extends StateNotifier<List<KametiInviteModel>> {
  InviteController() : super(const []);

  KametiInviteModel createInvite({
    required KametiModel kameti,
    required String invitedPhone,
    required MemberRole role,
    required String invitedBy,
  }) {
    final now = DateTime.now();
    final invite = KametiInviteModel(
      id: 'invite-${now.microsecondsSinceEpoch}',
      kametiId: kameti.id,
      invitedPhone: invitedPhone,
      invitedUserId: '',
      inviteCode: _code(),
      role: role,
      status: KametiInviteStatus.pending,
      invitedBy: invitedBy,
      expiresAt: now.add(const Duration(days: 14)),
      acceptedAt: null,
      createdAt: now,
      updatedAt: now,
    );
    state = [invite, ...state];
    return invite;
  }

  KametiInviteModel? byCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final invite in state) {
      if (invite.inviteCode == normalized) return invite;
    }
    return null;
  }

  void acceptInvite(String inviteId, String userId) {
    final now = DateTime.now();
    state = [
      for (final invite in state)
        if (invite.id == inviteId)
          invite.copyWith(
            invitedUserId: userId,
            status: KametiInviteStatus.accepted,
            acceptedAt: now,
            updatedAt: now,
          )
        else
          invite,
    ];
  }

  void rejectInvite(String inviteId) {
    state = [
      for (final invite in state)
        if (invite.id == inviteId)
          invite.copyWith(
              status: KametiInviteStatus.rejected, updatedAt: DateTime.now())
        else
          invite,
    ];
  }

  String _code() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

final inviteControllerProvider =
    StateNotifierProvider<InviteController, List<KametiInviteModel>>(
        (ref) => InviteController());
