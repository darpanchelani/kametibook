import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';

class BiddingSummaryCard extends StatelessWidget {
  const BiddingSummaryCard({
    required this.eligibleCount,
    required this.excludedCount,
    required this.receivedCount,
    required this.bidsCount,
    required this.totalPoolAmount,
    super.key,
  });

  final int eligibleCount;
  final int excludedCount;
  final int receivedCount;
  final int bidsCount;
  final double totalPoolAmount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 14,
          runSpacing: 10,
          children: [
            _Item(label: 'Eligible', value: '$eligibleCount'),
            _Item(label: 'Excluded', value: '$excludedCount'),
            _Item(label: 'Received', value: '$receivedCount'),
            _Item(label: 'Bids', value: '$bidsCount'),
            _Item(
                label: 'Total Pool',
                value: CurrencyFormatter.pkr(totalPoolAmount)),
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
      width: 135,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
