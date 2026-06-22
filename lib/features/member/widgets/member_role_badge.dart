import 'package:flutter/material.dart';

import '../models/member_model.dart';

class MemberRoleBadge extends StatelessWidget {
  const MemberRoleBadge({required this.role, super.key});

  final MemberRole role;

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      MemberRole.organizer => Colors.blue.shade700,
      MemberRole.coOrganizer => Colors.teal.shade700,
      MemberRole.member => Colors.grey.shade700,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        role.label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
