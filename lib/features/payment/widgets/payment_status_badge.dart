import 'package:flutter/material.dart';

import '../models/payment_models.dart';

class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({required this.status, super.key});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PaymentStatus.paid => Theme.of(context).colorScheme.primary,
      PaymentStatus.pending => Colors.orange.shade700,
      PaymentStatus.proofSubmitted => Colors.blue.shade700,
      PaymentStatus.pendingApproval => Colors.indigo.shade700,
      PaymentStatus.late => Colors.red.shade700,
      PaymentStatus.rejected => Colors.red.shade900,
      PaymentStatus.waived => Colors.blueGrey.shade700,
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
