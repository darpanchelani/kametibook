import 'package:flutter/material.dart';

import '../models/bidding_models.dart';

class BiddingStatusBadge extends StatelessWidget {
  const BiddingStatusBadge({required this.status, super.key});

  final BiddingSessionStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BiddingSessionStatus.notStarted => Colors.grey.shade700,
      BiddingSessionStatus.open => Theme.of(context).colorScheme.primary,
      BiddingSessionStatus.closed => Colors.orange.shade800,
      BiddingSessionStatus.completed => Colors.blue.shade700,
      BiddingSessionStatus.cancelled => Colors.red.shade700,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30)),
      child: Text(status.label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}
