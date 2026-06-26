import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../auth/providers/auth_controller.dart';
import '../../cloud/services/storage_service.dart';
import '../../security/models/security_models.dart';
import '../../security/providers/security_controller.dart';
import '../models/payment_models.dart';
import '../providers/payment_controller.dart';

class SubmitPaymentProofScreen extends ConsumerStatefulWidget {
  const SubmitPaymentProofScreen({required this.paymentId, super.key});

  final String paymentId;

  @override
  ConsumerState<SubmitPaymentProofScreen> createState() =>
      _SubmitPaymentProofScreenState();
}

class _SubmitPaymentProofScreenState
    extends ConsumerState<SubmitPaymentProofScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  XFile? _proof;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payment = ref
        .watch(paymentControllerProvider)
        .payments
        .where((item) => item.id == widget.paymentId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Payment Proof')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (payment == null)
              const Text('Payment not found.')
            else ...[
              Text('Amount due: PKR ${payment.amountDue.toStringAsFixed(0)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              TextField(
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const <String>[],
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Amount paid', hintText: '0')),
              const SizedBox(height: 12),
              DropdownButtonFormField<PaymentMethod>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Payment method'),
                items: PaymentMethod.values
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item.label)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _method = value ?? PaymentMethod.cash),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  onPressed: _pickProof,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(_proof == null ? 'Attach Proof' : _proof!.name)),
              const SizedBox(height: 12),
              TextField(
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const <String>[],
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  controller: _noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Note')),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isSaving ? null : () => _submit(payment),
                icon: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Submit Proof'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickProof() async {
    final image = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;
    setState(() => _proof = image);
  }

  Future<void> _submit(MemberPaymentModel payment) async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      SnackbarHelper.showError(context, 'Amount must be greater than 0.');
      return;
    }
    setState(() => _isSaving = true);
    var proofUrl = '';
    try {
      if (_proof != null && FirebaseBootstrap.isInitialized) {
        proofUrl = await StorageService().uploadPaymentProof(
          kametiId: payment.kametiId,
          cycleId: payment.cycleId,
          memberId: payment.memberId,
          file: File(_proof!.path),
        );
      }
      ref.read(paymentControllerProvider.notifier).submitPaymentProof(
            paymentId: payment.id,
            amountPaid: amount,
            method: _method,
            proofImagePath: _proof?.path ?? '',
            proofUrl: proofUrl,
            note: _noteController.text.trim(),
            submittedBy: ref.read(authControllerProvider).user?.id ?? '',
          );
      ref.read(securityControllerProvider.notifier).createAuditLog(
            kametiId: payment.kametiId,
            userId: ref.read(authControllerProvider).user?.id ?? '',
            userName:
                ref.read(authControllerProvider).user?.fullName ?? 'Member',
            userRole: 'member',
            actionType: AuditActionType.paymentProofSubmitted,
            entityType: AuditEntityType.payment,
            entityId: payment.id,
            oldValue: payment.paymentStatus.name,
            newValue: PaymentStatus.pendingApproval.name,
            description: 'Member submitted payment proof for approval.',
            severity: AuditSeverity.medium,
          );
      if (mounted) {
        SnackbarHelper.showSuccess(
            context, 'Payment proof submitted for approval.');
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
