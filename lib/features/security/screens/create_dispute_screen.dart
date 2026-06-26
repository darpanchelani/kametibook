import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../../auth/providers/auth_controller.dart';
import '../models/security_models.dart';
import '../providers/security_controller.dart';

class CreateDisputeArgs {
  const CreateDisputeArgs({
    required this.kametiId,
    required this.relatedEntityType,
    required this.relatedEntityId,
    this.defaultType = DisputeType.other,
  });
  final String kametiId;
  final DisputeRelatedEntityType relatedEntityType;
  final String relatedEntityId;
  final DisputeType defaultType;
}

class CreateDisputeScreen extends ConsumerStatefulWidget {
  const CreateDisputeScreen({required this.args, super.key});
  final CreateDisputeArgs args;

  @override
  ConsumerState<CreateDisputeScreen> createState() =>
      _CreateDisputeScreenState();
}

class _CreateDisputeScreenState extends ConsumerState<CreateDisputeScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DisputeType _type = DisputeType.other;
  DisputePriority _priority = DisputePriority.normal;

  @override
  void initState() {
    super.initState();
    _type = widget.args.defaultType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Dispute')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          DropdownButtonFormField<DisputeType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Dispute type'),
            items: DisputeType.values
                .map((type) =>
                    DropdownMenuItem(value: type, child: Text(type.label)))
                .toList(),
            onChanged: (value) =>
                setState(() => _type = value ?? DisputeType.other),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DisputePriority>(
            initialValue: _priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: DisputePriority.values
                .map((priority) => DropdownMenuItem(
                    value: priority, child: Text(priority.label)))
                .toList(),
            onChanged: (value) =>
                setState(() => _priority = value ?? DisputePriority.normal),
          ),
          const SizedBox(height: 12),
          TextField(
              enableSuggestions: false,
              autocorrect: false,
              autofillHints: const <String>[],
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(
              enableSuggestions: false,
              autocorrect: false,
              autofillHints: const <String>[],
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.link_outlined),
              title: Text(widget.args.relatedEntityType.label),
              subtitle: Text(widget.args.relatedEntityId),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Submit Dispute')),
        ]),
      ),
    );
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      SnackbarHelper.showError(context, 'Title and description are required.');
      return;
    }
    final user = ref.read(authControllerProvider).user;
    ref.read(securityControllerProvider.notifier).createDispute(
          kametiId: widget.args.kametiId,
          createdBy: user?.id ?? '',
          createdByName: user?.fullName ?? 'Kameti User',
          againstUserId: '',
          againstUserName: '',
          disputeType: _type,
          relatedEntityType: widget.args.relatedEntityType,
          relatedEntityId: widget.args.relatedEntityId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
        );
    SnackbarHelper.showSuccess(context, 'Dispute submitted successfully.');
    Navigator.of(context).pop();
  }
}
