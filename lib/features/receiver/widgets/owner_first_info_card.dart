import 'package:flutter/material.dart';

class OwnerFirstInfoCard extends StatelessWidget {
  const OwnerFirstInfoCard({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.admin_panel_settings_outlined),
        title: const Text('Owner First'),
        subtitle: Text(message),
      ),
    );
  }
}
