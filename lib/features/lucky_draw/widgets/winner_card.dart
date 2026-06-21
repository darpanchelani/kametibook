import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/lucky_draw_model.dart';

class WinnerCard extends StatelessWidget {
  const WinnerCard({required this.draw, super.key});

  final LuckyDrawModel draw;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Winner: ${draw.winnerName}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Amount: ${CurrencyFormatter.pkr(draw.payoutAmount)}'),
            Text('Cycle: Month ${draw.cycleNumber}'),
            Text('Draw Date: ${DateFormatter.display(draw.drawDate)}'),
          ],
        ),
      ),
    );
  }
}
