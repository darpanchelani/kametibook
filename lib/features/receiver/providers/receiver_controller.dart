import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../kameti/models/kameti_model.dart';
import '../../member/models/member_model.dart';
import '../../payment/models/payment_models.dart';
import '../models/receiver_allocation_model.dart';

class ReceiverState {
  const ReceiverState({
    this.allocations = const [],
    this.fixedOrderSlots = const [],
  });

  final List<ReceiverAllocationModel> allocations;
  final List<FixedOrderSlotModel> fixedOrderSlots;

  ReceiverState copyWith({
    List<ReceiverAllocationModel>? allocations,
    List<FixedOrderSlotModel>? fixedOrderSlots,
  }) {
    return ReceiverState(
      allocations: allocations ?? this.allocations,
      fixedOrderSlots: fixedOrderSlots ?? this.fixedOrderSlots,
    );
  }
}

class ReceiverController extends StateNotifier<ReceiverState> {
  ReceiverController() : super(const ReceiverState());

  ReceiverAllocationModel? getCurrentCycleAllocation(String kametiId, String cycleId) {
    for (final allocation in state.allocations) {
      if (allocation.kametiId == kametiId &&
          allocation.cycleId == cycleId &&
          allocation.status == ReceiverAllocationStatus.confirmed) {
        return allocation;
      }
    }
    return null;
  }

  List<ReceiverAllocationModel> getAllocationsByKametiId(String kametiId) {
    final allocations = state.allocations.where((item) => item.kametiId == kametiId).toList();
    allocations.sort((a, b) => a.cycleNumber.compareTo(b.cycleNumber));
    return allocations;
  }

  List<ReceiverAllocationModel> getAllocationsByMemberId(String memberId) {
    return state.allocations.where((item) => item.memberId == memberId).toList();
  }

  bool hasReceiverConfirmedForCycle(String cycleId) {
    return state.allocations.any(
      (item) => item.cycleId == cycleId && item.status == ReceiverAllocationStatus.confirmed,
    );
  }

