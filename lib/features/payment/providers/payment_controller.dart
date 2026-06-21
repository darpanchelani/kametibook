import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../kameti/models/kameti_model.dart';
import '../../member/models/member_model.dart';
import '../models/payment_models.dart';

class PaymentState {
  const PaymentState({
    this.cycles = const [],
    this.payments = const [],
  });

  final List<PaymentCycleModel> cycles;
  final List<MemberPaymentModel> payments;

  PaymentState copyWith({
    List<PaymentCycleModel>? cycles,
    List<MemberPaymentModel>? payments,
  }) {
    return PaymentState(
      cycles: cycles ?? this.cycles,
      payments: payments ?? this.payments,
    );
  }
}

class MarkPaymentPaidData {
  const MarkPaymentPaidData({
    required this.amountPaid,
    required this.paymentMethod,
    required this.paidAt,
    required this.proofImagePath,
    required this.note,
    required this.approvedBy,
  });

  final double amountPaid;
  final PaymentMethod paymentMethod;
  final DateTime paidAt;
  final String proofImagePath;
  final String note;
  final String approvedBy;
}

class PaymentController extends StateNotifier<PaymentState> {
  PaymentController() : super(const PaymentState());

  final DateFormat _monthFormat = DateFormat('MMMM yyyy');

  List<PaymentCycleModel> getCyclesByKametiId(String kametiId) {
    final cycles = state.cycles.where((cycle) => cycle.kametiId == kametiId).toList();
    cycles.sort((a, b) => a.cycleNumber.compareTo(b.cycleNumber));
    return cycles;
  }

  PaymentCycleModel? getCycle(String cycleId) {
    for (final cycle in state.cycles) {
      if (cycle.id == cycleId) return cycle;
    }
    return null;
  }

  List<MemberPaymentModel> getPaymentsByCycleId(String cycleId) {
    return state.payments.where((payment) => payment.cycleId == cycleId).toList();
  }

  List<MemberPaymentModel> getPaymentsByMemberId(String memberId) {
    final payments = state.payments.where((payment) => payment.memberId == memberId).toList();
    payments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return payments;
  }

  PaymentCycleModel? getCurrentCycle(String kametiId) {
    final cycles = getCyclesByKametiId(kametiId);
    for (final cycle in cycles) {
      if (cycle.status == PaymentCycleStatus.current) return cycle;
    }
    for (final cycle in cycles) {
      if (cycle.status == PaymentCycleStatus.overdue) return cycle;
    }
    for (final cycle in cycles) {
      if (cycle.status == PaymentCycleStatus.upcoming) return cycle;
    }
    return cycles.isEmpty ? null : cycles.last;
  }

