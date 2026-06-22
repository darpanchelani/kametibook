import 'package:flutter/material.dart';

class ReminderSettingsTile extends StatelessWidget {
  const ReminderSettingsTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: subtitle == null ? null : Text(subtitle!),
    );
  }
}
