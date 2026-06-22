import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../models/ledger_entry_model.dart';

class LedgerSummaryCard extends StatelessWidget {
  const LedgerSummaryCard({required this.summary, super.key});
  final LedgerSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 14,
          runSpacing: 10,
          children: [
            _Item(label: 'Contributions', value: CurrencyFormatter.pkr(summary.totalContributions)),
            _Item(label: 'Payouts', value: CurrencyFormatter.pkr(summary.totalPayouts)),
            _Item(label: 'Discounts', value: CurrencyFormatter.pkr(summary.totalDiscounts)),
            _Item(label: 'Penalties', value: CurrencyFormatter.pkr(summary.totalPenalties)),
            _Item(label: 'Balance', value: CurrencyFormatter.pkr(summary.groupBalance)),
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
  Widget build(BuildContext context) => SizedBox(
        width: 135,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ]),
      );
}
