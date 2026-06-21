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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final kametis = ref.watch(kametiControllerProvider);
    final activeCount = kametis.where((kameti) => kameti.status == KametiStatus.active).length;
    final completedCount = kametis.where((kameti) => kameti.status == KametiStatus.completed).length;
    final monthlyPayable = kametis
        .where((kameti) => kameti.status == KametiStatus.active)
        .fold<double>(0, (total, kameti) => total + kameti.monthlyAmount);
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
                  title: 'Monthly Payable',
                  value: CurrencyFormatter.pkr(monthlyPayable),
                  icon: Icons.payments_outlined,
                  color: Colors.teal.shade700,
                ),
                const SummaryCard(title: 'Pending Payments', value: '0', icon: Icons.pending_actions_outlined),
                SummaryCard(
                  title: 'Completed Kametis',
                  value: '$completedCount',
                  icon: Icons.check_circle_outline,
                  color: Colors.blue.shade700,
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
                (kameti) => KametiCard(
                  kameti: kameti,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.kametiDetails, arguments: kameti.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
