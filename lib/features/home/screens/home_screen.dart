import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/summary_card.dart';
import '../../auth/providers/auth_controller.dart';
import '../../kameti/models/kameti_model.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../../kameti/widgets/kameti_card.dart';
import '../../member/providers/member_controller.dart';
import '../../lucky_draw/providers/lucky_draw_controller.dart';
import '../../payment/providers/payment_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final kametis = ref.watch(kametiControllerProvider);
    ref.watch(memberControllerProvider);
    ref.watch(paymentControllerProvider);
    ref.watch(luckyDrawControllerProvider);
    final activeCount = kametis.where((kameti) => kameti.status == KametiStatus.active).length;
    final draftCount = kametis.where((kameti) => kameti.status == KametiStatus.draft).length;
    final memberController = ref.read(memberControllerProvider.notifier);
    final paymentController = ref.read(paymentControllerProvider.notifier);
    final drawController = ref.read(luckyDrawControllerProvider.notifier);
    final pendingPayments = paymentController.pendingPaymentsInCurrentCycles(kametis);
    final collectedThisMonth = paymentController.collectedInCurrentCycles(kametis);
    final pendingDraws = drawController.getPendingDrawsCount(
      kametis: kametis,
      cycles: ref.watch(paymentControllerProvider).cycles,
    );
    final completedDraws = drawController.getCompletedDrawsCount();
    final recent = kametis.take(3).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Assalam o Alaikum, ${user?.fullName ?? 'User'}',
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
              ],
            ),
            const SizedBox(height: 18),
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
                title: 'No kameti created yet. Start your first kameti today.',
              )
            else
              ...recent.map(
                (kameti) {
                  final cycle = paymentController.getCurrentCycle(kameti.id);
                  final draw = cycle == null ? null : drawController.getDrawByCycleId(cycle.id);
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
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.kametiDetails, arguments: kameti.id),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
