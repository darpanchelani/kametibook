import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/bidding_models.dart';
import 'bidding_status_badge.dart';

class BiddingHistoryCard extends StatelessWidget {
  const BiddingHistoryCard({
    required this.session,
    required this.winnerName,
    required this.onTap,
    super.key,
  });

  final BiddingSessionModel session;
  final String winnerName;
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
                      'Month ${session.cycleNumber}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  BiddingStatusBadge(status: session.status),
                ],
              ),
              const SizedBox(height: 8),
              Text('Winner: $winnerName'),
              Text(
                  'Winning Amount: ${CurrencyFormatter.pkr(session.winningAmount)}'),
              Text(
                  'Total Pool: ${CurrencyFormatter.pkr(session.totalPoolAmount)}'),
              Text(
                  'Discount: ${CurrencyFormatter.pkr(session.discountAmount)}'),
              Text('Distribution: ${session.discountDistributionType.label}'),
              if (session.endTime != null)
                Text('Completed: ${DateFormatter.display(session.endTime!)}'),
            ],
          ),
        ),
      ),
    );
  }
}
