import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../kameti/models/kameti_model.dart';
import '../../member/models/member_model.dart';
import '../../payment/models/payment_models.dart';
import '../models/bidding_models.dart';

class BiddingState {
  const BiddingState({
    this.sessions = const [],
    this.bids = const [],
    this.adjustments = const [],
  });

  final List<BiddingSessionModel> sessions;
  final List<BidModel> bids;
  final List<DiscountAdjustmentModel> adjustments;

  BiddingState copyWith({
    List<BiddingSessionModel>? sessions,
    List<BidModel>? bids,
    List<DiscountAdjustmentModel>? adjustments,
  }) {
    return BiddingState(
      sessions: sessions ?? this.sessions,
      bids: bids ?? this.bids,
      adjustments: adjustments ?? this.adjustments,
    );
  }
}

class BiddingCompletionPreview {
  const BiddingCompletionPreview({
    required this.winningBid,
    required this.discountAmount,
    required this.adjustments,
  });

  final BidModel winningBid;
  final double discountAmount;
  final List<DiscountAdjustmentModel> adjustments;
}

class BiddingController extends StateNotifier<BiddingState> {
  BiddingController() : super(const BiddingState());

  BiddingSessionModel? getBiddingSessionByCycleId(String cycleId) {
    for (final session in state.sessions) {
      if (session.cycleId == cycleId) return session;
    }
    return null;
  }

  BiddingSessionModel? getSession(String sessionId) {
    for (final session in state.sessions) {
      if (session.id == sessionId) return session;
    }
    return null;
  }

  List<BiddingSessionModel> getBiddingSessionsByKametiId(String kametiId) {
    final sessions = state.sessions.where((session) => session.kametiId == kametiId).toList();
    sessions.sort((a, b) => a.cycleNumber.compareTo(b.cycleNumber));
    return sessions;
  }

  List<BidModel> getBidsBySessionId(String sessionId) {
    final session = getSession(sessionId);
    if (session == null) return const [];
    final bids = state.bids.where((bid) => bid.cycleId == session.cycleId).toList();
    bids.sort((a, b) {
      final amount = a.bidAmount.compareTo(b.bidAmount);
      if (amount != 0) return amount;
      return a.submittedAt.compareTo(b.submittedAt);
    });
    return bids;
  }

  List<DiscountAdjustmentModel> getAdjustmentsBySessionId(String sessionId) {
    return state.adjustments.where((item) => item.biddingSessionId == sessionId).toList();
  }

  List<DiscountAdjustmentModel> getAdjustmentsByMemberId(String memberId) {
    return state.adjustments.where((item) => item.memberId == memberId).toList();
  }

  BidModel? getLowestActiveBid(String sessionId) {
    final active = getBidsBySessionId(sessionId).where((bid) => bid.status == BidStatus.active).toList();
    return active.isEmpty ? null : active.first;
  }

  bool hasBiddingCompletedForCycle(String cycleId) {
    final session = getBiddingSessionByCycleId(cycleId);
    return session?.status == BiddingSessionStatus.completed;
  }

