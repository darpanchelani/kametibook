import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../models/kameti_model.dart';
import '../../member/providers/member_controller.dart';
import '../../lucky_draw/providers/lucky_draw_controller.dart';
import '../../bidding/models/bidding_models.dart';
import '../../bidding/providers/bidding_controller.dart';
import '../../payment/providers/payment_controller.dart';
import '../providers/kameti_controller.dart';
import '../widgets/kameti_card.dart';

class MyKametisScreen extends ConsumerWidget {
  const MyKametisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kametis = ref.watch(kametiControllerProvider);
    ref.watch(memberControllerProvider);
    ref.watch(paymentControllerProvider);
    ref.watch(luckyDrawControllerProvider);
    ref.watch(biddingControllerProvider);
    final memberController = ref.read(memberControllerProvider.notifier);
    final paymentController = ref.read(paymentControllerProvider.notifier);
    final drawController = ref.read(luckyDrawControllerProvider.notifier);
    final biddingController = ref.read(biddingControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('My Kametis')),
      body: SafeArea(
        child: kametis.isEmpty
            ? EmptyState(
                icon: Icons.groups_2_outlined,
                title: 'No kameti groups yet',
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
