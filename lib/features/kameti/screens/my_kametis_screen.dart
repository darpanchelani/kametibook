import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/app_state_views.dart';
import '../models/kameti_model.dart';
import '../../auth/providers/auth_controller.dart';
import '../../member/providers/member_controller.dart';
import '../../lucky_draw/providers/lucky_draw_controller.dart';
import '../../bidding/models/bidding_models.dart';
import '../../bidding/providers/bidding_controller.dart';
import '../../ledger/providers/ledger_controller.dart';
import '../../payment/providers/payment_controller.dart';
import '../../receiver/providers/receiver_controller.dart';
import '../providers/kameti_controller.dart';
import '../widgets/kameti_card.dart';

class MyKametisScreen extends ConsumerWidget {
  const MyKametisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) {
      return const Scaffold(
        body: AppPermissionDeniedView(
          title: 'Login required',
          message: 'Please login with an active KametiBook account.',
        ),
      );
    }
    ref.watch(kametiControllerProvider);
    final kametis = ref.read(kametiControllerProvider.notifier).visibleToUser(user.id);
    ref.watch(memberControllerProvider);
    ref.watch(paymentControllerProvider);
    ref.watch(luckyDrawControllerProvider);
    ref.watch(biddingControllerProvider);
    ref.watch(receiverControllerProvider);
    ref.watch(ledgerControllerProvider);
    final memberController = ref.read(memberControllerProvider.notifier);
    final paymentController = ref.read(paymentControllerProvider.notifier);
    final drawController = ref.read(luckyDrawControllerProvider.notifier);
    final biddingController = ref.read(biddingControllerProvider.notifier);
    final receiverController = ref.read(receiverControllerProvider.notifier);
    final ledgerController = ref.read(ledgerControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('My Kametis')),
      body: SafeArea(
        child: kametis.isEmpty
            ? EmptyState(
                icon: Icons.groups_2_outlined,
                title: 'Your KametiBook is empty. Create or join your first kameti.',
                action: AppButton(
                  label: 'Create Kameti',
                  icon: Icons.add,
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.createKameti),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final kameti = kametis[index];
                  final cycle = paymentController.getCurrentCycle(kameti.id);
                  final draw = cycle == null ? null : drawController.getDrawByCycleId(cycle.id);
                  final bidding = cycle == null ? null : biddingController.getBiddingSessionByCycleId(cycle.id);
                  final lowestBid = bidding == null ? null : biddingController.getLowestActiveBid(bidding.id);
                  final allocation = cycle == null ? null : receiverController.getCurrentCycleAllocation(kameti.id, cycle.id);
                  final balance = ledgerController.calculateGroupLedgerSummary(kameti.id).groupBalance;
                  return KametiCard(
                    kameti: kameti,
                    activeMembersCount: memberController.getActiveMembersCount(kameti.id),
                    currentCycleLabel: cycle == null ? null : 'Month ${cycle.cycleNumber}',
                    paidCount: cycle == null ? null : paymentController.getPaidMembersCount(cycle.id),
                    pendingCount: cycle == null ? null : paymentController.getPendingMembersCount(cycle.id),
                    collectedAmount: cycle?.collectedAmount,
                    expectedAmount: cycle?.expectedAmount,
                    drawStatusText: kameti.type == KametiType.luckyDraw && cycle != null
                        ? draw == null
                            ? 'Draw: Pending'
                            : 'Winner: ${draw.winnerName}'
                        : null,
                    biddingStatusText: kameti.type == KametiType.bidding && cycle != null
                        ? bidding == null
                            ? 'Bidding: Not Started'
                            : bidding.status == BiddingSessionStatus.completed
                                ? 'Winner: ${biddingController.getBidsBySessionId(bidding.id).where((bid) => bid.id == bidding.winningBidId).map((bid) => bid.memberName).join()} | Discount: ${bidding.discountAmount.toStringAsFixed(0)}'
                                : lowestBid == null
                                    ? 'Bidding: ${bidding.status.label}'
                                    : 'Bidding: ${bidding.status.label} | Lowest: ${lowestBid.bidAmount.toStringAsFixed(0)}'
                        : null,
                    receiverStatusText: cycle == null
                        ? null
                        : allocation == null
                            ? 'Receiver: Pending'
                            : 'Receiver: ${allocation.memberName} | Payout: ${allocation.payoutStatus.label} | Balance: ${balance.toStringAsFixed(0)}',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.kametiDetails, arguments: kameti.id),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: kametis.length,
              ),
      ),
      floatingActionButton: kametis.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.createKameti),
              child: const Icon(Icons.add),
            ),
    );
  }
}