  void generatePaymentCycles({
    required KametiModel kameti,
    required List<MemberModel> members,
  }) {
    if (kameti.status != KametiStatus.active) return;
    if (getCyclesByKametiId(kameti.id).isNotEmpty) return;

    final activeMembers = members
        .where((member) => member.kametiId == kameti.id && member.status == MemberStatus.active)
        .toList();
    if (activeMembers.isEmpty) return;

    final now = DateTime.now();
    final cycles = <PaymentCycleModel>[];
    final payments = <MemberPaymentModel>[];
    for (var index = 0; index < kameti.durationMonths; index++) {
      final monthDate = DateTime(kameti.startDate.year, kameti.startDate.month + index);
      final dueDate = DateTime(monthDate.year, monthDate.month, kameti.dueDay);
      final cycleId = '${kameti.id}-cycle-${index + 1}';
      final status = index == 0 ? PaymentCycleStatus.current : PaymentCycleStatus.upcoming;
      cycles.add(
        PaymentCycleModel(
          id: cycleId,
          kametiId: kameti.id,
          cycleNumber: index + 1,
          monthLabel: _monthFormat.format(monthDate),
          dueDate: dueDate,
          expectedAmount: kameti.monthlyAmount * activeMembers.length,
          collectedAmount: 0,
          pendingAmount: kameti.monthlyAmount * activeMembers.length,
          status: status,
          createdAt: now,
          updatedAt: now,
        ),
      );
      for (final member in activeMembers) {
        final paymentId = '$cycleId-${member.id}';
        payments.add(
          MemberPaymentModel(
            id: paymentId,
            kametiId: kameti.id,
            cycleId: cycleId,
            memberId: member.id,
            amountDue: kameti.monthlyAmount,
            amountPaid: 0,
            paymentStatus: PaymentStatus.pending,
            paymentMethod: null,
            proofImagePath: '',
            note: '',
            paidAt: null,
            approvedBy: '',
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }

    state = state.copyWith(
      cycles: [...state.cycles, ...cycles],
      payments: [...state.payments, ...payments],
    );
  }

  void generateMemberPaymentsForCycle({
    required KametiModel kameti,
    required PaymentCycleModel cycle,
    required List<MemberModel> members,
  }) {
    final now = DateTime.now();
    final additions = <MemberPaymentModel>[];
    for (final member in members.where((member) => member.status == MemberStatus.active)) {
      final paymentId = '${cycle.id}-${member.id}';
      final exists = state.payments.any((payment) => payment.id == paymentId);
      if (exists) continue;
      additions.add(
        MemberPaymentModel(
          id: paymentId,
          kametiId: kameti.id,
          cycleId: cycle.id,
          memberId: member.id,
          amountDue: kameti.monthlyAmount,
          amountPaid: 0,
          paymentStatus: PaymentStatus.pending,
          paymentMethod: null,
          proofImagePath: '',
          note: '',
          paidAt: null,
          approvedBy: '',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    if (additions.isEmpty) return;
    state = state.copyWith(payments: [...state.payments, ...additions]);
    recalculateCycleSummary(cycle.id);
  }

  double getCycleExpectedAmount(String cycleId) => getCycle(cycleId)?.expectedAmount ?? 0;
  double getCycleCollectedAmount(String cycleId) => getCycle(cycleId)?.collectedAmount ?? 0;
  double getCyclePendingAmount(String cycleId) => getCycle(cycleId)?.pendingAmount ?? 0;
  int getPaidMembersCount(String cycleId) => _count(cycleId, PaymentStatus.paid) + _count(cycleId, PaymentStatus.waived);
  int getPendingMembersCount(String cycleId) => _count(cycleId, PaymentStatus.pending);
  int getLateMembersCount(String cycleId) => _count(cycleId, PaymentStatus.late);
  int getRejectedMembersCount(String cycleId) => _count(cycleId, PaymentStatus.rejected);

  void markPaymentPaid(String paymentId, MarkPaymentPaidData data) {
    _updatePayment(
      paymentId,
      (payment) => payment.copyWith(
        amountPaid: data.amountPaid,
        paymentStatus: PaymentStatus.paid,
        paymentMethod: data.paymentMethod,
        proofImagePath: data.proofImagePath,
        note: data.note,
        paidAt: data.paidAt,
        approvedBy: data.approvedBy,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void markPaymentPending(String paymentId) {
    _updatePayment(
      paymentId,
      (payment) => payment.copyWith(
        amountPaid: 0,
        paymentStatus: PaymentStatus.pending,
        clearPaymentMethod: true,
        proofImagePath: '',
        note: '',
        clearPaidAt: true,
        approvedBy: '',
        updatedAt: DateTime.now(),
      ),
    );
  }

  void markPaymentLate(String paymentId, String note) {
    _updatePayment(
      paymentId,
      (payment) => payment.copyWith(
        amountPaid: 0,
        paymentStatus: PaymentStatus.late,
        clearPaymentMethod: true,
        note: note,
        clearPaidAt: true,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void rejectPayment(String paymentId, String reason) {
    _updatePayment(
      paymentId,
      (payment) => payment.copyWith(
        amountPaid: 0,
        paymentStatus: PaymentStatus.rejected,
        clearPaymentMethod: true,
        note: reason,
        clearPaidAt: true,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void updatePayment(String paymentId, MarkPaymentPaidData data) {
    markPaymentPaid(paymentId, data);
  }

  String? completeCycle(String cycleId) {
    final payments = getPaymentsByCycleId(cycleId);
    final hasOpenPayments = payments.any((payment) => !payment.countsAsPaid);
    if (hasOpenPayments) return 'Complete all member payments before closing this cycle.';
    _replaceCycle(cycleId, (cycle) => cycle.copyWith(status: PaymentCycleStatus.completed, updatedAt: DateTime.now()));
    return null;
  }

  void markCycleCurrent(String cycleId) {
    final target = getCycle(cycleId);
    if (target == null) return;
    state = state.copyWith(
      cycles: [
        for (final cycle in state.cycles)
          if (cycle.kametiId == target.kametiId && cycle.status != PaymentCycleStatus.completed)
            cycle.copyWith(
              status: cycle.id == cycleId ? PaymentCycleStatus.current : PaymentCycleStatus.upcoming,
              updatedAt: DateTime.now(),
            )
          else
            cycle,
      ],
    );
  }

  void recalculateCycleSummary(String cycleId) {
    final cycle = getCycle(cycleId);
    if (cycle == null) return;
    final payments = getPaymentsByCycleId(cycleId);
    final expected = payments.fold<double>(0, (total, payment) => total + payment.amountDue);
    final collected = payments.fold<double>(0, (total, payment) => total + payment.amountPaid);
    final pending = (expected - collected).clamp(0, expected).toDouble();
    _replaceCycle(
      cycleId,
      (item) => item.copyWith(
        expectedAmount: expected,
        collectedAmount: collected,
        pendingAmount: pending,
        updatedAt: DateTime.now(),
      ),
    );
  }

  int pendingPaymentsInCurrentCycles(List<KametiModel> kametis) {
    var count = 0;
    for (final kameti in kametis.where((item) => item.status == KametiStatus.active)) {
      final cycle = getCurrentCycle(kameti.id);
      if (cycle == null) continue;
      count += getPaymentsByCycleId(cycle.id).where((payment) {
        return payment.paymentStatus == PaymentStatus.pending ||
            payment.paymentStatus == PaymentStatus.late ||
            payment.paymentStatus == PaymentStatus.rejected;
      }).length;
    }
    return count;
  }

  double collectedInCurrentCycles(List<KametiModel> kametis) {
    var total = 0.0;
    for (final kameti in kametis.where((item) => item.status == KametiStatus.active)) {
      final cycle = getCurrentCycle(kameti.id);
      if (cycle == null) continue;
      total += cycle.collectedAmount;
    }
    return total;
  }

  void _updatePayment(String paymentId, MemberPaymentModel Function(MemberPaymentModel payment) update) {
    String? cycleId;
    state = state.copyWith(
      payments: [
        for (final payment in state.payments)
          if (payment.id == paymentId)
            update(payment).also((updated) => cycleId = updated.cycleId)
          else
            payment,
      ],
    );
    if (cycleId != null) recalculateCycleSummary(cycleId!);
  }

  void _replaceCycle(String cycleId, PaymentCycleModel Function(PaymentCycleModel cycle) update) {
    state = state.copyWith(
      cycles: [
        for (final cycle in state.cycles)
          if (cycle.id == cycleId) update(cycle) else cycle,
      ],
    );
  }

  int _count(String cycleId, PaymentStatus status) {
    return getPaymentsByCycleId(cycleId).where((payment) => payment.paymentStatus == status).length;
  }
}

extension _Also<T> on T {
  T also(void Function(T value) action) {
    action(this);
    return this;
  }
}

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, PaymentState>((ref) {
  return PaymentController();
});
