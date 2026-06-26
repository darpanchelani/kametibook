import 'package:flutter/material.dart';

import '../../receiver/models/receiver_allocation_model.dart';

class PayoutStatusBadge extends StatelessWidget {
  const PayoutStatusBadge({required this.status, super.key});
  final PayoutStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PayoutStatus.confirmed => Theme.of(context).colorScheme.primary,
      PayoutStatus.paid || PayoutStatus.proofUploaded => Colors.blue.shade700,
      PayoutStatus.pending => Colors.orange.shade700,
      PayoutStatus.rejected => Colors.red.shade700,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30)),
      child: Text(status.label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}
