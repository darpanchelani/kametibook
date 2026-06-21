import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatter.dart';
import '../models/member_model.dart';
import '../providers/member_controller.dart';
import '../widgets/member_info_tile.dart';
import '../widgets/member_role_badge.dart';
import '../widgets/member_status_badge.dart';

class MemberDetailsScreen extends ConsumerWidget {
  const MemberDetailsScreen({required this.memberId, super.key});

  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    MemberModel? member;
    for (final item in ref.watch(memberControllerProvider)) {
      if (item.id == memberId) {
        member = item;
        break;
      }
    }
    if (member == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Details')),
        body: const Center(child: Text('Member not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Member Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      MemberRoleBadge(role: member.role),
                      MemberStatusBadge(status: member.status),
                    ]),
                    const SizedBox(height: 12),
                    MemberInfoTile(label: 'Phone', value: member.phone, icon: Icons.phone_outlined),
                    MemberInfoTile(label: 'WhatsApp', value: member.whatsappNumber, icon: Icons.chat_outlined),
                    MemberInfoTile(label: 'Email', value: member.email, icon: Icons.email_outlined),
                    MemberInfoTile(label: 'City', value: member.city, icon: Icons.location_city_outlined),
                    if (member.cnic.isNotEmpty)
                      MemberInfoTile(label: 'CNIC', value: member.cnic, icon: Icons.badge_outlined),
                    MemberInfoTile(label: 'Role', value: member.role.label, icon: Icons.admin_panel_settings_outlined),
                    MemberInfoTile(label: 'Status', value: member.status.label, icon: Icons.flag_outlined),
                    MemberInfoTile(
                      label: 'Joined Date',
                      value: DateFormatter.display(member.joinedAt),
                      icon: Icons.event_outlined,
                    ),
                    MemberInfoTile(
                      label: 'Has Received Kameti',
                      value: member.hasReceivedKameti ? 'Yes' : 'No',
                      icon: Icons.savings_outlined,
                    ),
                    if (member.notes.isNotEmpty)
                      MemberInfoTile(label: 'Notes', value: member.notes, icon: Icons.notes_outlined),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...['Payment History', 'Received Kameti Details', 'Penalties', 'Ledger Entries'].map(
              (title) => Card(
                child: ListTile(
                  leading: const Icon(Icons.lock_clock_outlined),
                  title: Text(title),
                  subtitle: const Text('Coming in next phases.'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
