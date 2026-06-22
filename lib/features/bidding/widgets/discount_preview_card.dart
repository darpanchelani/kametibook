import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../models/bidding_models.dart';
import 'discount_adjustment_card.dart';

class DiscountPreviewCard extends StatelessWidget {
  const DiscountPreviewCard({
    required this.totalPool,
    required this.winningBid,
    required this.discount,
    required this.adjustments,
    super.key,
  });

  final double totalPool;
  final double winningBid;
  final double discount;
  final List<DiscountAdjustmentModel> adjustments;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Discount Preview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Total Pool: ${CurrencyFormatter.pkr(totalPool)}'),
            Text('Winning Bid: ${CurrencyFormatter.pkr(winningBid)}'),
            Text('Discount: ${CurrencyFormatter.pkr(discount)}'),
            const SizedBox(height: 8),
            if (adjustments.isEmpty)
              const Text('No discount adjustments generated.')
            else
              ...adjustments.map((item) => DiscountAdjustmentCard(adjustment: item)),
          ],
        ),
      ),
    );
  }
}
