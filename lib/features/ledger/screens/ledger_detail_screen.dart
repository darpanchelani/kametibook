import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../member/providers/member_controller.dart';
import '../../security/models/security_models.dart';
import '../../security/screens/create_dispute_screen.dart';
import '../models/ledger_entry_model.dart';
import '../providers/ledger_controller.dart';
import '../widgets/ledger_direction_badge.dart';
import '../widgets/ledger_type_badge.dart';
import '../widgets/proof_indicator.dart';

class LedgerDetailScreen extends ConsumerWidget {
  const LedgerDetailScreen({required this.entryId, super.key});
  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(ledgerControllerProvider);
    LedgerEntryModel? entry;
    for (final item in ref.read(ledgerControllerProvider)) {
      if (item.id == entryId) {
        entry = item;
        break;
      }
    }
    if (entry == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Ledger Detail')),
          body: const Center(child: Text('Entry not found')));
    }
    final selectedEntry = entry;
    final member = ref
        .read(memberControllerProvider.notifier)
        .getMember(selectedEntry.memberId);
    return Scaffold(
      appBar: AppBar(title: const Text('Ledger Detail')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selectedEntry.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      LedgerTypeBadge(type: selectedEntry.entryType),
                      LedgerDirectionBadge(direction: selectedEntry.direction),
                      Chip(label: Text(selectedEntry.status.label))
                    ]),
                    const SizedBox(height: 12),
                    _Line(
                        label: 'Amount',
                        value: CurrencyFormatter.pkr(selectedEntry.amount)),
                    _Line(label: 'Member', value: member?.fullName ?? '-'),
                    _Line(
                        label: 'Payment Method',
                        value: selectedEntry.paymentMethod?.label ?? '-'),
                    _Line(
                        label: 'Entry Date',
                        value: DateFormatter.display(selectedEntry.entryDate)),
                    _Line(label: 'Created By', value: selectedEntry.createdBy),
                    _Line(
                        label: 'Description',
                        value: selectedEntry.description.isEmpty
                            ? '-'
                            : selectedEntry.description),
                    ProofIndicator(proofPath: selectedEntry.proofPath),
                  ]),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => SnackbarHelper.showInfo(context,
                'Advanced ledger corrections will be available in future phases.'),
            child: const Text('Reverse Entry'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.createDispute,
              arguments: CreateDisputeArgs(
                kametiId: selectedEntry.kametiId,
                relatedEntityType: DisputeRelatedEntityType.ledgerEntry,
                relatedEntityId: selectedEntry.id,
                defaultType: DisputeType.ledgerIssue,
              ),
            ),
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Report Ledger Issue'),
          ),
        ]),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 130,
              child:
                  Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
        ]),
      );
}
