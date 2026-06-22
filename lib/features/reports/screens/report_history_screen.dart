import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/empty_state.dart';
import '../models/report_model.dart';
import '../providers/report_controller.dart';
import '../providers/report_pdf_service.dart';
import '../widgets/report_history_card.dart';

class ReportHistoryScreen extends ConsumerStatefulWidget {
  const ReportHistoryScreen({required this.kametiId, super.key});

  final String kametiId;

  @override
  ConsumerState<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends ConsumerState<ReportHistoryScreen> {
  ReportType? _filter;

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(reportControllerProvider).where((report) {
      return report.kametiId == widget.kametiId && (_filter == null || report.reportType == _filter);
    }).toList()
      ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Report History')),
      body: SafeArea(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ChoiceChip(label: const Text('All'), selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
                  const SizedBox(width: 8),
                  for (final type in ReportType.values) ...[
                    ChoiceChip(label: Text(type.label), selected: _filter == type, onSelected: (_) => setState(() => _filter = type)),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Expanded(
              child: reports.isEmpty
                  ? const EmptyState(icon: Icons.description_outlined, title: 'No reports generated yet.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: reports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        return ReportHistoryCard(
                          report: report,
                          onOpen: () => _openReport(report),
                          onShare: () => _shareReport(report),
                          onDelete: () => ref.read(reportControllerProvider.notifier).deleteReportHistory(report.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReport(ReportModel report) async {
    final file = File(report.filePath);
    if (report.filePath.isEmpty || !await file.exists()) {
      if (mounted) SnackbarHelper.showError(context, 'File not found. Please regenerate report.');
      return;
    }
    await Printing.layoutPdf(name: report.title, onLayout: (_) => file.readAsBytes());
  }

  Future<void> _shareReport(ReportModel report) async {
    final file = File(report.filePath);
    if (report.filePath.isEmpty || !await file.exists()) {
      if (mounted) SnackbarHelper.showError(context, 'File not found. Please regenerate report.');
      return;
    }
    await ReportPdfService.shareReportPdf(report.filePath, text: report.summary);
  }
}
