import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../../kameti/models/kameti_model.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../widgets/reminder_settings_tile.dart';

class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({required this.kametiId, super.key});

  final String kametiId;

  @override
  ConsumerState<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends ConsumerState<ReminderSettingsScreen> {
  late bool remindersEnabled;
  late int paymentDaysBefore;
  late bool paymentOnDueDate;
  late bool overdueEnabled;
  late OverdueReminderFrequency overdueFrequency;
  late bool payoutProofEnabled;
  late bool receiverPendingEnabled;
  late bool biddingEnabled;
  late bool luckyDrawEnabled;
  late bool quietHoursEnabled;
  late final TextEditingController quietStartController;
  late final TextEditingController quietEndController;

  @override
  void initState() {
    super.initState();
    final kameti = ref.read(kametiControllerProvider.notifier).byId(widget.kametiId);
    remindersEnabled = kameti?.remindersEnabled ?? true;
    paymentDaysBefore = kameti?.paymentReminderDaysBefore ?? 2;
    paymentOnDueDate = kameti?.paymentReminderOnDueDate ?? true;
    overdueEnabled = kameti?.overdueReminderEnabled ?? true;
    overdueFrequency = kameti?.overdueReminderFrequency ?? OverdueReminderFrequency.daily;
    payoutProofEnabled = kameti?.payoutProofReminderEnabled ?? true;
    receiverPendingEnabled = kameti?.receiverPendingReminderEnabled ?? true;
    biddingEnabled = kameti?.biddingReminderEnabled ?? true;
    luckyDrawEnabled = kameti?.luckyDrawReminderEnabled ?? true;
    quietHoursEnabled = kameti?.quietHoursEnabled ?? false;
    quietStartController = TextEditingController(text: kameti?.quietHoursStart ?? '22:00');
    quietEndController = TextEditingController(text: kameti?.quietHoursEnd ?? '08:00');
  }

  @override
  void dispose() {
    quietStartController.dispose();
    quietEndController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kameti = ref.watch(kametiControllerProvider).where((item) => item.id == widget.kametiId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(kameti?.name ?? 'Kameti', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            ReminderSettingsTile(title: 'Enable reminders', value: remindersEnabled, onChanged: (value) => setState(() => remindersEnabled = value)),
            TextFormField(
              initialValue: '$paymentDaysBefore',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Payment reminder days before due date'),
              onChanged: (value) => paymentDaysBefore = int.tryParse(value) ?? 2,
            ),
            ReminderSettingsTile(title: 'Remind on due date', value: paymentOnDueDate, onChanged: (value) => setState(() => paymentOnDueDate = value)),
            ReminderSettingsTile(title: 'Overdue reminders', value: overdueEnabled, onChanged: (value) => setState(() => overdueEnabled = value)),
            DropdownButtonFormField<OverdueReminderFrequency>(
              initialValue: overdueFrequency,
              decoration: const InputDecoration(labelText: 'Overdue reminder frequency'),
              items: OverdueReminderFrequency.values.map((item) => DropdownMenuItem(value: item, child: Text(item.label))).toList(),
              onChanged: (value) => setState(() => overdueFrequency = value ?? OverdueReminderFrequency.daily),
            ),
            ReminderSettingsTile(title: 'Payout proof reminders', value: payoutProofEnabled, onChanged: (value) => setState(() => payoutProofEnabled = value)),
            ReminderSettingsTile(title: 'Receiver pending reminders', value: receiverPendingEnabled, onChanged: (value) => setState(() => receiverPendingEnabled = value)),
            ReminderSettingsTile(title: 'Bidding reminders', value: biddingEnabled, onChanged: (value) => setState(() => biddingEnabled = value)),
            ReminderSettingsTile(title: 'Lucky draw reminders', value: luckyDrawEnabled, onChanged: (value) => setState(() => luckyDrawEnabled = value)),
            ReminderSettingsTile(title: 'Quiet hours', value: quietHoursEnabled, onChanged: (value) => setState(() => quietHoursEnabled = value)),
            Row(
              children: [
                Expanded(child: TextField(controller: quietStartController, decoration: const InputDecoration(labelText: 'Quiet start'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: quietEndController, decoration: const InputDecoration(labelText: 'Quiet end'))),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Save Settings')),
            TextButton(onPressed: _reset, child: const Text('Reset to Default')),
          ],
        ),
      ),
    );
  }

  void _save() {
    ref.read(kametiControllerProvider.notifier).updateReminderSettings(
          id: widget.kametiId,
          remindersEnabled: remindersEnabled,
          paymentReminderDaysBefore: paymentDaysBefore,
          paymentReminderOnDueDate: paymentOnDueDate,
          overdueReminderEnabled: overdueEnabled,
          overdueReminderFrequency: overdueFrequency,
          payoutProofReminderEnabled: payoutProofEnabled,
          receiverPendingReminderEnabled: receiverPendingEnabled,
          biddingReminderEnabled: biddingEnabled,
          luckyDrawReminderEnabled: luckyDrawEnabled,
          quietHoursEnabled: quietHoursEnabled,
          quietHoursStart: quietStartController.text,
          quietHoursEnd: quietEndController.text,
        );
    SnackbarHelper.showSuccess(context, 'Reminder settings saved.');
  }

  void _reset() {
    setState(() {
      remindersEnabled = true;
      paymentDaysBefore = 2;
      paymentOnDueDate = true;
      overdueEnabled = true;
      overdueFrequency = OverdueReminderFrequency.daily;
      payoutProofEnabled = true;
      receiverPendingEnabled = true;
      biddingEnabled = true;
      luckyDrawEnabled = true;
      quietHoursEnabled = false;
      quietStartController.text = '22:00';
      quietEndController.text = '08:00';
    });
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
