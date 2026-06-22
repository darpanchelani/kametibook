import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/providers/auth_controller.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/providers/notification_controller.dart';
import '../models/report_model.dart';
import '../providers/report_controller.dart';
import '../providers/report_pdf_service.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/report_warning_card.dart';

class ReportPreviewScreen extends ConsumerStatefulWidget {
  const ReportPreviewScreen({required this.data, super.key});

  final ReportData data;

  @override
  ConsumerState<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends ConsumerState<ReportPreviewScreen> {
  late ReportData _data;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
  }

  @override
  Widget build(BuildContext context) {
    final hasPdf = _data.model.filePath.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Report Preview')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(_data.model.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(_data.kametiName),
            Text('Generated: ${DateFormatter.display(_data.model.generatedAt)}'),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width > 520 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.25,
              children: [
                for (final entry in _data.summaryCards.entries)
                  ReportSummaryCard(title: entry.key, value: entry.value),
              ],
            ),
            if (_data.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              ReportWarningCard(warnings: _data.warnings),
            ],
            const SizedBox(height: 12),
            for (final section in _data.sections) _ReportPreviewSection(section: section),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.privacy_tip_outlined),
                title: Text('Privacy'),
                subtitle: Text('CNIC is hidden by default. Share reports only with trusted people.'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Export PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  isLoading: _isExporting,
                  onPressed: _exportPdf,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Share',
                  icon: Icons.ios_share_outlined,
                  isOutlined: true,
                  onPressed: hasPdf ? _sharePdf : _shareSummary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final path = await ReportPdfService.exportReportToPdf(_data);
      final updatedModel = _data.model.copyWith(filePath: path, status: ReportStatus.exported);
      setState(() => _data = _data.copyWith(model: updatedModel));
      ref.read(reportControllerProvider.notifier).saveReportHistory(updatedModel);
      ref.read(notificationControllerProvider.notifier).createNotification(
            ref.read(notificationControllerProvider.notifier).buildNotification(
                  userId: ref.read(authControllerProvider).user?.id ?? 'mock-user',
                  kametiId: updatedModel.kametiId,
                  relatedReportId: updatedModel.id,
                  type: AppNotificationType.reportGenerated,
                  title: 'Report Generated',
                  message: '${updatedModel.title} has been generated successfully.',
                  actionType: NotificationActionType.openReport,
                  actionRoute: AppRoutes.reportHistory,
                ),
          );
      if (mounted) SnackbarHelper.showSuccess(context, 'PDF generated successfully.');
    } catch (_) {
      if (mounted) SnackbarHelper.showError(context, 'PDF export failed.');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _sharePdf() async {
    await ReportPdfService.shareReportPdf(_data.model.filePath, text: _data.shareSummary);
    ref.read(reportControllerProvider.notifier).saveReportHistory(_data.model.copyWith(status: ReportStatus.shared));
  }

  Future<void> _shareSummary() async {
    await ReportPdfService.shareReportSummary(_data.shareSummary);
  }
}

class _ReportPreviewSection extends StatelessWidget {
  const _ReportPreviewSection({required this.section});

  final ReportSection section;

  @override
  Widget build(BuildContext context) {
    final rows = section.rows.length <= 7 ? section.rows : section.rows.take(7).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (section.rows.isEmpty)
              const Text('No records.')
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.w900),
                  columns: [for (final cell in rows.first) DataColumn(label: Text(cell))],
                  rows: [
                    for (final row in rows.skip(1))
                      DataRow(cells: [for (final cell in row) DataCell(Text(cell))]),
                  ],
                ),
              ),
            if (section.rows.length > rows.length) ...[
              const SizedBox(height: 8),
              Text('${section.rows.length - rows.length} more rows will be included in the PDF.'),
            ],
          ],
        ),
      ),
    );
  }
}
