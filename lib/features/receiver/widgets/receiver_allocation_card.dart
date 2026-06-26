import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/receiver_allocation_model.dart';
import 'allocation_type_badge.dart';
import 'receiver_status_badge.dart';

class ReceiverAllocationCard extends StatelessWidget {
  const ReceiverAllocationCard(
      {required this.allocation, this.onMarkPayoutPaid, super.key});

  final ReceiverAllocationModel allocation;
  final VoidCallback? onMarkPayoutPaid;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Receiver: ${allocation.memberName}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                ReceiverStatusBadge(status: allocation.status),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              AllocationTypeBadge(type: allocation.allocationType)
            ]),
            const SizedBox(height: 8),
            Text('Amount: ${CurrencyFormatter.pkr(allocation.amount)}'),
            Text('Cycle: Month ${allocation.cycleNumber}'),
            Text('Payout: ${allocation.payoutStatus.label}'),
            Text(allocation.payoutProofPath.isEmpty
                ? 'No proof'
                : 'Proof attached'),
            if (allocation.confirmedAt != null)
              Text(
                  'Confirmed: ${DateFormatter.display(allocation.confirmedAt!)}'),
            if (allocation.notes.isNotEmpty) Text('Notes: ${allocation.notes}'),
            if (onMarkPayoutPaid != null &&
                allocation.payoutStatus != PayoutStatus.confirmed) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onMarkPayoutPaid,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Mark Payout Paid'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
