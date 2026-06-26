import 'package:flutter/material.dart';

import '../models/lucky_draw_model.dart';

class DrawStatusBadge extends StatelessWidget {
  const DrawStatusBadge({required this.status, super.key});

  final LuckyDrawStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      LuckyDrawStatus.pending => Colors.orange.shade700,
      LuckyDrawStatus.completed => Theme.of(context).colorScheme.primary,
      LuckyDrawStatus.cancelled => Colors.red.shade700,
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
