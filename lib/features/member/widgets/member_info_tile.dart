import 'package:flutter/material.dart';

class MemberInfoTile extends StatelessWidget {
  const MemberInfoTile({
    required this.label,
    required this.value,
    this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: icon == null ? null : Icon(icon),
      title: Text(label, style: const TextStyle(color: Colors.black54)),
      subtitle: Text(
        value.isEmpty ? '-' : value,
        style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
      ),
    );
  }
}
