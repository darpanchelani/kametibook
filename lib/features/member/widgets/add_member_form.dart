import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/member_model.dart';

class AddMemberForm extends StatefulWidget {
  const AddMemberForm({
    required this.onSubmit,
    this.initialMember,
    this.allowStatusEditing = false,
    this.submitLabel = 'Save Member',
    super.key,
  });

  final MemberModel? initialMember;
  final bool allowStatusEditing;
  final String submitLabel;
  final String? Function(MemberFormData data) onSubmit;

  @override
  State<AddMemberForm> createState() => _AddMemberFormState();
}

class _AddMemberFormState extends State<AddMemberForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  late final TextEditingController _cnicController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _emailController;
  late final TextEditingController _notesController;
  late MemberStatus _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final member = widget.initialMember;
    _nameController = TextEditingController(text: member?.fullName ?? '');
    _phoneController = TextEditingController(text: member?.phone ?? '');
    _cityController = TextEditingController(text: member?.city ?? '');
    _cnicController = TextEditingController(text: member?.cnic ?? '');
    _whatsappController =
        TextEditingController(text: member?.whatsappNumber ?? '');
    _emailController = TextEditingController(text: member?.email ?? '');
    _notesController = TextEditingController(text: member?.notes ?? '');
    _status = member?.status ?? MemberStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _cnicController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final error = widget.onSubmit(
      MemberFormData(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        cnic: _cnicController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        email: _emailController.text.trim(),
        notes: _notesController.text.trim(),
        status: _status,
      ),
    );
    if (mounted) setState(() => _isLoading = false);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const <String>[],
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            controller: _nameController,
            label: 'Full Name',
            prefixIcon: Icons.person_outline,
            validator: (value) => Validators.required(value, 'Full name'),
          ),
          const SizedBox(height: 14),
          AppTextField(
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const <String>[],
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            controller: _phoneController,
            label: 'Phone Number',
            hint: '03XXXXXXXXX',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            validator: Validators.phone,
          ),
          const SizedBox(height: 14),
          AppTextField(
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const <String>[],
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            controller: _cityController,
            label: 'City',
            prefixIcon: Icons.location_city_outlined,
            validator: (value) => Validators.required(value, 'City'),
          ),
          const SizedBox(height: 14),
          AppTextField(
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const <String>[],
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            controller: _cnicController,
            label: 'CNIC',
            hint: 'Optional, 13 digits',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.badge_outlined,
            validator: Validators.optionalCnic,
          ),
          const SizedBox(height: 14),
          AppTextField(
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const <String>[],
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            controller: _whatsappController,
            label: 'WhatsApp Number',
            hint: 'Optional',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.chat_outlined,
          ),
          const SizedBox(height: 14),
          AppTextField(
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const <String>[],
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            controller: _emailController,
            label: 'Email',
            hint: 'Optional',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: Validators.optionalEmail,
          ),
          if (widget.allowStatusEditing) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<MemberStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                  labelText: 'Status', prefixIcon: Icon(Icons.flag_outlined)),
              items: MemberStatus.values
                  .map((status) => DropdownMenuItem(
                      value: status, child: Text(status.label)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _status = value ?? MemberStatus.active),
            ),
          ],
          const SizedBox(height: 14),
          AppTextField(
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const <String>[],
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            controller: _notesController,
            label: 'Notes',
            hint: 'Optional',
            maxLines: 3,
            prefixIcon: Icons.notes_outlined,
          ),
          const SizedBox(height: 22),
          AppButton(
              label: widget.submitLabel,
              icon: Icons.check,
              isLoading: _isLoading,
              onPressed: _submit),
        ],
      ),
    );
  }
}

class MemberFormData {
  const MemberFormData({
    required this.fullName,
    required this.phone,
    required this.city,
    required this.cnic,
    required this.whatsappNumber,
    required this.email,
    required this.notes,
    required this.status,
  });

  final String fullName;
  final String phone;
  final String city;
  final String cnic;
  final String whatsappNumber;
  final String email;
  final String notes;
  final MemberStatus status;
}
