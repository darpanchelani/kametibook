import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../models/bidding_models.dart';

class LowestBidCard extends StatelessWidget {
  const LowestBidCard({required this.bid, super.key});

  final BidModel? bid;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          bid == null
              ? 'No active bids yet.'
              : 'Current lowest bid: ${CurrencyFormatter.pkr(bid!.bidAmount)} by ${bid!.memberName}',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