  ReceiverEligibilityResult getEligibleReceivers({
    required KametiModel kameti,
    required PaymentCycleModel? cycle,
    required ReceiverAllocationType allocationType,
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
      } else if (kameti.requirePaymentBeforeReceiving && payment.paymentStatus != PaymentStatus.paid) {
        reason = 'Payment not paid for current cycle';
      }

      if (reason == null) {
        eligible.add(member);
      } else {
        excluded.add(member);
        reasons[member.id] = reason;
      }
    }
    return ReceiverEligibilityResult(
      eligibleMembers: eligible,
      excludedMembers: excluded,
      exclusionReasons: reasons,
    );
  }

  String? confirmReceiverAllocation({
    required KametiModel kameti,
    required PaymentCycleModel cycle,
    required MemberModel member,
    required ReceiverAllocationType allocationType,
    required double amount,
    required String selectedBy,
    String sourceId = '',
    String notes = '',
  }) {
    if (kameti.status != KametiStatus.active) return 'Receiver can only be confirmed for active kametis.';
    if (hasReceiverConfirmedForCycle(cycle.id)) return 'Receiver already confirmed for this cycle.';
    if (member.hasReceivedKameti) return 'This member has already received kameti.';
    if (member.status != MemberStatus.active) return 'Only active members can receive kameti.';
    final now = DateTime.now();
    state = state.copyWith(
      allocations: [
        ReceiverAllocationModel(
          id: '${cycle.id}-receiver',
          kametiId: kameti.id,
          cycleId: cycle.id,
          cycleNumber: cycle.cycleNumber,
          memberId: member.id,
          memberName: member.fullName,
          memberPhone: member.phone,
          allocationType: allocationType,
          amount: amount,
          status: ReceiverAllocationStatus.confirmed,
          selectedBy: selectedBy,
          selectedAt: now,
          confirmedAt: now,
          notes: notes,
          sourceId: sourceId,
          createdAt: now,
          updatedAt: now,
        ),
        ...state.allocations,
      ],
    );
    return null;
  }

  String? cancelReceiverAllocation(String allocationId) {
    ReceiverAllocationModel? allocation;
    for (final item in state.allocations) {
      if (item.id == allocationId) {
        allocation = item;
        break;
      }
    }
    if (allocation == null) return 'Allocation not found.';
    if (allocation.status == ReceiverAllocationStatus.confirmed) return 'Confirmed allocation cannot be changed.';
    state = state.copyWith(
      allocations: [
        for (final item in state.allocations)
          if (item.id == allocationId)
            ReceiverAllocationModel(
              id: item.id,
              kametiId: item.kametiId,
              cycleId: item.cycleId,
              cycleNumber: item.cycleNumber,
              memberId: item.memberId,
              memberName: item.memberName,
              memberPhone: item.memberPhone,
              allocationType: item.allocationType,
              amount: item.amount,
              status: ReceiverAllocationStatus.cancelled,
              selectedBy: item.selectedBy,
              selectedAt: item.selectedAt,
              confirmedAt: item.confirmedAt,
              notes: item.notes,
              sourceId: item.sourceId,
              createdAt: item.createdAt,
              updatedAt: DateTime.now(),
            )
          else
            item,
      ],
    );
    return null;
  }

  String? createAllocationFromLuckyDraw({
    required KametiModel kameti,
    required PaymentCycleModel cycle,
    required MemberModel winner,
    required String drawId,
    required double amount,
    required String selectedBy,
  }) {
    if (hasReceiverConfirmedForCycle(cycle.id)) return null;
    return confirmReceiverAllocation(
      kameti: kameti,
      cycle: cycle,
      member: winner,
      allocationType: ReceiverAllocationType.luckyDraw,
      amount: amount,
      selectedBy: selectedBy,
      sourceId: drawId,
    );
  }

  String? createAllocationFromBiddingSession({
    required KametiModel kameti,
    required PaymentCycleModel cycle,
    required MemberModel winner,
    required String sessionId,
    required double amount,
    required String selectedBy,
  }) {
    if (hasReceiverConfirmedForCycle(cycle.id)) return null;
    return confirmReceiverAllocation(
      kameti: kameti,
      cycle: cycle,
      member: winner,
      allocationType: ReceiverAllocationType.bidding,
      amount: amount,
      selectedBy: selectedBy,
      sourceId: sessionId,
    );
  }

  List<FixedOrderSlotModel> getFixedOrderSlots(String kametiId) {
    final slots = state.fixedOrderSlots.where((slot) => slot.kametiId == kametiId).toList();
    slots.sort((a, b) => a.cycleNumber.compareTo(b.cycleNumber));
    return slots;
  }

  FixedOrderSlotModel? getFixedOrderSlot(String kametiId, int cycleNumber) {
    for (final slot in state.fixedOrderSlots) {
      if (slot.kametiId == kametiId && slot.cycleNumber == cycleNumber) return slot;
    }
    return null;
  }

  String? saveFixedOrder({
    required KametiModel kameti,
    required Map<int, MemberModel> assignments,
  }) {
    if (assignments.length != kameti.totalMembers) return 'Assign one member to each cycle.';
    final memberIds = assignments.values.map((member) => member.id).toSet();
    if (memberIds.length != assignments.length) return 'Each member can appear only once.';
    final now = DateTime.now();
    state = state.copyWith(
      fixedOrderSlots: [
        ...state.fixedOrderSlots.where((slot) => slot.kametiId != kameti.id),
        for (final entry in assignments.entries)
          FixedOrderSlotModel(
            id: '${kameti.id}-fixed-${entry.key}',
            kametiId: kameti.id,
            cycleNumber: entry.key,
            memberId: entry.value.id,
            memberName: entry.value.fullName,
            status: FixedOrderSlotStatus.pending,
            createdAt: now,
            updatedAt: now,
          ),
      ],
    );
    return null;
  }

  int getPendingReceiverConfirmationsCount({
    required List<KametiModel> kametis,
    required List<PaymentCycleModel> cycles,
  }) {
    var count = 0;
    for (final kameti in kametis.where((item) => item.status == KametiStatus.active)) {
      PaymentCycleModel? cycle;
      for (final item in cycles) {
        if (item.kametiId == kameti.id && item.status == PaymentCycleStatus.current) {
          cycle = item;
          break;
        }
      }
      if (cycle != null && !hasReceiverConfirmedForCycle(cycle.id)) count++;
    }
    return count;
  }

  int getConfirmedReceiversCount() {
    return state.allocations.where((item) => item.status == ReceiverAllocationStatus.confirmed).length;
  }

  int getCompletedAllocationCyclesCount(List<PaymentCycleModel> cycles) {
    var count = 0;
    for (final cycle in cycles.where((item) => item.status == PaymentCycleStatus.completed)) {
      if (hasReceiverConfirmedForCycle(cycle.id)) count++;
    }
    return count;
  }
}

final receiverControllerProvider =
    StateNotifierProvider<ReceiverController, ReceiverState>((ref) {
  return ReceiverController();
});
