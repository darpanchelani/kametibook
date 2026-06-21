import 'package:flutter/material.dart';

import '../models/member_model.dart';

class MemberStatusBadge extends StatelessWidget {
  const MemberStatusBadge({required this.status, super.key});

  final MemberStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MemberStatus.pending => Colors.orange.shade700,
      MemberStatus.active => Theme.of(context).colorScheme.primary,
      MemberStatus.removed => Colors.red.shade700,
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
