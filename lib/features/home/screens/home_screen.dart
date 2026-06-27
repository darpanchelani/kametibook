import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/app_state_views.dart';
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
    final kametis =
        ref.read(kametiControllerProvider.notifier).visibleToUser(user.id);
    ref.watch(memberControllerProvider);
    ref.watch(paymentControllerProvider);
    ref.watch(luckyDrawControllerProvider);
    ref.watch(biddingControllerProvider);
    ref.watch(receiverControllerProvider);
    ref.watch(ledgerControllerProvider);
    ref.watch(notificationControllerProvider);
    final activeCount =
        kametis.where((kameti) => kameti.status == KametiStatus.active).length;
    final draftCount =
        kametis.where((kameti) => kameti.status == KametiStatus.draft).length;
    final memberController = ref.read(memberControllerProvider.notifier);
    final paymentController = ref.read(paymentControllerProvider.notifier);
    final drawController = ref.read(luckyDrawControllerProvider.notifier);
    final biddingController = ref.read(biddingControllerProvider.notifier);
    final receiverController = ref.read(receiverControllerProvider.notifier);
    final ledgerController = ref.read(ledgerControllerProvider.notifier);
    final pendingPayments =
        paymentController.pendingPaymentsInCurrentCycles(kametis);
    final collectedThisMonth =
        paymentController.collectedInCurrentCycles(kametis);
    final pendingDraws = drawController.getPendingDrawsCount(
      kametis: kametis,
      cycles: ref.watch(paymentControllerProvider).cycles,
    );
    final completedDraws = drawController.getCompletedDrawsCount();
    final openBiddings = biddingController.getOpenBiddingsCount();
    final pendingBiddingResults =
        biddingController.getPendingBiddingResultsCount();
    final completedBiddings = biddingController.getCompletedBiddingsCount();
    final totalDiscounts = biddingController.getTotalDiscountsGenerated();
    final pendingReceivers =
        receiverController.getPendingReceiverConfirmationsCount(
      kametis: kametis,
      cycles: ref.watch(paymentControllerProvider).cycles,
    );
    final confirmedReceivers = receiverController.getConfirmedReceiversCount();
    final completedAllocationCycles =
        receiverController.getCompletedAllocationCyclesCount(
            ref.watch(paymentControllerProvider).cycles);
    final allSummary = kametis.fold(
      0.0,
      (total, kameti) =>
          total +
          ledgerController.calculateGroupLedgerSummary(kameti.id).groupBalance,
    );
    final totalCollected = kametis.fold(
      0.0,
      (total, kameti) =>
          total +
          ledgerController
              .calculateGroupLedgerSummary(kameti.id)
              .totalContributions,
    );
    final totalPayouts = kametis.fold(
      0.0,
      (total, kameti) =>
          total +
          ledgerController.calculateGroupLedgerSummary(kameti.id).totalPayouts,
    );
    final pendingPayoutProofs = kametis.fold(
      0,
      (total, kameti) =>
          total + receiverController.getPendingPayoutProofs(kameti.id),
    );
    final userId = user.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) _runNotificationChecks(ref, userId);
    });
    final unreadNotifications = ref
        .read(notificationControllerProvider.notifier)
        .getUnreadCount(userId);
    final urgentAlerts = ref
        .read(notificationControllerProvider.notifier)
        .getUrgentCount(userId);
    final recent = kametis.take(3).toList();
    final organizedCount =
        kametis.where((kameti) => kameti.ownerUserId == user.id).length;
    final joinedCount = kametis.length - organizedCount;
    final actionCount = pendingPayments +
        pendingPayoutProofs +
        pendingReceivers +
        pendingBiddingResults +
        pendingDraws;

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HomeHeroCard(
              userName: user.fullName,
              activeCount: activeCount,
              draftCount: draftCount,
              joinedCount: joinedCount,
              balance: allSummary,
              actionCount: actionCount,
            ),
            const SizedBox(height: 16),
            _HomeActionGrid(
              onCreateKameti: () =>
                  Navigator.of(context).pushNamed(AppRoutes.createKameti),
              onNotifications: () =>
                  Navigator.of(context).pushNamed(AppRoutes.main, arguments: 3),
              onMyKametis: () =>
                  Navigator.of(context).pushNamed(AppRoutes.main, arguments: 1),
            ),
            const SizedBox(height: 18),
            _FocusSection(
              pendingPayments: pendingPayments,
              pendingPayoutProofs: pendingPayoutProofs,
              pendingReceivers: pendingReceivers,
              pendingDraws: pendingDraws,
              openBiddings: openBiddings,
              unreadNotifications: unreadNotifications,
              urgentAlerts: urgentAlerts,
              onNotifications: () =>
                  Navigator.of(context).pushNamed(AppRoutes.main, arguments: 3),
            ),
            const SizedBox(height: 18),
            _FinanceSnapshot(
              collectedThisMonth: collectedThisMonth,
              totalCollected: totalCollected,
              totalPayouts: totalPayouts,
              groupBalance: allSummary,
            ),
            const SizedBox(height: 18),
            _InsightStrip(
              completedDraws: completedDraws,
              completedBiddings: completedBiddings,
              confirmedReceivers: confirmedReceivers,
              completedAllocationCycles: completedAllocationCycles,
              totalDiscounts: totalDiscounts,
            ),
            if (urgentAlerts > 0) ...[
              const SizedBox(height: 18),
              AlertBanner(
                title: '$urgentAlerts urgent alert(s)',
                message:
                    'Payments, payouts, receivers, or ledger records need review.',
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.main, arguments: 3),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'My Recent Kametis',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (recent.isEmpty)
              const EmptyState(
                icon: Icons.savings_outlined,
                title:
                    'Your KametiBook is empty. Create or join your first kameti.',
              )
            else
              ...recent.map(
                (kameti) {
                  final cycle = paymentController.getCurrentCycle(kameti.id);
                  final draw = cycle == null
                      ? null
                      : drawController.getDrawByCycleId(cycle.id);
                  final bidding = cycle == null
                      ? null
                      : biddingController.getBiddingSessionByCycleId(cycle.id);
                  final lowestBid = bidding == null
                      ? null
                      : biddingController.getLowestActiveBid(bidding.id);
                  final allocation = cycle == null
                      ? null
                      : receiverController.getCurrentCycleAllocation(
                          kameti.id, cycle.id);
                  return KametiCard(
                    kameti: kameti,
                    activeMembersCount:
                        memberController.getActiveMembersCount(kameti.id),
                    currentCycleLabel:
                        cycle == null ? null : 'Month ${cycle.cycleNumber}',
                    paidCount: cycle == null
                        ? null
                        : paymentController.getPaidMembersCount(cycle.id),
                    pendingCount: cycle == null
                        ? null
                        : paymentController.getPendingMembersCount(cycle.id),
                    collectedAmount: cycle?.collectedAmount,
                    expectedAmount: cycle?.expectedAmount,
                    drawStatusText:
                        kameti.type == KametiType.luckyDraw && cycle != null
                            ? draw == null
                                ? 'Draw: Pending'
                                : 'Winner: ${draw.winnerName}'
                            : null,
                    biddingStatusText: kameti.type == KametiType.bidding &&
                            cycle != null
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
                    onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.kametiDetails,
                        arguments: kameti.id),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _runNotificationChecks(WidgetRef ref, String userId) {
    final notificationController =
        ref.read(notificationControllerProvider.notifier);
    final kametis =
        ref.read(kametiControllerProvider.notifier).visibleToUser(userId);
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
    notificationController.checkOverduePayments(
        userId: userId,
        kametis: kametis,
        cycles: cycles,
        payments: payments,
        members: members);
    notificationController.checkPendingPayoutProofs(
        userId: userId, kametis: kametis, allocations: allocations);
    notificationController.checkPendingReceivers(
        userId: userId,
        kametis: kametis,
        cycles: cycles,
        allocations: allocations);
    notificationController.checkPendingBiddings(
        userId: userId,
        kametis: kametis,
        cycles: cycles,
        sessions: ref.read(biddingControllerProvider).sessions);
  }
}

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({
    required this.userName,
    required this.activeCount,
    required this.draftCount,
    required this.joinedCount,
    required this.balance,
    required this.actionCount,
  });

  final String userName;
  final int activeCount;
  final int draftCount;
  final int joinedCount;
  final double balance;
  final int actionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = userName.trim().split(RegExp(r'\s+')).first;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF087F5B),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087F5B).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.white),
              ),
              const Spacer(),
              _HeroBadge(
                icon: actionCount > 0
                    ? Icons.priority_high_rounded
                    : Icons.check_rounded,
                label:
                    actionCount > 0 ? '$actionCount needs review' : 'All clear',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Hello, $firstName',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Here is your KametiBook overview.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            CurrencyFormatter.pkr(balance),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Current group balance',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(label: 'Active', value: '$activeCount'),
              ),
              Expanded(
                child: _HeroMetric(label: 'Draft', value: '$draftCount'),
              ),
              Expanded(
                child: _HeroMetric(label: 'Joined', value: '$joinedCount'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActionGrid extends StatelessWidget {
  const _HomeActionGrid({
    required this.onCreateKameti,
    required this.onNotifications,
    required this.onMyKametis,
  });

  final VoidCallback onCreateKameti;
  final VoidCallback onNotifications;
  final VoidCallback onMyKametis;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            title: 'Create',
            subtitle: 'New group',
            icon: Icons.add_circle_outline,
            color: const Color(0xFF087F5B),
            onTap: onCreateKameti,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            title: 'Kametis',
            subtitle: 'View all',
            icon: Icons.groups_2_outlined,
            color: const Color(0xFF0B7285),
            onTap: onMyKametis,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            title: 'Alerts',
            subtitle: 'Review',
            icon: Icons.notifications_active_outlined,
            color: const Color(0xFFB7791F),
            onTap: onNotifications,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF17211D),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF5D6B65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusSection extends StatelessWidget {
  const _FocusSection({
    required this.pendingPayments,
    required this.pendingPayoutProofs,
    required this.pendingReceivers,
    required this.pendingDraws,
    required this.openBiddings,
    required this.unreadNotifications,
    required this.urgentAlerts,
    required this.onNotifications,
  });

  final int pendingPayments;
  final int pendingPayoutProofs;
  final int pendingReceivers;
  final int pendingDraws;
  final int openBiddings;
  final int unreadNotifications;
  final int urgentAlerts;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final items = [
      _FocusItemData(
        title: 'Pending payments',
        value: pendingPayments,
        icon: Icons.pending_actions_outlined,
        color: const Color(0xFFE67700),
      ),
      _FocusItemData(
        title: 'Payout proof',
        value: pendingPayoutProofs,
        icon: Icons.upload_file_outlined,
        color: const Color(0xFF0B7285),
      ),
      _FocusItemData(
        title: 'Receiver pending',
        value: pendingReceivers,
        icon: Icons.person_search_outlined,
        color: const Color(0xFF7048E8),
      ),
      _FocusItemData(
        title: 'Draws due',
        value: pendingDraws,
        icon: Icons.casino_outlined,
        color: const Color(0xFF2F80ED),
      ),
      _FocusItemData(
        title: 'Open bidding',
        value: openBiddings,
        icon: Icons.gavel_outlined,
        color: const Color(0xFF087F5B),
      ),
    ];
    return _SectionCard(
      title: "Today's focus",
      trailing: unreadNotifications > 0
          ? TextButton.icon(
              onPressed: onNotifications,
              icon: const Icon(Icons.notifications_outlined, size: 18),
              label: Text('$unreadNotifications alerts'),
            )
          : null,
      child: Column(
        children: [
          if (urgentAlerts > 0)
            _FocusAlert(
              title: '$urgentAlerts urgent item(s)',
              message: "Review alerts before closing today's hisaab.",
              onTap: onNotifications,
            )
          else
            const _FocusAlert(
              title: 'No urgent alerts',
              message: 'Payments and receiver actions look stable right now.',
            ),
          const SizedBox(height: 10),
          for (final item in items.where((item) => item.value > 0))
            _FocusRow(item: item),
          if (items.every((item) => item.value == 0))
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Nothing needs immediate action.',
                style: TextStyle(
                  color: Color(0xFF5D6B65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FocusItemData {
  const _FocusItemData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;
}

class _FocusAlert extends StatelessWidget {
  const _FocusAlert({
    required this.title,
    required this.message,
    this.onTap,
  });

  final String title;
  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4FBF8),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.shield_outlined,
                    color: Color(0xFF087F5B), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF5D6B65),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusRow extends StatelessWidget {
  const _FocusRow({required this.item});

  final _FocusItemData item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF26352F),
                  ),
            ),
          ),
          Text(
            '${item.value}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: item.color,
                ),
          ),
        ],
      ),
    );
  }
}

