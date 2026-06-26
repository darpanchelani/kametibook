import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../models/report_model.dart';

class ReportHistoryCard extends StatelessWidget {
  const ReportHistoryCard({
    required this.report,
    required this.onOpen,
    required this.onShare,
    required this.onDelete,
    super.key,
  });

  final ReportModel report;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(report.title,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
            '${report.reportType.label} | ${DateFormatter.display(report.generatedAt)}\n${report.filePath.isEmpty ? 'No PDF exported yet' : report.filePath}'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'open') onOpen();
            if (value == 'share') onShare();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'open', child: Text('Open')),
            PopupMenuItem(value: 'share', child: Text('Share again')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
