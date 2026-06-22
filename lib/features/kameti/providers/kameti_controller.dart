import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/kameti_model.dart';

class KametiController extends StateNotifier<List<KametiModel>> {
  KametiController() : super(const []);

  void createKameti(KametiModel kameti) {
    state = [kameti, ...state];
  }

  List<KametiModel> visibleToUser(String userId) {
    if (userId.isEmpty) return const [];
    return state
        .where(
          (kameti) =>
              kameti.ownerUserId == userId ||
              kameti.memberUserIds.contains(userId),
        )
        .toList();
  }

  bool canViewKameti(String kametiId, String userId) {
    final kameti = byId(kametiId);
    if (kameti == null || userId.isEmpty) return false;
    return kameti.ownerUserId == userId || kameti.memberUserIds.contains(userId);
  }

  bool canManageKameti(String kametiId, String userId) {
    final kameti = byId(kametiId);
    if (kameti == null || userId.isEmpty) return false;
    return kameti.ownerUserId == userId;
  }

  void addMemberUser(String kametiId, String userId) {
    if (userId.isEmpty) return;
    state = [
      for (final kameti in state)
        if (kameti.id == kametiId && !kameti.memberUserIds.contains(userId))
          kameti.copyWith(memberUserIds: [...kameti.memberUserIds, userId])
        else
          kameti,
    ];
  }

  KametiModel? byId(String id) {
    for (final kameti in state) {
      if (kameti.id == id) return kameti;
    }
    return null;
  }

  void updateStatus(String id, KametiStatus status) {
    state = [
      for (final kameti in state)
        if (kameti.id == id) kameti.copyWith(status: status) else kameti,
    ];
  }

  void updateRequirePaymentBeforeDraw(String id, bool value) {
    state = [
      for (final kameti in state)
        if (kameti.id == id) kameti.copyWith(requirePaymentBeforeDraw: value) else kameti,
    ];
  }

  void updateRequirePaymentBeforeBidding(String id, bool value) {
    state = [
      for (final kameti in state)
        if (kameti.id == id) kameti.copyWith(requirePaymentBeforeBidding: value) else kameti,
    ];
  }

  void updateDiscountDistributionType(String id, DiscountDistributionType value) {
    state = [
      for (final kameti in state)
        if (kameti.id == id) kameti.copyWith(discountDistributionType: value) else kameti,
    ];
  }

  void updateBiddingRules({
    required String id,
    double? minimumBidAmount,
    required String biddingRules,
  }) {
    state = [
      for (final kameti in state)
        if (kameti.id == id)
          kameti.copyWith(minimumBidAmount: minimumBidAmount, biddingRules: biddingRules)
        else
          kameti,
    ];
  }

  void updateReceiverSettings({
    required String id,
    bool? requirePaymentBeforeReceiving,
    bool? ownerReceivesFirstCycle,
    AfterOwnerAllocationMode? afterOwnerAllocationMode,
  }) {
    state = [
      for (final kameti in state)
        if (kameti.id == id)
          kameti.copyWith(
            requirePaymentBeforeReceiving: requirePaymentBeforeReceiving,
            ownerReceivesFirstCycle: ownerReceivesFirstCycle,
            afterOwnerAllocationMode: afterOwnerAllocationMode,
          )
        else
          kameti,
    ];
  }

  void updateReminderSettings({
    required String id,
    required bool remindersEnabled,
    required int paymentReminderDaysBefore,
    required bool paymentReminderOnDueDate,
    required bool overdueReminderEnabled,
    required OverdueReminderFrequency overdueReminderFrequency,
    required bool payoutProofReminderEnabled,
    required bool receiverPendingReminderEnabled,
    required bool biddingReminderEnabled,
    required bool luckyDrawReminderEnabled,
    required bool quietHoursEnabled,
    required String quietHoursStart,
    required String quietHoursEnd,
  }) {
    state = [
      for (final kameti in state)
        if (kameti.id == id)
          kameti.copyWith(
            remindersEnabled: remindersEnabled,
            paymentReminderDaysBefore: paymentReminderDaysBefore,
            paymentReminderOnDueDate: paymentReminderOnDueDate,
            overdueReminderEnabled: overdueReminderEnabled,
            overdueReminderFrequency: overdueReminderFrequency,
            payoutProofReminderEnabled: payoutProofReminderEnabled,
            receiverPendingReminderEnabled: receiverPendingReminderEnabled,
            biddingReminderEnabled: biddingReminderEnabled,
            luckyDrawReminderEnabled: luckyDrawReminderEnabled,
            quietHoursEnabled: quietHoursEnabled,
            quietHoursStart: quietHoursStart,
            quietHoursEnd: quietHoursEnd,
          )
        else
          kameti,
    ];
  }
}

final kametiControllerProvider =
    StateNotifierProvider<KametiController, List<KametiModel>>((ref) {
  return KametiController();
});
