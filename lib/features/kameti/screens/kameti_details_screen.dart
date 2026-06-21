import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../models/kameti_model.dart';
import '../providers/kameti_controller.dart';

class KametiDetailsScreen extends ConsumerWidget {
  const KametiDetailsScreen({required this.kametiId, super.key});

  final String kametiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kametis = ref.watch(kametiControllerProvider);
    KametiModel? kameti;
    for (final item in kametis) {
      if (item.id == kametiId) {
        kameti = item;
        break;
      }
    }
    final selectedKameti = kameti;
    if (selectedKameti == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kameti Details')),
        body: const Center(child: Text('Kameti not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Kameti Details')),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedKameti.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        Chip(label: Text(selectedKameti.status.label)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DetailLine(label: 'Kameti Type', value: selectedKameti.type.label),
                    _DetailLine(
                      label: 'Monthly Contribution',
                      value: CurrencyFormatter.pkr(selectedKameti.monthlyAmount),
                    ),
                    _DetailLine(label: 'Total Members', value: '${selectedKameti.totalMembers}'),
                    _DetailLine(label: 'Duration', value: '${selectedKameti.durationMonths} months'),
                    _DetailLine(label: 'Start Date', value: DateFormatter.display(selectedKameti.startDate)),
                    _DetailLine(label: 'Due Day', value: 'Day ${selectedKameti.dueDay}'),
                    _DetailLine(
                      label: 'Total Pool Amount',
                      value: CurrencyFormatter.pkr(selectedKameti.totalPoolAmount),
                    ),
                    _DetailLine(label: 'Organizer Name', value: selectedKameti.organizerName),
                    if (selectedKameti.description.isNotEmpty)
                      _DetailLine(label: 'Description / Rules', value: selectedKameti.description),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Add Members',
                    icon: Icons.group_add_outlined,
                    isOutlined: true,
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addMembers),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'Start Kameti',
                    icon: Icons.play_arrow,
                    onPressed: selectedKameti.status == KametiStatus.draft
                        ? () => _confirmStart(context, ref, selectedKameti.id)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Future Modules',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ...['Members', 'Payments', 'Cycles', 'Ledger', 'Bidding', 'Lucky Draw'].map(
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

  Future<void> _confirmStart(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Kameti?'),
        content: const Text('This will change the status from Draft to Active.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Start')),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(kametiControllerProvider.notifier).updateStatus(id, KametiStatus.active);
    if (context.mounted) {
      SnackbarHelper.showSuccess(context, 'Kameti status changed to Active.');
    }
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
