import 'package:flutter/material.dart';

class SensitiveActionDialog extends StatelessWidget {
  const SensitiveActionDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.requiresTypedConfirm = false,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool requiresTypedConfirm;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (requiresTypedConfirm) ...[
            const SizedBox(height: 12),
            const Text('Type CONFIRM to continue.'),
            TextField(
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const <String>[],
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                controller: controller,
                decoration: const InputDecoration(labelText: 'Confirmation')),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (requiresTypedConfirm && controller.text.trim() != 'CONFIRM') {
              return;
            }
            Navigator.of(context).pop(true);
          },
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

class ReAuthService {
  const ReAuthService();

  Future<bool> requireRecentLogin(BuildContext context,
      {required String action}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SensitiveActionDialog(
        title: 'Confirm Sensitive Action',
        message:
            '$action needs a recent login in cloud mode. For now, confirm to continue in local mode.',
        confirmLabel: 'Confirm',
        requiresTypedConfirm: true,
      ),
    );
    return result == true;
  }
}
