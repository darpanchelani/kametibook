import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../models/member_model.dart';
import 'member_role_badge.dart';
import 'member_status_badge.dart';

class MemberCard extends StatelessWidget {
  const MemberCard({
    required this.member,
    required this.onView,
    required this.onEdit,
    required this.onRemove,
    required this.canRemove,
    super.key,
  });

  final MemberModel member;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    member.fullName.isEmpty ? '?' : member.fullName[0].toUpperCase(),
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(member.phone, style: const TextStyle(color: Colors.black54)),
                      Text(member.city, style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'view') onView();
                    if (value == 'edit') onEdit();
                    if (value == 'remove') onRemove();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'view', child: Text('View Details')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'remove',
                      enabled: canRemove,
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                MemberRoleBadge(role: member.role),
                MemberStatusBadge(status: member.status),
                _SmallInfo(text: 'Received: ${member.hasReceivedKameti ? 'Yes' : 'No'}'),
                _SmallInfo(text: 'Joined: ${DateFormatter.display(member.joinedAt)}'),
              ],
            ),
            if (member.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(member.notes, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  const _SmallInfo({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