class _FinanceSnapshot extends StatelessWidget {
  const _FinanceSnapshot({
    required this.collectedThisMonth,
    required this.totalCollected,
    required this.totalPayouts,
    required this.groupBalance,
  });

  final double collectedThisMonth;
  final double totalCollected;
  final double totalPayouts;
  final double groupBalance;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Financial snapshot',
      child: Column(
        children: [
          _MoneyRow(
            label: 'Collected this month',
            value: collectedThisMonth,
            icon: Icons.payments_outlined,
            color: const Color(0xFF087F5B),
          ),
          const SizedBox(height: 10),
          _MoneyRow(
            label: 'Total collected',
            value: totalCollected,
            icon: Icons.add_card_outlined,
            color: const Color(0xFF0B7285),
          ),
          const SizedBox(height: 10),
          _MoneyRow(
            label: 'Total payouts',
            value: totalPayouts,
            icon: Icons.outbound_outlined,
            color: const Color(0xFFC92A2A),
          ),
          const Divider(height: 22),
          _MoneyRow(
            label: 'Balance',
            value: groupBalance,
            icon: Icons.account_balance_outlined,
            color: const Color(0xFF087F5B),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4C5A54),
            ),
          ),
        ),
        Text(
          CurrencyFormatter.pkr(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (emphasized
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.bodyMedium)
              ?.copyWith(
            color: emphasized ? color : const Color(0xFF17211D),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InsightStrip extends StatelessWidget {
  const _InsightStrip({
    required this.completedDraws,
    required this.completedBiddings,
    required this.confirmedReceivers,
    required this.completedAllocationCycles,
    required this.totalDiscounts,
  });

  final int completedDraws;
  final int completedBiddings;
  final int confirmedReceivers;
  final int completedAllocationCycles;
  final double totalDiscounts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _InsightPill(
            label: 'Draws completed',
            value: '$completedDraws',
            icon: Icons.emoji_events_outlined,
            color: const Color(0xFF2F80ED),
          ),
          _InsightPill(
            label: 'Biddings closed',
            value: '$completedBiddings',
            icon: Icons.gavel_outlined,
            color: const Color(0xFF7048E8),
          ),
          _InsightPill(
            label: 'Receivers',
            value: '$confirmedReceivers',
            icon: Icons.person_pin_circle_outlined,
            color: const Color(0xFF087F5B),
          ),
          _InsightPill(
            label: 'Cycles allocated',
            value: '$completedAllocationCycles',
            icon: Icons.task_alt_outlined,
            color: const Color(0xFF0B7285),
          ),
          _InsightPill(
            label: 'Discounts',
            value: CurrencyFormatter.pkr(totalDiscounts),
            icon: Icons.savings_outlined,
            color: const Color(0xFFB7791F),
          ),
        ],
      ),
    );
  }
}

class _InsightPill extends StatelessWidget {
  const _InsightPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 154,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5D6B65),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
