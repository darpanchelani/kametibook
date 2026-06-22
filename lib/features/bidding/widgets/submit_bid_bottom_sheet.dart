import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../member/models/member_model.dart';

class SubmitBidBottomSheet extends StatefulWidget {
  const SubmitBidBottomSheet({
    required this.members,
    required this.totalPoolAmount,
    required this.onSubmit,
    this.initialMember,
    this.initialAmount,
    this.initialNote = '',
    super.key,
  });

  final List<MemberModel> members;
  final double totalPoolAmount;
  final MemberModel? initialMember;
  final double? initialAmount;
  final String initialNote;
  final String? Function(MemberModel member, double amount, String note) onSubmit;

  @override
  State<SubmitBidBottomSheet> createState() => _SubmitBidBottomSheetState();
}

class _SubmitBidBottomSheetState extends State<SubmitBidBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  MemberModel? _member;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _member = widget.initialMember;
    _amountController = TextEditingController(text: widget.initialAmount?.toStringAsFixed(0) ?? '');
    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final member = _member;
    if (member == null) return;
    final amount = double.parse(_amountController.text.replaceAll(',', '').trim());
    setState(() => _isLoading = true);
    final error = widget.onSubmit(member, amount, _noteController.text.trim());
    if (mounted) setState(() => _isLoading = false);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), behavior: SnackBarBehavior.floating));
    }
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
                Text('Submit Bid', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                DropdownButtonFormField<MemberModel>(
                  initialValue: _member,
                  decoration: const InputDecoration(labelText: 'Select Member', prefixIcon: Icon(Icons.person_outline)),
                  validator: (value) => value == null ? 'Member is required' : null,
                  items: widget.members
                      .map((member) => DropdownMenuItem(value: member, child: Text(member.fullName)))
                      .toList(),
                  onChanged: widget.initialMember == null ? (value) => setState(() => _member = value) : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _amountController,
                  label: 'Bid Amount',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.price_change_outlined,
                  validator: (value) {
                    final required = Validators.positiveNumber(value, 'Bid amount');
                    if (required != null) return required;
                    final amount = double.parse(value!.replaceAll(',', '').trim());
                    if (amount >= widget.totalPoolAmount) return 'Bid must be less than total pool';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _noteController,
                  label: 'Note',
                  hint: 'Optional',
                  maxLines: 3,
                  prefixIcon: Icons.notes_outlined,
                ),
                const SizedBox(height: 18),
                AppButton(label: 'Save Bid', icon: Icons.check, isLoading: _isLoading, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
