import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/providers/auth_controller.dart';
import '../models/ledger_entry_model.dart';
import '../providers/ledger_controller.dart';

class ManualLedgerEntryScreen extends ConsumerStatefulWidget {
  const ManualLedgerEntryScreen({required this.kametiId, super.key});
  final String kametiId;

  @override
  ConsumerState<ManualLedgerEntryScreen> createState() => _ManualLedgerEntryScreenState();
}

class _ManualLedgerEntryScreenState extends ConsumerState<ManualLedgerEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController(text: '0');
  LedgerEntryType _type = LedgerEntryType.manualNote;
  LedgerDirection _direction = LedgerDirection.neutral;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Manual Entry')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            DropdownButtonFormField<LedgerEntryType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Entry Type'),
              items: [LedgerEntryType.correction, LedgerEntryType.refund, LedgerEntryType.manualNote, LedgerEntryType.penalty]
                  .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
                  .toList(),
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<LedgerDirection>(
              initialValue: _direction,
              decoration: const InputDecoration(labelText: 'Direction'),
              items: LedgerDirection.values.map((direction) => DropdownMenuItem(value: direction, child: Text(direction.label))).toList(),
              onChanged: (value) => setState(() => _direction = value ?? _direction),
            ),
            const SizedBox(height: 14),
            AppTextField(controller: _titleController, label: 'Title', validator: (value) => value == null || value.trim().isEmpty ? 'Title is required' : null),
            const SizedBox(height: 14),
            AppTextField(controller: _amountController, label: 'Amount', keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            AppTextField(controller: _descriptionController, label: 'Description', maxLines: 3),
            const SizedBox(height: 14),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2035), initialDate: _date);
                if (picked != null) setState(() => _date = picked);
              },
              child: InputDecorator(decoration: const InputDecoration(labelText: 'Date'), child: Text(_date.toIso8601String().split('T').first)),
            ),
            const SizedBox(height: 20),
            AppButton(label: 'Save Entry', onPressed: _save),
          ]),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0;
    if (_direction != LedgerDirection.neutral && amount <= 0) {
      SnackbarHelper.showError(context, 'Amount is required for money in/out entries.');
      return;
    }
    final now = DateTime.now();
    ref.read(ledgerControllerProvider.notifier).createLedgerEntry(
          LedgerEntryModel(
            id: 'ledger-manual-${now.microsecondsSinceEpoch}',
            kametiId: widget.kametiId,
            cycleId: '',
            memberId: '',
            relatedPaymentId: '',
            relatedAllocationId: '',
            relatedBiddingSessionId: '',
            relatedDiscountAdjustmentId: '',
            entryType: _type,
            direction: _direction,
            amount: amount,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            paymentMethod: null,
            proofPath: '',
            status: LedgerStatus.confirmed,
            entryDate: _date,
            createdBy: ref.read(authControllerProvider).user?.fullName ?? 'Organizer',
            createdAt: now,
            updatedAt: now,
          ),
        );
    SnackbarHelper.showSuccess(context, 'Ledger entry added successfully.');
    Navigator.of(context).pop();
  }
}
