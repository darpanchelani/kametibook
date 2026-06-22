import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../bidding/providers/bidding_controller.dart';
import '../../member/providers/member_controller.dart';
import '../../payment/providers/payment_controller.dart';
import '../../receiver/providers/receiver_controller.dart';
import '../models/ledger_entry_model.dart';
import '../providers/ledger_controller.dart';
import '../widgets/ledger_entry_card.dart';
import '../widgets/ledger_summary_card.dart';

class GroupLedgerScreen extends ConsumerStatefulWidget {
  const GroupLedgerScreen({required this.kametiId, super.key});
  final String kametiId;

  @override
  ConsumerState<GroupLedgerScreen> createState() => _GroupLedgerScreenState();
}

class _GroupLedgerScreenState extends ConsumerState<GroupLedgerScreen> {
  final _searchController = TextEditingController();
  LedgerEntryType? _filter;
  bool _newestFirst = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _sync() {
    ref.read(ledgerControllerProvider.notifier).syncLedgerForKameti(
          kametiId: widget.kametiId,
          payments: ref.read(paymentControllerProvider).payments,
          allocations: ref.read(receiverControllerProvider).allocations,
          biddingSessions: ref.read(biddingControllerProvider).sessions,
          discountAdjustments: ref.read(biddingControllerProvider).adjustments,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(ledgerControllerProvider);
    ref.watch(memberControllerProvider);
    final ledgerController = ref.read(ledgerControllerProvider.notifier);
    final memberController = ref.read(memberControllerProvider.notifier);
    final summary = ledgerController.calculateGroupLedgerSummary(widget.kametiId);
    final query = _searchController.text.trim().toLowerCase();
    var entries = ledgerController.getLedgerEntriesByKametiId(widget.kametiId).where((entry) {
      final member = memberController.getMember(entry.memberId);
      final matchesFilter = _filter == null || entry.entryType == _filter;
      final matchesSearch = query.isEmpty ||
          entry.title.toLowerCase().contains(query) ||
          entry.description.toLowerCase().contains(query) ||
          (member?.fullName.toLowerCase().contains(query) ?? false) ||
          (member?.phone.toLowerCase().contains(query) ?? false);
      return matchesFilter && matchesSearch;
    }).toList();
    if (!_newestFirst) entries = entries.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Hisaab / Ledger')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LedgerSummaryCard(summary: summary),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: AppButton(label: 'Sync Ledger', icon: Icons.sync, onPressed: () {
                _sync();
                SnackbarHelper.showSuccess(context, 'Ledger synced successfully.');
              })),
              const SizedBox(width: 10),
              Expanded(child: AppButton(label: 'Add Manual Entry', icon: Icons.add, isOutlined: true, onPressed: () => Navigator.of(context).pushNamed(AppRoutes.manualLedgerEntry, arguments: widget.kametiId))),
            ]),
            const SizedBox(height: 12),
            TextField(controller: _searchController, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Search ledger', prefixIcon: Icon(Icons.search))),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilterChip(label: const Text('All'), selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
              for (final type in [LedgerEntryType.contribution, LedgerEntryType.payout, LedgerEntryType.discountGenerated, LedgerEntryType.penalty, LedgerEntryType.correction])
                FilterChip(label: Text(type.label), selected: _filter == type, onSelected: (_) => setState(() => _filter = type)),
              FilterChip(label: Text(_newestFirst ? 'Newest first' : 'Oldest first'), selected: true, onSelected: (_) => setState(() => _newestFirst = !_newestFirst)),
            ]),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const EmptyState(icon: Icons.menu_book_outlined, title: 'No ledger entries yet.')
            else
              ...entries.map((entry) => LedgerEntryCard(
                    entry: entry,
                    member: memberController.getMember(entry.memberId),
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.ledgerDetail, arguments: entry.id),
                  )),
          ],
        ),
      ),
    );
  }
}
