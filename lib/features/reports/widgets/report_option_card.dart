import 'package:flutter/material.dart';

class ReportOptionCard extends StatelessWidget {
  const ReportOptionCard({
    required this.title,
    required this.description,
    required this.onGenerate,
    this.enabled = true,
    this.disabledReason,
    super.key,
  });

  final String title;
  final String description;
  final VoidCallback onGenerate;
  final bool enabled;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(enabled ? description : disabledReason ?? description),
        trailing: FilledButton(
            onPressed: enabled ? onGenerate : null,
            child: const Text('Generate')),
      ),
    );
  }
}
