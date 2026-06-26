import 'package:flutter/material.dart';

class AlertBanner extends StatelessWidget {
  const AlertBanner(
      {required this.title,
      required this.message,
      required this.onTap,
      super.key});

  final String title;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.withValues(alpha: 0.12),
      child: ListTile(
        leading: const Icon(Icons.warning_amber_outlined, color: Colors.orange),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(message),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
