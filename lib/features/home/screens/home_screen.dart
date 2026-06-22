import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/app_state_views.dart';
import '../../../core/widgets/summary_card.dart';
import '../../auth/providers/auth_controller.dart';
import '../../kameti/models/kameti_model.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../../kameti/widgets/kameti_card.dart';
import '../../member/providers/member_controller.dart';
import '../../notifications/providers/notification_controller.dart';
import '../../notifications/widgets/alert_banner.dart';
import '../../lucky_draw/providers/lucky_draw_controller.dart';
import '../../bidding/models/bidding_models.dart';
import '../../bidding/providers/bidding_controller.dart';
import '../../ledger/providers/ledger_controller.dart';
import '../../payment/providers/payment_controller.dart';
import '../../receiver/providers/receiver_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
    ref.watch(notificationControllerProvider);
    final activeCount = kametis.where((kameti) => kameti.status == KametiStatus.active).length;
    final draftCount = kametis.where((kameti) => kameti.status == KametiStatus.draft).length;
    final memberController = ref.read(memberControllerProvider.notifier);
    final paymentController = ref.read(paymentControllerProvider.notifier);
    final drawController = ref.read(luckyDrawControllerProvider.notifier);
    final biddingController = ref.read(biddingControllerProvider.notifier);
    final receiverController = ref.read(receiverControllerProvider.notifier);
    final ledgerController = ref.read(ledgerControllerProvider.notifier);
    final pendingPayments = paymentController.pendingPaymentsInCurrentCycles(kametis);
    final collectedThisMonth = paymentController.collectedInCurrentCycles(kametis);
    final pendingDraws = drawController.getPendingDrawsCount(
      kametis: kametis,
      cycles: ref.watch(paymentControllerProvider).cycles,
    );
    final completedDraws = drawController.getCompletedDrawsCount();
    final openBiddings = biddingController.getOpenBiddingsCount();
    final pendingBiddingResults = biddingController.getPendingBiddingResultsCount();
    final completedBiddings = biddingController.getCompletedBiddingsCount();
    final totalDiscounts = biddingController.getTotalDiscountsGenerated();
    final pendingReceivers = receiverController.getPendingReceiverConfirmationsCount(
      kametis: kametis,
      cycles: ref.watch(paymentControllerProvider).cycles,
    );
    final confirmedReceivers = receiverController.getConfirmedReceiversCount();
    final completedAllocationCycles = receiverController.getCompletedAllocationCyclesCount(ref.watch(paymentControllerProvider).cycles);
    final allSummary = kametis.fold(
      0.0,
      (total, kameti) => total + ledgerController.calculateGroupLedgerSummary(kameti.id).groupBalance,
    );
    final totalCollected = kametis.fold(
      0.0,
      (total, kameti) => total + ledgerController.calculateGroupLedgerSummary(kameti.id).totalContributions,
    );
    final totalPayouts = kametis.fold(
      0.0,
      (total, kameti) => total + ledgerController.calculateGroupLedgerSummary(kameti.id).totalPayouts,
    );
    final pendingPayoutProofs = kametis.fold(
      0,
      (total, kameti) => total + receiverController.getPendingPayoutProofs(kameti.id),
    );
    final userId = user.id;
    _runNotificationChecks(ref, userId);
    final unreadNotifications = ref.read(notificationControllerProvider.notifier).getUnreadCount(userId);
    final urgentAlerts = ref.read(notificationControllerProvider.notifier).getUrgentCount(userId);
    final recent = kametis.take(3).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Assalam o Alaikum, ${user.fullName}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width > 520 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.15,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                SummaryCard(title: 'Active Kametis', value: '$activeCount', icon: Icons.play_circle_outline),
                SummaryCard(
                  title: 'Draft Kametis',
                  value: '$draftCount',
                  icon: Icons.edit_note_outlined,
                  color: Colors.teal.shade700,
                ),
                SummaryCard(title: 'Pending Payments', value: '$pendingPayments', icon: Icons.pending_actions_outlined),
                SummaryCard(
                  title: 'Pending Draws',
                  value: '$pendingDraws',
                  icon: Icons.casino_outlined,
                  color: Colors.blue.shade700,
                ),
                SummaryCard(
                  title: 'Completed Draws',
                  value: '$completedDraws',
                  icon: Icons.emoji_events_outlined,
                  color: Colors.indigo.shade700,
                ),
                SummaryCard(
                  title: 'Collected This Month',
                  value: CurrencyFormatter.pkr(collectedThisMonth),
                  icon: Icons.payments_outlined,
                  color: Colors.green.shade700,
                ),
                SummaryCard(title: 'Open Biddings', value: '$openBiddings', icon: Icons.gavel_outlined),
                SummaryCard(title: 'Pending Bidding Results', value: '$pendingBiddingResults', icon: Icons.pending_outlined),
                SummaryCard(title: 'Completed Biddings', value: '$completedBiddings', icon: Icons.lock_outline),
                SummaryCard(
                  title: 'Total Discounts',
                  value: CurrencyFormatter.pkr(totalDiscounts),
                  icon: Icons.savings_outlined,
                  color: Colors.purple.shade700,
                ),
                SummaryCard(title: 'Pending Receivers', value: '$pendingReceivers', icon: Icons.person_search_outlined),
                SummaryCard(title: 'Confirmed Receivers', value: '$confirmedReceivers', icon: Icons.person_pin_circle_outlined),
                SummaryCard(title: 'Allocation Cycles', value: '$completedAllocationCycles', icon: Icons.task_alt_outlined),
                SummaryCard(title: 'Pending Payout Proofs', value: '$pendingPayoutProofs', icon: Icons.upload_file_outlined),
                SummaryCard(title: 'Total Collected', value: CurrencyFormatter.pkr(totalCollected), icon: Icons.add_card_outlined),
                SummaryCard(title: 'Total Payouts', value: CurrencyFormatter.pkr(totalPayouts), icon: Icons.outbound_outlined),
                SummaryCard(title: 'Group Balance', value: CurrencyFormatter.pkr(allSummary), icon: Icons.account_balance_outlined),
                SummaryCard(title: 'Unread Alerts', value: '$unreadNotifications', icon: Icons.notifications_active_outlined),
                SummaryCard(title: 'Urgent Alerts', value: '$urgentAlerts', icon: Icons.warning_amber_outlined, color: Colors.red.shade700),
              ],
            ),
            if (urgentAlerts > 0) ...[
              const SizedBox(height: 12),
              AlertBanner(
                title: '$urgentAlerts urgent alert(s)',
                message: 'Payments, payouts, receivers, or ledger records need review.',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.main, arguments: 2),
              ),
            ],
            const SizedBox(height: 18),
            AppButton(
              label: 'View Notifications',
              icon: Icons.notifications_outlined,
              isOutlined: true,
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.main, arguments: 2),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Create New Kameti',
              icon: Icons.add,
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.createKameti),
            ),
            const SizedBox(height: 24),
            Text(
              'My Recent Kametis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (recent.isEmpty)
              const EmptyState(
                icon: Icons.savings_outlined,
                title: 'Your KametiBook is empty. Create or join your first kameti.',
              )
            else
              ...recent.map(
                (kameti) {
                  final cycle = paymentController.getCurrentCycle(kameti.id);
                  final draw = cycle == null ? null : drawController.getDrawByCycleId(cycle.id);
                  final bidding = cycle == null ? null : biddingController.getBiddingSessionByCycleId(cycle.id);
                  final lowestBid = bidding == null ? null : biddingController.getLowestActiveBid(bidding.id);
                  final allocation = cycle == null ? null : receiverController.getCurrentCycleAllocation(kameti.id, cycle.id);
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
                                ? 'Winner: ${biddingController.getBidsBySessionId(bidding.id).where((bid) => bid.id == bidding.winningBidId).map((bid) => bid.memberName).join()} | Discount: ${CurrencyFormatter.pkr(bidding.discountAmount)}'
                                : lowestBid == null
                                    ? 'Bidding: ${bidding.status.label}'
                                    : 'Bidding: ${bidding.status.label} | Lowest: ${CurrencyFormatter.pkr(lowestBid.bidAmount)}'
                        : null,
                    receiverStatusText: cycle == null
                        ? null
                        : allocation == null
                            ? 'Receiver: Pending'
                            : 'Receiver: ${allocation.memberName}',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.kametiDetails, arguments: kameti.id),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _runNotificationChecks(WidgetRef ref, String userId) {
    final notificationController = ref.read(notificationControllerProvider.notifier);
    final kametis = ref.read(kametiControllerProvider.notifier).visibleToUser(userId);
    final cycles = ref.read(paymentControllerProvider).cycles;
    final payments = ref.read(paymentControllerProvider).payments;
    final members = ref.read(memberControllerProvider);
    final allocations = ref.read(receiverControllerProvider).allocations;
    for (final kameti in kametis) {
      notificationController.generateScheduledRemindersForKameti(
        userId: userId,
        kameti: kameti,
        cycles: cycles,
        payments: payments,
        members: members,
      );
    }
    notificationController.processDueScheduledNotifications();
    notificationController.checkOverduePayments(userId: userId, kametis: kametis, cycles: cycles, payments: payments, members: members);
    notificationController.checkPendingPayoutProofs(userId: userId, kametis: kametis, allocations: allocations);
    notificationController.checkPendingReceivers(userId: userId, kametis: kametis, cycles: cycles, allocations: allocations);
    notificationController.checkPendingBiddings(userId: userId, kametis: kametis, cycles: cycles, sessions: ref.read(biddingControllerProvider).sessions);
  }
}
