import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bidding/models/bidding_models.dart';
import '../../payment/models/payment_models.dart';
import '../../receiver/models/receiver_allocation_model.dart';
import '../models/ledger_entry_model.dart';

class LedgerController extends StateNotifier<List<LedgerEntryModel>> {
  LedgerController() : super(const []);

  void createLedgerEntry(LedgerEntryModel entry) {
    if (state.any((item) => item.id == entry.id)) return;
    state = [entry, ...state];
  }

  void updateLedgerEntry(String entryId, LedgerEntryModel Function(LedgerEntryModel entry) update) {
    state = [
      for (final entry in state)
        if (entry.id == entryId) update(entry) else entry,
    ];
  }

  List<LedgerEntryModel> getLedgerEntriesByKametiId(String kametiId) {
    final entries = state.where((entry) => entry.kametiId == kametiId).toList();
    entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    return entries;
  }

  List<LedgerEntryModel> getLedgerEntriesByCycleId(String cycleId) {
    return state.where((entry) => entry.cycleId == cycleId).toList();
  }

  List<LedgerEntryModel> getLedgerEntriesByMemberId(String memberId) {
    return state.where((entry) => entry.memberId == memberId).toList();
  }

  LedgerEntryModel? getLedgerEntryByRelatedPaymentId(String paymentId) => _by((entry) => entry.relatedPaymentId == paymentId);
  LedgerEntryModel? getLedgerEntryByRelatedAllocationId(String allocationId) => _by((entry) => entry.relatedAllocationId == allocationId);
  LedgerEntryModel? getLedgerEntryByRelatedBiddingSessionId(String sessionId) => _by((entry) => entry.relatedBiddingSessionId == sessionId);

