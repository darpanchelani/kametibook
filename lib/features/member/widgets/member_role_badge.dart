import 'package:flutter/material.dart';

import '../models/member_model.dart';

class MemberRoleBadge extends StatelessWidget {
  const MemberRoleBadge({required this.role, super.key});

  final MemberRole role;

  @override
  Widget build(BuildContext context) {
    if (role != MemberRole.organizer) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade700.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        'Organizer',
        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
