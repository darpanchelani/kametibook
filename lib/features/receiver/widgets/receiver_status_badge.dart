import 'package:flutter/material.dart';

import '../models/receiver_allocation_model.dart';

class ReceiverStatusBadge extends StatelessWidget {
  const ReceiverStatusBadge({required this.status, super.key});

  final ReceiverAllocationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ReceiverAllocationStatus.pending => Colors.orange.shade700,
      ReceiverAllocationStatus.confirmed =>
        Theme.of(context).colorScheme.primary,
      ReceiverAllocationStatus.cancelled => Colors.red.shade700,
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
