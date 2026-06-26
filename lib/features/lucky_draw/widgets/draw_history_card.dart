import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/lucky_draw_model.dart';
import 'draw_status_badge.dart';

class DrawHistoryCard extends StatelessWidget {
  const DrawHistoryCard({
    required this.draw,
    required this.onTap,
    super.key,
  });

  final LuckyDrawModel draw;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Month ${draw.cycleNumber}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  DrawStatusBadge(status: draw.status),
                ],
              ),
              const SizedBox(height: 8),
              Text('Winner: ${draw.winnerName}'),
              Text('Payout: ${CurrencyFormatter.pkr(draw.payoutAmount)}'),
              Text('Draw Date: ${DateFormatter.display(draw.drawDate)}'),
              Text('Eligible Members: ${draw.totalEligibleMembers}'),
              Text('Created By: ${draw.createdBy}'),
            ],
          ),
        ),
      ),
    );
  }
}
