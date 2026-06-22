import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/payment_models.dart';
import 'cycle_progress_bar.dart';

class PaymentCycleCard extends StatelessWidget {
  const PaymentCycleCard({
    required this.cycle,
    required this.paidCount,
    required this.pendingCount,
    required this.onOpen,
    required this.onMarkCurrent,
    required this.onComplete,
    this.drawStatusText,
    this.drawWarning,
    this.biddingStatusText,
    this.biddingWarning,
    this.receiverStatusText,
    super.key,
  });

  final PaymentCycleModel cycle;
  final int paidCount;
  final int pendingCount;
  final VoidCallback onOpen;
  final VoidCallback onMarkCurrent;
  final VoidCallback onComplete;
  final String? drawStatusText;
  final String? drawWarning;
  final String? biddingStatusText;
  final String? biddingWarning;
  final String? receiverStatusText;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Month ${cycle.cycleNumber} - ${cycle.monthLabel}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                _CycleStatusChip(status: cycle.status),
              ],
            ),
            const SizedBox(height: 10),
            Text('Due Date: ${DateFormatter.display(cycle.dueDate)}'),
            const SizedBox(height: 12),
            CycleProgressBar(collectedAmount: cycle.collectedAmount, expectedAmount: cycle.expectedAmount),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _Meta(icon: Icons.savings_outlined, text: 'Expected: ${CurrencyFormatter.pkr(cycle.expectedAmount)}'),
                _Meta(icon: Icons.check_circle_outline, text: 'Collected: ${CurrencyFormatter.pkr(cycle.collectedAmount)}'),
                _Meta(icon: Icons.pending_actions_outlined, text: 'Pending: ${CurrencyFormatter.pkr(cycle.pendingAmount)}'),
                _Meta(icon: Icons.group_outlined, text: 'Paid: $paidCount'),
                _Meta(icon: Icons.hourglass_empty_outlined, text: 'Pending Members: $pendingCount'),
              ],
            ),
            if (drawStatusText != null) ...[
              const SizedBox(height: 10),
              Text(drawStatusText!, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
            if (drawWarning != null) ...[
              const SizedBox(height: 6),
              Text(drawWarning!, style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w800)),
            ],
            if (biddingStatusText != null) ...[
              const SizedBox(height: 10),
              Text(biddingStatusText!, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
            if (biddingWarning != null) ...[
              const SizedBox(height: 6),
              Text(biddingWarning!, style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w800)),
            ],
            if (receiverStatusText != null) ...[
              const SizedBox(height: 10),
              Text(receiverStatusText!, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(onPressed: onOpen, icon: const Icon(Icons.open_in_new), label: const Text('Open Payments')),
                OutlinedButton(onPressed: onMarkCurrent, child: const Text('Mark Current')),
                OutlinedButton(onPressed: onComplete, child: const Text('Complete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CycleStatusChip extends StatelessWidget {
  const _CycleStatusChip({required this.status});

  final PaymentCycleStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PaymentCycleStatus.current => Theme.of(context).colorScheme.primary,
      PaymentCycleStatus.completed => Colors.blue.shade700,
      PaymentCycleStatus.overdue => Colors.red.shade700,
      PaymentCycleStatus.upcoming => Colors.orange.shade700,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30)),
      child: Text(status.label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: Colors.black54),
        const SizedBox(width: 5),
        Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
      ],
    );
  }
}
