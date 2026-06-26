import 'package:flutter/material.dart';

class DrawSettingsTile extends StatelessWidget {
  const DrawSettingsTile({
    required this.value,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        title: const Text('Require payment before draw'),
        subtitle:
            const Text('Only paid members in the current cycle are eligible.'),
      ),
    );
  }
}
