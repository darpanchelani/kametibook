import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../models/bidding_models.dart';

class DiscountAdjustmentCard extends StatelessWidget {
  const DiscountAdjustmentCard({required this.adjustment, super.key});

  final DiscountAdjustmentModel adjustment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(adjustment.memberName),
        subtitle: Text('${adjustment.adjustmentType.label} - ${adjustment.status.label}'),
        trailing: Text(CurrencyFormatter.pkr(adjustment.adjustmentAmount), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}
