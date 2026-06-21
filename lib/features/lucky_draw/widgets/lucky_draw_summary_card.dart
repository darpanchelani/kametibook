import 'package:flutter/material.dart';

class LuckyDrawSummaryCard extends StatelessWidget {
  const LuckyDrawSummaryCard({
    required this.eligibleCount,
    required this.excludedCount,
    required this.alreadyReceivedCount,
    required this.remainingDraws,
    super.key,
  });

  final int eligibleCount;
  final int excludedCount;
  final int alreadyReceivedCount;
  final int remainingDraws;

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
            _Item(label: 'Received', value: '$alreadyReceivedCount'),
            _Item(label: 'Remaining Draws', value: '$remainingDraws'),
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
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
