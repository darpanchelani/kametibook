import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../member/models/member_model.dart';
import '../models/ledger_entry_model.dart';
import 'ledger_direction_badge.dart';
import 'ledger_type_badge.dart';
import 'proof_indicator.dart';

class LedgerEntryCard extends StatelessWidget {
  const LedgerEntryCard({
    required this.entry,
    required this.member,
    required this.onTap,
    super.key,
  });

  final LedgerEntryModel entry;
  final MemberModel? member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sign = entry.direction == LedgerDirection.moneyIn
        ? '+ '
        : entry.direction == LedgerDirection.moneyOut
            ? '- '
            : '';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(entry.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900))),
              Text('$sign${CurrencyFormatter.pkr(entry.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              LedgerTypeBadge(type: entry.entryType),
              LedgerDirectionBadge(direction: entry.direction),
              Chip(
                  label: Text(entry.status.label),
                  visualDensity: VisualDensity.compact),
            ]),
            const SizedBox(height: 8),
            if (member != null) Text(member!.fullName),
            Text(
                'Cycle: ${entry.cycleId.isEmpty ? '-' : entry.cycleId.split('-cycle-').last.split('-').first}'),
            Text(DateFormatter.display(entry.entryDate)),
            ProofIndicator(proofPath: entry.proofPath),
          ]),
        ),
      ),
    );
  }
}
