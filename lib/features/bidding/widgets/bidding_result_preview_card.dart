import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../providers/bidding_controller.dart';
import 'discount_preview_card.dart';

class BiddingResultPreviewCard extends StatelessWidget {
  const BiddingResultPreviewCard({
    required this.preview,
    required this.totalPool,
    required this.onComplete,
    super.key,
  });

  final BiddingCompletionPreview preview;
  final double totalPool;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Winner Preview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('Winner: ${preview.winningBid.memberName}'),
                Text('Winning Bid: ${CurrencyFormatter.pkr(preview.winningBid.bidAmount)}'),
                Text('Discount: ${CurrencyFormatter.pkr(preview.discountAmount)}'),
              ],
            ),
          ),
        ),
        DiscountPreviewCard(
          totalPool: totalPool,
          winningBid: preview.winningBid.bidAmount,
          discount: preview.discountAmount,
          adjustments: preview.adjustments,
        ),
        FilledButton.icon(onPressed: onComplete, icon: const Icon(Icons.lock_outline), label: const Text('Complete Bidding')),
      ],
    );
  }
}