  void syncLedgerForKameti({
    required String kametiId,
    required List<MemberPaymentModel> payments,
    required List<ReceiverAllocationModel> allocations,
    required List<BiddingSessionModel> biddingSessions,
    required List<DiscountAdjustmentModel> discountAdjustments,
    String createdBy = 'Organizer',
  }) {
    final now = DateTime.now();
    for (final payment in payments.where((payment) => payment.kametiId == kametiId)) {
      final existing = getLedgerEntryByRelatedPaymentId(payment.id);
      if (payment.paymentStatus == PaymentStatus.paid) {
        createLedgerEntry(
          LedgerEntryModel(
            id: 'ledger-payment-${payment.id}',
            kametiId: payment.kametiId,
            cycleId: payment.cycleId,
            memberId: payment.memberId,
            relatedPaymentId: payment.id,
            relatedAllocationId: '',
            relatedBiddingSessionId: '',
            relatedDiscountAdjustmentId: '',
            entryType: LedgerEntryType.contribution,
            direction: LedgerDirection.moneyIn,
            amount: payment.amountPaid,
            title: 'Monthly contribution received',
            description: payment.note,
            paymentMethod: payment.paymentMethod,
            proofPath: payment.proofImagePath,
            status: LedgerStatus.confirmed,
            entryDate: payment.paidAt ?? payment.updatedAt,
            createdBy: createdBy,
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else if (existing != null && existing.status == LedgerStatus.confirmed) {
        updateLedgerEntry(existing.id, (entry) => entry.copyWith(status: LedgerStatus.reversed, updatedAt: now));
      }
    }

    for (final allocation in allocations.where((allocation) => allocation.kametiId == kametiId)) {
      createLedgerEntry(
        LedgerEntryModel(
          id: 'ledger-allocation-${allocation.id}',
          kametiId: allocation.kametiId,
          cycleId: allocation.cycleId,
          memberId: allocation.memberId,
          relatedPaymentId: '',
          relatedAllocationId: allocation.id,
          relatedBiddingSessionId: '',
          relatedDiscountAdjustmentId: '',
          entryType: LedgerEntryType.payout,
          direction: LedgerDirection.moneyOut,
          amount: allocation.amount,
          title: allocation.payoutStatus == PayoutStatus.confirmed ? 'Payout paid' : 'Payout pending',
          description: allocation.payoutNote,
          paymentMethod: _payoutToPaymentMethod(allocation.payoutMethod),
          proofPath: allocation.payoutProofPath,
          status: allocation.payoutStatus == PayoutStatus.confirmed ? LedgerStatus.confirmed : LedgerStatus.pending,
          entryDate: allocation.payoutPaidAt ?? allocation.confirmedAt ?? allocation.selectedAt,
          createdBy: allocation.selectedBy,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    for (final session in biddingSessions.where((session) => session.kametiId == kametiId && session.status == BiddingSessionStatus.completed)) {
      createLedgerEntry(
        LedgerEntryModel(
          id: 'ledger-bidding-discount-${session.id}',
          kametiId: session.kametiId,
          cycleId: session.cycleId,
          memberId: session.winnerMemberId,
          relatedPaymentId: '',
          relatedAllocationId: '',
          relatedBiddingSessionId: session.id,
          relatedDiscountAdjustmentId: '',
          entryType: LedgerEntryType.discountGenerated,
          direction: LedgerDirection.neutral,
          amount: session.discountAmount,
          title: 'Bidding discount generated',
          description: 'Winning amount created group saving/discount.',
          paymentMethod: null,
          proofPath: '',
          status: LedgerStatus.confirmed,
          entryDate: session.endTime ?? session.updatedAt,
          createdBy: session.createdBy,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    for (final adjustment in discountAdjustments.where((item) => item.kametiId == kametiId)) {
      createLedgerEntry(
        LedgerEntryModel(
          id: 'ledger-adjustment-${adjustment.id}',
          kametiId: adjustment.kametiId,
          cycleId: adjustment.cycleId,
          memberId: adjustment.memberId,
          relatedPaymentId: '',
          relatedAllocationId: '',
          relatedBiddingSessionId: adjustment.biddingSessionId,
          relatedDiscountAdjustmentId: adjustment.id,
          entryType: adjustment.adjustmentType == AdjustmentType.groupWallet ? LedgerEntryType.groupWallet : LedgerEntryType.discountAdjustment,
          direction: LedgerDirection.neutral,
          amount: adjustment.adjustmentAmount,
          title: 'Discount adjustment',
          description: adjustment.adjustmentType.label,
          paymentMethod: null,
          proofPath: '',
          status: LedgerStatus.confirmed,
          entryDate: adjustment.createdAt,
          createdBy: createdBy,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  void markPayoutLedgerPaid({
    required ReceiverAllocationModel allocation,
    required PaymentMethod method,
    required String proofPath,
    required String note,
    required DateTime paidAt,
  }) {
    final existing = getLedgerEntryByRelatedAllocationId(allocation.id);
    if (existing == null) return;
    updateLedgerEntry(
      existing.id,
      (entry) => entry.copyWith(
        status: LedgerStatus.confirmed,
        paymentMethod: method,
        proofPath: proofPath,
        description: note,
        entryDate: paidAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void addPenalty({
    required String kametiId,
    required String cycleId,
    required String memberId,
    required double amount,
    required String note,
    required String createdBy,
  }) {
    final now = DateTime.now();
    createLedgerEntry(
      LedgerEntryModel(
        id: 'ledger-penalty-${now.microsecondsSinceEpoch}',
        kametiId: kametiId,
        cycleId: cycleId,
        memberId: memberId,
        relatedPaymentId: '',
        relatedAllocationId: '',
        relatedBiddingSessionId: '',
        relatedDiscountAdjustmentId: '',
        entryType: LedgerEntryType.penalty,
        direction: LedgerDirection.moneyIn,
        amount: amount,
        title: 'Late payment penalty',
        description: note,
        paymentMethod: null,
        proofPath: '',
        status: LedgerStatus.confirmed,
        entryDate: now,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  LedgerSummary calculateGroupLedgerSummary(String kametiId) {
    return _summary(getLedgerEntriesByKametiId(kametiId));
  }

  LedgerSummary calculateCycleLedgerSummary(String cycleId) {
    return _summary(getLedgerEntriesByCycleId(cycleId));
  }

  LedgerSummary calculateMemberLedgerSummary(String memberId) {
    return _summary(getLedgerEntriesByMemberId(memberId));
  }

  void reverseLedgerEntry(String entryId) {
    updateLedgerEntry(entryId, (entry) => entry.copyWith(status: LedgerStatus.reversed, updatedAt: DateTime.now()));
  }

  LedgerEntryModel? _by(bool Function(LedgerEntryModel entry) test) {
    for (final entry in state) {
      if (test(entry)) return entry;
    }
    return null;
  }

  LedgerSummary _summary(List<LedgerEntryModel> entries) {
    final confirmed = entries.where((entry) => entry.status == LedgerStatus.confirmed).toList();
    final contributions = _sum(confirmed, LedgerEntryType.contribution);
    final payouts = _sum(confirmed, LedgerEntryType.payout);
    final discounts = _sum(confirmed, LedgerEntryType.discountGenerated);
    final penalties = _sum(confirmed, LedgerEntryType.penalty);
    final moneyIn = confirmed.where((entry) => entry.direction == LedgerDirection.moneyIn).fold<double>(0, (total, entry) => total + entry.amount);
    final moneyOut = confirmed.where((entry) => entry.direction == LedgerDirection.moneyOut).fold<double>(0, (total, entry) => total + entry.amount);
    return LedgerSummary(
      totalContributions: contributions,
      totalPayouts: payouts,
      totalDiscounts: discounts,
      totalPenalties: penalties,
      groupBalance: moneyIn - moneyOut,
    );
  }

  double _sum(List<LedgerEntryModel> entries, LedgerEntryType type) {
    return entries.where((entry) => entry.entryType == type).fold<double>(0, (total, entry) => total + entry.amount);
  }

  static PaymentMethod? _payoutToPaymentMethod(PayoutMethod? method) {
    return switch (method) {
      PayoutMethod.cash => PaymentMethod.cash,
      PayoutMethod.bankTransfer => PaymentMethod.bankTransfer,
      PayoutMethod.easypaisa => PaymentMethod.easypaisa,
      PayoutMethod.jazzcash => PaymentMethod.jazzcash,
      PayoutMethod.sadapay => PaymentMethod.sadapay,
      PayoutMethod.nayapay => PaymentMethod.nayapay,
      PayoutMethod.other => PaymentMethod.other,
      null => null,
    };
  }
}

final ledgerControllerProvider =
    StateNotifierProvider<LedgerController, List<LedgerEntryModel>>((ref) {
  return LedgerController();
});
