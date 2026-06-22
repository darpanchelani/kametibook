import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../member/models/member_model.dart';
import '../models/payment_models.dart';
import 'payment_status_badge.dart';

class MemberPaymentCard extends StatelessWidget {
  const MemberPaymentCard({
    required this.payment,
    required this.member,
    required this.onMarkPaid,
    required this.onMarkPending,
    required this.onMarkLate,
    required this.onReject,
    required this.onEdit,
    this.onSubmitProof,
    this.onApproveProof,
    this.onReportIssue,
    super.key,
  });

  final MemberPaymentModel payment;
  final MemberModel? member;
  final VoidCallback onMarkPaid;
  final VoidCallback onMarkPending;
  final VoidCallback onMarkLate;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final VoidCallback? onSubmitProof;
  final VoidCallback? onApproveProof;
  final VoidCallback? onReportIssue;

  @override
  Widget build(BuildContext context) {
    final paidDate = payment.paidAt == null ? '-' : DateFormatter.display(payment.paidAt!);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member?.fullName ?? 'Unknown Member',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(member?.phone ?? '-', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                PaymentStatusBadge(status: payment.paymentStatus),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _Meta(icon: Icons.payments_outlined, text: 'Due: ${CurrencyFormatter.pkr(payment.amountDue)}'),
                _Meta(icon: Icons.check_circle_outline, text: 'Paid: ${CurrencyFormatter.pkr(payment.amountPaid)}'),
                _Meta(icon: Icons.account_balance_wallet_outlined, text: payment.paymentMethod?.label ?? 'No method'),
                _Meta(icon: Icons.event_available_outlined, text: 'Paid: $paidDate'),
                _Meta(
                  icon: Icons.attachment_outlined,
                  text: payment.proofImagePath.isEmpty && payment.proofUrl.isEmpty ? 'No proof' : 'Proof attached',
                ),
              ],
            ),
            if (payment.note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(payment.note, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(onPressed: onMarkPaid, child: const Text('Mark Paid')),
                if (onSubmitProof != null) OutlinedButton(onPressed: onSubmitProof, child: const Text('Submit Proof')),
                if (payment.paymentStatus == PaymentStatus.pendingApproval && onApproveProof != null)
                  FilledButton(onPressed: onApproveProof, child: const Text('Approve')),
                OutlinedButton(onPressed: onMarkPending, child: const Text('Pending')),
                OutlinedButton(onPressed: onMarkLate, child: const Text('Late')),
                OutlinedButton(onPressed: onReject, child: const Text('Reject')),
                TextButton(onPressed: onEdit, child: const Text('View/Edit')),
                if (onReportIssue != null) TextButton(onPressed: onReportIssue, child: const Text('Report Issue')),
              ],
            ),
          ],
        ),
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
