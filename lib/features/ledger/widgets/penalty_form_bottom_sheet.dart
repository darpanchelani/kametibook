import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../member/models/member_model.dart';

class PenaltyFormBottomSheet extends StatefulWidget {
  const PenaltyFormBottomSheet(
      {required this.members, required this.onSubmit, super.key});
  final List<MemberModel> members;
  final void Function(MemberModel member, double amount, String note) onSubmit;

  @override
  State<PenaltyFormBottomSheet> createState() => _PenaltyFormBottomSheetState();
}

class _PenaltyFormBottomSheetState extends State<PenaltyFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  MemberModel? _member;

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
        padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Add Penalty',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<MemberModel>(
                    initialValue: _member,
                    decoration: const InputDecoration(labelText: 'Member'),
                    validator: (value) =>
                        value == null ? 'Member is required' : null,
                    items: widget.members
                        .map((member) => DropdownMenuItem(
                            value: member, child: Text(member.fullName)))
                        .toList(),
                    onChanged: (value) => setState(() => _member = value),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    enableSuggestions: false,
                    autocorrect: false,
                    autofillHints: const <String>[],
                    smartDashesType: SmartDashesType.disabled,
                    smartQuotesType: SmartQuotesType.disabled,
                    controller: _amountController,
                    label: 'Penalty Amount',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        Validators.positiveNumber(value, 'Penalty amount'),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                      enableSuggestions: false,
                      autocorrect: false,
                      autofillHints: const <String>[],
                      smartDashesType: SmartDashesType.disabled,
                      smartQuotesType: SmartQuotesType.disabled,
                      controller: _noteController,
                      label: 'Reason / note',
                      maxLines: 3),
                  const SizedBox(height: 18),
                  AppButton(
                    label: 'Save Penalty',
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      widget.onSubmit(
                          _member!,
                          double.parse(_amountController.text
                              .replaceAll(',', '')
                              .trim()),
                          _noteController.text.trim());
                    },
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}
