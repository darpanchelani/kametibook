import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../models/kameti_model.dart';

class KametiCard extends StatelessWidget {
  const KametiCard({
    required this.kameti,
    required this.onTap,
    this.activeMembersCount,
    this.currentCycleLabel,
    this.paidCount,
    this.pendingCount,
    this.collectedAmount,
    this.expectedAmount,
    this.drawStatusText,
    this.biddingStatusText,
    super.key,
  });

  final KametiModel kameti;
  final VoidCallback onTap;
  final int? activeMembersCount;
  final String? currentCycleLabel;
  final int? paidCount;
  final int? pendingCount;
  final double? collectedAmount;
  final double? expectedAmount;
  final String? drawStatusText;
  final String? biddingStatusText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      kameti.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  _StatusChip(status: kameti.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(kameti.type.label, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _Meta(icon: Icons.payments_outlined, text: CurrencyFormatter.pkr(kameti.monthlyAmount)),
                  _Meta(icon: Icons.savings_outlined, text: 'Pool: ${CurrencyFormatter.pkr(kameti.totalPoolAmount)}'),
                  _Meta(
                    icon: Icons.group_outlined,
                    text: 'Members: ${activeMembersCount ?? 0} / ${kameti.totalMembers}',
                  ),
                  _Meta(icon: Icons.calendar_month_outlined, text: '${kameti.durationMonths} months'),
                  if (currentCycleLabel != null) _Meta(icon: Icons.event_repeat_outlined, text: 'Current: $currentCycleLabel'),
                  if (paidCount != null && pendingCount != null)
                    _Meta(icon: Icons.fact_check_outlined, text: 'Paid: $paidCount / ${(paidCount ?? 0) + (pendingCount ?? 0)}'),
                  if (collectedAmount != null && expectedAmount != null)
                    _Meta(
                      icon: Icons.trending_up_outlined,
                      text: 'Collected: ${CurrencyFormatter.pkr(collectedAmount!)} / ${CurrencyFormatter.pkr(expectedAmount!)}',
                    ),
                  if (drawStatusText != null) _Meta(icon: Icons.casino_outlined, text: drawStatusText!),
                  if (biddingStatusText != null) _Meta(icon: Icons.gavel_outlined, text: biddingStatusText!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final KametiStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      KametiStatus.draft => Colors.orange.shade700,
      KametiStatus.active => Theme.of(context).colorScheme.primary,
      KametiStatus.completed => Colors.blue.shade700,
      KametiStatus.cancelled => Colors.red.shade700,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: Colors.black54),
        const SizedBox(width: 5),
        Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
      ],
    );
  }
}
