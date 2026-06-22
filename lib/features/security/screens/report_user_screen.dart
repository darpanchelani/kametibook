import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../../auth/providers/auth_controller.dart';
import '../../member/providers/member_controller.dart';
import '../models/security_models.dart';
import '../providers/security_controller.dart';

class ReportUserArgs {
  const ReportUserArgs({required this.kametiId, required this.memberId});
  final String kametiId;
  final String memberId;
}

class ReportUserScreen extends ConsumerStatefulWidget {
  const ReportUserScreen({required this.args, super.key});
  final ReportUserArgs args;

  @override
  ConsumerState<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends ConsumerState<ReportUserScreen> {
  final _descriptionController = TextEditingController();
  ReportUserReason _reason = ReportUserReason.other;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(memberControllerProvider).where((item) => item.id == widget.args.memberId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Report User')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (member != null) Text(member.fullName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          DropdownButtonFormField<ReportUserReason>(
            initialValue: _reason,
            decoration: const InputDecoration(labelText: 'Reason'),
            items: ReportUserReason.values.map((reason) => DropdownMenuItem(value: reason, child: Text(reason.label))).toList(),
            onChanged: (value) => setState(() => _reason = value ?? ReportUserReason.other),
          ),
          const SizedBox(height: 12),
          TextField(controller: _descriptionController, maxLines: 5, decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.report_outlined), label: const Text('Submit Report')),
        ]),
      ),
    );
  }

  void _submit() {
    final user = ref.read(authControllerProvider).user;
    final now = DateTime.now();
    ref.read(securityControllerProvider.notifier).reportUser(
          ReportUserModel(
            id: 'report-user-${now.microsecondsSinceEpoch}',
            reportedUserId: widget.args.memberId,
            reportedBy: user?.id ?? 'mock-user',
            kametiId: widget.args.kametiId,
            reason: _reason,
            description: _descriptionController.text.trim(),
            evidenceUrls: const [],
            status: 'open',
            createdAt: now,
            updatedAt: now,
          ),
        );
    SnackbarHelper.showSuccess(context, 'User report submitted.');
    Navigator.of(context).pop();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
