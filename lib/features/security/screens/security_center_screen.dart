import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../auth/providers/auth_controller.dart';
import '../../ledger/providers/ledger_controller.dart';
import '../../member/providers/member_controller.dart';
import '../../payment/providers/payment_controller.dart';
import '../models/security_models.dart';
import '../providers/security_controller.dart';
import '../widgets/security_widgets.dart';

class SecurityCenterScreen extends ConsumerWidget {
  const SecurityCenterScreen({this.kametiId = '', super.key});
  final String kametiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(securityControllerProvider);
    final user = ref.watch(authControllerProvider).user;
    final members = kametiId.isEmpty ? ref.watch(memberControllerProvider) : ref.read(memberControllerProvider.notifier).getMembersByKametiId(kametiId);
    final risky = ref.read(securityControllerProvider.notifier).getRiskyMembers(
          members: members,
          payments: ref.watch(paymentControllerProvider).payments,
          ledgerEntries: ref.watch(ledgerControllerProvider),
        );
    final disputes = kametiId.isEmpty ? ref.watch(securityControllerProvider).disputes : ref.read(securityControllerProvider.notifier).getDisputesByKametiId(kametiId);
    final logs = kametiId.isEmpty ? ref.watch(securityControllerProvider).auditLogs : ref.read(securityControllerProvider.notifier).getAuditLogsByKametiId(kametiId);
    return Scaffold(
      appBar: AppBar(title: Text(kametiId.isEmpty ? 'Security Center' : 'Kameti Security')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (user != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Security, privacy, disputes, reports, and trust score controls.'),
              ),
            ),
          SecurityWarningCard(message: '${disputes.where((item) => item.status != dynamicResolved && item.status != dynamicClosed).length} unresolved dispute(s).'),
          SecurityWarningCard(message: '${risky.length} risky member(s) need review.'),
          Card(
            child: Column(children: [
              if (kametiId.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.history_outlined),
                  title: const Text('Audit Logs'),
                  subtitle: Text('${logs.length} recorded action(s)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.auditLogs, arguments: kametiId),
                ),
              if (kametiId.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.report_problem_outlined),
                  title: const Text('Disputes'),
                  subtitle: Text('${disputes.length} dispute(s)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.disputes, arguments: kametiId),
                ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.privacySettings),
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('Export My Data'),
                subtitle: const Text('Placeholder for account data export.'),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data export request prepared.'))),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Request Account Deletion'),
                subtitle: const Text('Financial records may remain for group integrity.'),
                onTap: () => _requestDeletion(context, ref),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  DisputeStatus get dynamicResolved => DisputeStatus.resolved;
  DisputeStatus get dynamicClosed => DisputeStatus.closed;

  void _requestDeletion(BuildContext context, WidgetRef ref) {
    final userId = ref.read(authControllerProvider).user?.id ?? '';
    ref.read(securityControllerProvider.notifier).createDeletionRequest(userId, 'User requested deletion from Security Center.');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deletion request created.')));
  }
}
