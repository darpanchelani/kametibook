import 'package:flutter/material.dart';

class ReportWarningCard extends StatelessWidget {
  const ReportWarningCard({required this.warnings, super.key});
  final List<String> warnings;
  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Warnings',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...warnings.map((warning) => Text('- $warning')),
        ]),
      ),
    );
  }
}