  BiddingEligibilityResult getEligibleMembersForBidding({
    required KametiModel kameti,
    required PaymentCycleModel? cycle,
    required List<MemberModel> members,
    required List<MemberPaymentModel> payments,
  }) {
    final eligible = <MemberModel>[];
    final excluded = <MemberModel>[];
    final reasons = <String, String>{};
    for (final member in members.where((member) => member.kametiId == kameti.id)) {
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
        reason = 'No payment record found';
      } else if (kameti.requirePaymentBeforeBidding && payment.paymentStatus != PaymentStatus.paid) {
        reason = 'Payment not paid for current cycle';
      }

      if (reason == null) {
        eligible.add(member);
      } else {
        excluded.add(member);
        reasons[member.id] = reason;
      }
    }
    return BiddingEligibilityResult(
      eligibleMembers: eligible,
      excludedMembers: excluded,
      exclusionReasons: reasons,
    );
  }

  String? validateAvailability({
    required KametiModel kameti,
    required PaymentCycleModel? cycle,
    required BiddingEligibilityResult eligibility,
  }) {
    if (kameti.type != KametiType.bidding) return 'Bidding is only available for auction kametis.';
    if (kameti.status == KametiStatus.draft) return 'Start this kameti before running bidding.';
    if (kameti.status != KametiStatus.active) return 'Bidding is only available for active kametis.';
    if (cycle == null) return 'No active payment cycle found.';
    if (hasBiddingCompletedForCycle(cycle.id)) return null;
    if (eligibility.eligibleMembers.isEmpty) return 'No eligible members available for bidding.';
    return null;
  }

  String? createBiddingSession({
    required KametiModel kameti,
    required PaymentCycleModel cycle,
    required int activeMembersCount,
    required String createdBy,
  }) {
    if (getBiddingSessionByCycleId(cycle.id) != null) return 'Bidding session already exists for this cycle.';
    final now = DateTime.now();
    final totalPool = kameti.monthlyAmount * activeMembersCount;
    final session = BiddingSessionModel(
      id: '${cycle.id}-bidding',
      kametiId: kameti.id,
      cycleId: cycle.id,
      cycleNumber: cycle.cycleNumber,
      status: BiddingSessionStatus.open,
      startTime: now,
      endTime: null,
      createdBy: createdBy,
      totalPoolAmount: totalPool,
      minimumBidAmount: kameti.minimumBidAmount ?? 0,
      maximumBidAmount: totalPool,
      winningBidId: '',
      winnerMemberId: '',
      winningAmount: 0,
      discountAmount: 0,
      discountDistributionType: kameti.discountDistributionType,
      notes: kameti.biddingRules,
      createdAt: now,
      updatedAt: now,
    );
    state = state.copyWith(sessions: [session, ...state.sessions]);
    return null;
  }

  String? submitBid({
    required BiddingSessionModel session,
    required MemberModel member,
    required double bidAmount,
    required String note,
    required BiddingEligibilityResult eligibility,
  }) {
    final validation = _validateBid(session: session, member: member, bidAmount: bidAmount, eligibility: eligibility);
    if (validation != null) return validation;
    final existing = _activeBidForMember(session, member.id);
    if (existing != null) {
      return updateBid(existing.id, bidAmount, note);
    }
    final now = DateTime.now();
    state = state.copyWith(
      bids: [
        BidModel(
          id: '${session.id}-${member.id}',
          kametiId: session.kametiId,
          cycleId: session.cycleId,
          cycleNumber: session.cycleNumber,
          memberId: member.id,
          memberName: member.fullName,
          bidAmount: bidAmount,
          status: BidStatus.active,
          note: note,
          submittedAt: now,
          updatedAt: now,
        ),
        ...state.bids,
      ],
    );
    return null;
  }

  String? updateBid(String bidId, double bidAmount, String note) {
    final bid = _getBid(bidId);
    if (bid == null) return 'Bid not found.';
    final session = getBiddingSessionByCycleId(bid.cycleId);
    if (session == null || session.status != BiddingSessionStatus.open) {
      return 'Bids cannot be updated after bidding is closed.';
    }
    if (bidAmount <= 0 || bidAmount >= session.totalPoolAmount) return 'Bid amount must be greater than 0 and less than total pool.';
    if (session.minimumBidAmount > 0 && bidAmount < session.minimumBidAmount) return 'Bid amount is lower than minimum bid.';
    state = state.copyWith(
      bids: [
        for (final item in state.bids)
          if (item.id == bidId) item.copyWith(bidAmount: bidAmount, note: note, updatedAt: DateTime.now()) else item,
      ],
    );
    return null;
  }

  String? withdrawBid(String bidId) {
    final bid = _getBid(bidId);
    if (bid == null) return 'Bid not found.';
    final session = getBiddingSessionByCycleId(bid.cycleId);
    if (session == null || session.status != BiddingSessionStatus.open) {
      return 'Bids cannot be withdrawn after bidding is closed.';
    }
    state = state.copyWith(
      bids: [
        for (final item in state.bids)
          if (item.id == bidId) item.copyWith(status: BidStatus.withdrawn, updatedAt: DateTime.now()) else item,
      ],
    );
    return null;
  }

  String? closeBiddingSession(String sessionId) {
    final session = getSession(sessionId);
    if (session == null) return 'Bidding session not found.';
    if (session.status != BiddingSessionStatus.open) return 'Only open bidding sessions can be closed.';
    if (getLowestActiveBid(sessionId) == null) return 'At least one active bid is required.';
    _replaceSession(sessionId, (item) => item.copyWith(status: BiddingSessionStatus.closed, endTime: DateTime.now(), updatedAt: DateTime.now()));
    return null;
  }

  BiddingCompletionPreview? buildCompletionPreview({
    required BiddingSessionModel session,
    required List<MemberModel> activeMembers,
  }) {
    final winner = getLowestActiveBid(session.id);
    if (winner == null) return null;
    final discount = calculateDiscount(session.totalPoolAmount, winner.bidAmount);
    final adjustments = calculateDiscountAdjustments(
      session: session,
      winningBid: winner,
      discountAmount: discount,
      activeMembers: activeMembers,
    );
    return BiddingCompletionPreview(winningBid: winner, discountAmount: discount, adjustments: adjustments);
  }

  String? completeBiddingSession({
    required String sessionId,
    required List<MemberModel> activeMembers,
  }) {
    final session = getSession(sessionId);
    if (session == null) return 'Bidding session not found.';
    if (session.status != BiddingSessionStatus.closed) return 'Close bidding before completing it.';
    if (session.status == BiddingSessionStatus.completed) return 'Bidding already completed.';
    final preview = buildCompletionPreview(session: session, activeMembers: activeMembers);
    if (preview == null) return 'No active bids available.';
    final now = DateTime.now();
    state = state.copyWith(
      sessions: [
        for (final item in state.sessions)
          if (item.id == sessionId)
            item.copyWith(
              status: BiddingSessionStatus.completed,
              winningBidId: preview.winningBid.id,
              winnerMemberId: preview.winningBid.memberId,
              winningAmount: preview.winningBid.bidAmount,
              discountAmount: preview.discountAmount,
              endTime: now,
              updatedAt: now,
            )
          else
            item,
      ],
      bids: [
        for (final bid in state.bids)
          if (bid.cycleId == session.cycleId && bid.status == BidStatus.active)
            bid.copyWith(
              status: bid.id == preview.winningBid.id ? BidStatus.winning : BidStatus.lost,
              updatedAt: now,
            )
          else
            bid,
      ],
      adjustments: [
        ...state.adjustments.where((item) => item.biddingSessionId != sessionId),
        ...preview.adjustments,
      ],
    );
    return null;
  }

  double calculateDiscount(double totalPoolAmount, double winningBid) => (totalPoolAmount - winningBid).clamp(0, totalPoolAmount).toDouble();

  List<DiscountAdjustmentModel> calculateDiscountAdjustments({
    required BiddingSessionModel session,
    required BidModel winningBid,
    required double discountAmount,
    required List<MemberModel> activeMembers,
  }) {
    if (discountAmount <= 0) return const [];
    final now = DateTime.now();
    if (session.discountDistributionType == DiscountDistributionType.groupWallet) {
      return [
        DiscountAdjustmentModel(
          id: '${session.id}-group-wallet',
          kametiId: session.kametiId,
          cycleId: session.cycleId,
          biddingSessionId: session.id,
          memberId: 'group_wallet',
          memberName: 'Group Wallet',
          adjustmentAmount: discountAmount,
          adjustmentType: AdjustmentType.groupWallet,
          applyToCycleId: '',
          status: AdjustmentStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
      ];
    }
    if (session.discountDistributionType == DiscountDistributionType.manualLater) {
      return [
        DiscountAdjustmentModel(
          id: '${session.id}-manual',
          kametiId: session.kametiId,
          cycleId: session.cycleId,
          biddingSessionId: session.id,
          memberId: 'manual',
          memberName: 'Manual Adjustment',
          adjustmentAmount: discountAmount,
          adjustmentType: AdjustmentType.manual,
          applyToCycleId: '',
          status: AdjustmentStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
      ];
    }
    final recipients = activeMembers.where((member) {
      if (session.discountDistributionType == DiscountDistributionType.equalToAllMembers) return true;
      return member.id != winningBid.memberId;
    }).toList();
    if (recipients.isEmpty) return const [];
    final totalCents = (discountAmount * 100).round();
    final baseCents = totalCents ~/ recipients.length;
    var remainder = totalCents - (baseCents * recipients.length);
    return [
      for (final member in recipients)
        DiscountAdjustmentModel(
          id: '${session.id}-${member.id}-discount',
          kametiId: session.kametiId,
          cycleId: session.cycleId,
          biddingSessionId: session.id,
          memberId: member.id,
          memberName: member.fullName,
          adjustmentAmount: (baseCents + (remainder-- > 0 ? 1 : 0)) / 100,
          adjustmentType: AdjustmentType.discountShare,
          applyToCycleId: '',
          status: AdjustmentStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
    ];
  }

  int getOpenBiddingsCount() => state.sessions.where((item) => item.status == BiddingSessionStatus.open).length;
  int getPendingBiddingResultsCount() => state.sessions.where((item) => item.status == BiddingSessionStatus.closed).length;
  int getCompletedBiddingsCount() => state.sessions.where((item) => item.status == BiddingSessionStatus.completed).length;
  double getTotalDiscountsGenerated() => state.sessions.fold(0, (total, item) => total + item.discountAmount);

  String? _validateBid({
    required BiddingSessionModel session,
    required MemberModel member,
    required double bidAmount,
    required BiddingEligibilityResult eligibility,
  }) {
    if (session.status != BiddingSessionStatus.open) return 'Bidding session must be open.';
    if (!eligibility.eligibleMembers.any((item) => item.id == member.id)) return 'This member is not eligible to bid.';
    if (bidAmount <= 0 || bidAmount >= session.totalPoolAmount) return 'Bid amount must be greater than 0 and less than total pool.';
    if (session.minimumBidAmount > 0 && bidAmount < session.minimumBidAmount) return 'Bid amount is lower than minimum bid.';
    return null;
  }

  BidModel? _activeBidForMember(BiddingSessionModel session, String memberId) {
    for (final bid in state.bids) {
      if (bid.cycleId == session.cycleId && bid.memberId == memberId && bid.status == BidStatus.active) return bid;
    }
    return null;
  }

  BidModel? _getBid(String bidId) {
    for (final bid in state.bids) {
      if (bid.id == bidId) return bid;
    }
    return null;
  }

  void _replaceSession(String sessionId, BiddingSessionModel Function(BiddingSessionModel session) update) {
    state = state.copyWith(
      sessions: [
        for (final session in state.sessions)
          if (session.id == sessionId) update(session) else session,
      ],
    );
  }
}

final biddingControllerProvider =
    StateNotifierProvider<BiddingController, BiddingState>((ref) {
  return BiddingController();
});
