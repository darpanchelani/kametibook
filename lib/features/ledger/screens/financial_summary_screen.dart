import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../member/providers/member_controller.dart';
import '../../payment/providers/payment_controller.dart';
import '../providers/ledger_controller.dart';
import '../widgets/ledger_summary_card.dart';

class FinancialSummaryScreen extends ConsumerWidget {
  const FinancialSummaryScreen({required this.kametiId, super.key});
  final String kametiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(ledgerControllerProvider);
    ref.watch(paymentControllerProvider);
    ref.watch(memberControllerProvider);
    final ledgerController = ref.read(ledgerControllerProvider.notifier);
    final paymentController = ref.read(paymentControllerProvider.notifier);
    final memberController = ref.read(memberControllerProvider.notifier);
    final summary = ledgerController.calculateGroupLedgerSummary(kametiId);
    final cycles = paymentController.getCyclesByKametiId(kametiId);
    final members = memberController.getMembersByKametiId(kametiId);
    return Scaffold(
      appBar: AppBar(title: const Text('Financial Summary')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Overall Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          LedgerSummaryCard(summary: summary),
          const SizedBox(height: 12),
          Text('Cycle-wise Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          ...cycles.map((cycle) {
            final cycleSummary = ledgerController.calculateCycleLedgerSummary(cycle.id);
            return Card(
              child: ListTile(
                title: Text('Month ${cycle.cycleNumber} - ${cycle.monthLabel}'),
                subtitle: Text('Expected: ${CurrencyFormatter.pkr(cycle.expectedAmount)} | Collected: ${CurrencyFormatter.pkr(cycle.collectedAmount)} | Pending: ${CurrencyFormatter.pkr(cycle.pendingAmount)}'),
                trailing: Text(CurrencyFormatter.pkr(cycleSummary.groupBalance), style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            );
          }),
          const SizedBox(height: 12),
          Text('Member-wise Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          ...members.map((member) {
            final memberSummary = ledgerController.calculateMemberLedgerSummary(member.id);
            final net = member.receivedAmount + memberSummary.totalDiscounts - memberSummary.totalContributions - memberSummary.totalPenalties;
            return Card(
              child: ListTile(
                title: Text(member.fullName),
                subtitle: Text('Paid: ${CurrencyFormatter.pkr(memberSummary.totalContributions)} | Penalties: ${CurrencyFormatter.pkr(memberSummary.totalPenalties)} | Received: ${CurrencyFormatter.pkr(member.receivedAmount)}'),
                trailing: Text(CurrencyFormatter.pkr(net), style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            );
          }),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.warning_amber_outlined),
              title: Text('Warnings'),
              subtitle: Text('Some payments or payout proofs may still be pending.'),
            ),
          ),
        ]),
      ),
    );
  }
}
