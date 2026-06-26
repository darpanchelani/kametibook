import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/payment_models.dart';
import '../providers/payment_controller.dart';
import 'payment_method_dropdown.dart';

class MarkPaymentBottomSheet extends StatefulWidget {
  const MarkPaymentBottomSheet({
    required this.payment,
    required this.onSubmit,
    super.key,
  });

  final MemberPaymentModel payment;
  final ValueChanged<MarkPaymentPaidData> onSubmit;

  @override
  State<MarkPaymentBottomSheet> createState() => _MarkPaymentBottomSheetState();
}

class _MarkPaymentBottomSheetState extends State<MarkPaymentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  PaymentMethod? _method;
  DateTime _paidAt = DateTime.now();
  String _proofPath = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.payment.amountPaid > 0
          ? widget.payment.amountPaid.toStringAsFixed(0)
          : '',
    );
    _noteController = TextEditingController(text: widget.payment.note);
    _method = widget.payment.paymentMethod ?? PaymentMethod.cash;
    _paidAt = widget.payment.paidAt ?? DateTime.now();
    _proofPath = widget.payment.proofImagePath;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
      initialDate: _paidAt,
    );
    if (picked != null) setState(() => _paidAt = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount =
        double.parse(_amountController.text.replaceAll(',', '').trim());
    if (amount > widget.payment.amountDue) {
      SnackbarHelper.showError(
          context, 'Amount paid cannot be greater than amount due.');
      return;
    }
    setState(() => _isLoading = true);
    widget.onSubmit(
      MarkPaymentPaidData(
        amountPaid: amount,
        paymentMethod: _method!,
        paidAt: _paidAt,
        proofImagePath: _proofPath,
        note: _noteController.text.trim(),
        approvedBy: 'Organizer',
      ),
    );
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mark Payment Paid',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                AppTextField(
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const <String>[],
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  controller: _amountController,
                  label: 'Amount Paid',
                  hint: '0',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.payments_outlined,
                  validator: (value) =>
                      Validators.positiveNumber(value, 'Amount paid'),
                ),
                const SizedBox(height: 14),
                PaymentMethodDropdown(
                    value: _method,
                    onChanged: (value) => setState(() => _method = value)),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Paid Date',
                        prefixIcon: Icon(Icons.event_outlined)),
                    child: Text(DateFormatter.display(_paidAt)),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _proofPath =
                      'mock/proof-${DateTime.now().millisecondsSinceEpoch}.jpg'),
                  icon: const Icon(Icons.attachment_outlined),
                  label: Text(
                      _proofPath.isEmpty ? 'Attach Proof' : 'Proof Attached'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const <String>[],
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  controller: _noteController,
                  label: 'Note',
                  hint: 'Optional',
                  maxLines: 3,
                  prefixIcon: Icons.notes_outlined,
                ),
                const SizedBox(height: 18),
                AppButton(
                    label: 'Save Payment',
                    icon: Icons.check,
                    isLoading: _isLoading,
                    onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
