import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import 'cycle_progress_bar.dart';

class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({
    required this.title,
    required this.expectedAmount,
    required this.collectedAmount,
    required this.pendingAmount,
    required this.paidCount,
    required this.pendingCount,
    this.lateCount = 0,
    this.rejectedCount = 0,
    super.key,
  });

  final String title;
  final double expectedAmount;
  final double collectedAmount;
  final double pendingAmount;
  final int paidCount;
  final int pendingCount;
  final int lateCount;
  final int rejectedCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            CycleProgressBar(collectedAmount: collectedAmount, expectedAmount: expectedAmount),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _Item(label: 'Expected', value: CurrencyFormatter.pkr(expectedAmount)),
                _Item(label: 'Collected', value: CurrencyFormatter.pkr(collectedAmount)),
                _Item(label: 'Pending', value: CurrencyFormatter.pkr(pendingAmount)),
                _Item(label: 'Paid', value: '$paidCount'),
                _Item(label: 'Pending Members', value: '$pendingCount'),
                if (lateCount > 0) _Item(label: 'Late', value: '$lateCount'),
                if (rejectedCount > 0) _Item(label: 'Rejected', value: '$rejectedCount'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
