import 'package:flutter/material.dart';

class MemberCountSummaryCard extends StatelessWidget {
  const MemberCountSummaryCard({
    required this.addedCount,
    required this.totalCount,
    super.key,
  });

  final int addedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final remaining = (totalCount - addedCount).clamp(0, totalCount);
    final progress =
        totalCount == 0 ? 0.0 : (addedCount / totalCount).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Members: $addedCount / $totalCount',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text('Remaining: $remaining',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
          ],
        ),
      ),
    );
  }
}
