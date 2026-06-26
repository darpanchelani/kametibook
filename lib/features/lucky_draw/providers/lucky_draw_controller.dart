import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../kameti/models/kameti_model.dart';
import '../../member/models/member_model.dart';
import '../../payment/models/payment_models.dart';
import '../models/lucky_draw_model.dart';

class LuckyDrawController extends StateNotifier<List<LuckyDrawModel>> {
  LuckyDrawController() : super(const []);

  LuckyDrawModel? getDrawByCycleId(String cycleId) {
    for (final draw in state) {
      if (draw.cycleId == cycleId && draw.status == LuckyDrawStatus.completed) {
        return draw;
      }
    }
    return null;
  }

  List<LuckyDrawModel> getDrawsByKametiId(String kametiId) {
    final draws = state.where((draw) => draw.kametiId == kametiId).toList();
    draws.sort((a, b) => a.cycleNumber.compareTo(b.cycleNumber));
    return draws;
  }

  bool hasDrawCompletedForCycle(String cycleId) =>
      getDrawByCycleId(cycleId) != null;

  DrawEligibilityResult getEligibleMembersForDraw({
    required KametiModel kameti,
    required PaymentCycleModel? cycle,
    required List<MemberModel> members,
    required List<MemberPaymentModel> payments,
  }) {
    final eligible = <MemberModel>[];
    final excluded = <MemberModel>[];
    final reasons = <String, String>{};

    for (final member
        in members.where((member) => member.kametiId == kameti.id)) {
      MemberPaymentModel? payment;
      if (cycle != null) {
        for (final item in payments) {
          if (item.cycleId == cycle.id && item.memberId == member.id) {
            payment = item;
            break;
          }
        }
      }
      String? reason;
      if (member.status == MemberStatus.removed) {
        reason = 'Member removed';
      } else if (member.status != MemberStatus.active) {
        reason = 'Member inactive';
      } else if (member.hasReceivedKameti) {
        reason = 'Already received kameti';
      } else if (payment == null) {
        reason = 'No payment record for current cycle';
      } else if (kameti.requirePaymentBeforeDraw &&
          payment.paymentStatus != PaymentStatus.paid) {
        reason = 'Payment not paid for current cycle';
      }

      if (reason == null) {
        eligible.add(member);
      } else {
        excluded.add(member);
        reasons[member.id] = reason;
      }
    }

    return DrawEligibilityResult(
      eligibleMembers: eligible,
      excludedMembers: excluded,
      exclusionReasons: reasons,
    );
  }

  String? validateDrawAvailability({
    required KametiModel kameti,
    required PaymentCycleModel? cycle,
    required DrawEligibilityResult eligibility,
  }) {
    if (kameti.type != KametiType.luckyDraw) {
      return 'Lucky draw is only available for Khulli Chhutti kametis.';
    }
    if (kameti.status == KametiStatus.draft) {
      return 'Start this kameti before running lucky draw.';
    }
    if (kameti.status != KametiStatus.active) {
      return 'Lucky draw is only available for active kametis.';
    }
    if (cycle == null) return 'No active payment cycle found.';
    if (hasDrawCompletedForCycle(cycle.id)) {
      return 'Draw already completed for this cycle.';
    }
    if (eligibility.eligibleMembers.isEmpty) {
      return 'No eligible members available for draw.';
    }
    return null;
  }

  MemberModel? runLuckyDraw({
    required KametiModel kameti,
    required PaymentCycleModel? cycle,
    required DrawEligibilityResult eligibility,
  }) {
    final error = validateDrawAvailability(
        kameti: kameti, cycle: cycle, eligibility: eligibility);
    if (error != null) return null;
    final members = eligibility.eligibleMembers;
    return members[Random.secure().nextInt(members.length)];
  }

  String? saveLuckyDrawResult({
    required KametiModel kameti,
    required PaymentCycleModel cycle,
    required MemberModel winner,
    required DrawEligibilityResult eligibility,
    required String createdBy,
    String notes = '',
  }) {
    if (hasDrawCompletedForCycle(cycle.id)) {
      return 'Draw already completed for this cycle.';
    }
    final now = DateTime.now();
    state = [
      LuckyDrawModel(
        id: '${cycle.id}-draw',
        kametiId: kameti.id,
        cycleId: cycle.id,
        cycleNumber: cycle.cycleNumber,
        winnerMemberId: winner.id,
        winnerName: winner.fullName,
        drawType: LuckyDrawType.luckyDraw,
        eligibleMemberIds:
            eligibility.eligibleMembers.map((member) => member.id).toList(),
        excludedMemberIds:
            eligibility.excludedMembers.map((member) => member.id).toList(),
        exclusionReasons: eligibility.exclusionReasons,
        totalEligibleMembers: eligibility.eligibleMembers.length,
        totalExcludedMembers: eligibility.excludedMembers.length,
        payoutAmount: cycle.expectedAmount,
        status: LuckyDrawStatus.completed,
        drawDate: now,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
        notes: notes,
      ),
      ...state,
    ];
    return null;
  }

  int getPendingDrawsCount({
    required List<KametiModel> kametis,
    required List<PaymentCycleModel> cycles,
  }) {
    var count = 0;
    for (final kameti in kametis.where((item) =>
        item.status == KametiStatus.active &&
        item.type == KametiType.luckyDraw)) {
      PaymentCycleModel? current;
      for (final cycle in cycles) {
        if (cycle.kametiId == kameti.id &&
            cycle.status == PaymentCycleStatus.current) {
          current = cycle;
          break;
        }
      }
      if (current != null && !hasDrawCompletedForCycle(current.id)) count++;
    }
    return count;
  }

  int getCompletedDrawsCount() =>
      state.where((draw) => draw.status == LuckyDrawStatus.completed).length;
}

final luckyDrawControllerProvider =
    StateNotifierProvider<LuckyDrawController, List<LuckyDrawModel>>((ref) {
  return LuckyDrawController();
});
