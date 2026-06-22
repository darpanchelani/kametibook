import 'package:flutter/material.dart';

import '../models/ledger_entry_model.dart';

class LedgerDirectionBadge extends StatelessWidget {
  const LedgerDirectionBadge({required this.direction, super.key});
  final LedgerDirection direction;

  @override
  Widget build(BuildContext context) {
    final color = switch (direction) {
      LedgerDirection.moneyIn => Theme.of(context).colorScheme.primary,
      LedgerDirection.moneyOut => Colors.red.shade700,
      LedgerDirection.neutral => Colors.blueGrey.shade700,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30)),
      child: Text(direction.label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}
