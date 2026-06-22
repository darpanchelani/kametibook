import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../receiver/models/receiver_allocation_model.dart';

class PayoutPaidData {
  const PayoutPaidData({
    required this.amount,
    required this.method,
    required this.paidAt,
    required this.proofPath,
    required this.note,
  });
  final double amount;
  final PayoutMethod method;
  final DateTime paidAt;
  final String proofPath;
  final String note;
}

class PayoutPaidBottomSheet extends StatefulWidget {
  const PayoutPaidBottomSheet({required this.allocation, required this.onSubmit, super.key});

  final ReceiverAllocationModel allocation;
  final ValueChanged<PayoutPaidData> onSubmit;

  @override
  State<PayoutPaidBottomSheet> createState() => _PayoutPaidBottomSheetState();
}

class _PayoutPaidBottomSheetState extends State<PayoutPaidBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  PayoutMethod _method = PayoutMethod.cash;
  DateTime _paidAt = DateTime.now();
  String _proofPath = '';

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.allocation.amount.toStringAsFixed(0));
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.viewInsetsOf(context).bottom + 16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
              Text('Mark Payout Paid', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              AppTextField(
                controller: _amountController,
                label: 'Payout Amount',
                keyboardType: TextInputType.number,
                validator: (value) {
                  final error = Validators.positiveNumber(value, 'Payout amount');
                  if (error != null) return error;
                  final amount = double.parse(value!.replaceAll(',', '').trim());
                  if (amount > widget.allocation.amount) return 'Payout cannot exceed allocation amount';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<PayoutMethod>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Payout Method'),
                items: PayoutMethod.values.map((method) => DropdownMenuItem(value: method, child: Text(method.label))).toList(),
                onChanged: (value) => setState(() => _method = value ?? PayoutMethod.cash),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(DateTime.now().year - 2),
                    lastDate: DateTime(DateTime.now().year + 2),
                    initialDate: _paidAt,
                  );
                  if (picked != null) setState(() => _paidAt = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Paid Date'),
                  child: Text(DateFormatter.display(_paidAt)),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => setState(() => _proofPath = 'mock/payout-proof-${DateTime.now().millisecondsSinceEpoch}.jpg'),
                icon: const Icon(Icons.attachment_outlined),
                label: Text(_proofPath.isEmpty ? 'Attach payout proof' : 'Proof attached'),
              ),
              const SizedBox(height: 14),
              AppTextField(controller: _noteController, label: 'Notes', maxLines: 3),
              const SizedBox(height: 18),
              AppButton(
                label: 'Save Payout',
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  widget.onSubmit(
                    PayoutPaidData(
                      amount: double.parse(_amountController.text.replaceAll(',', '').trim()),
                      method: _method,
                      paidAt: _paidAt,
                      proofPath: _proofPath,
                      note: _noteController.text.trim(),
                    ),
                  );
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
