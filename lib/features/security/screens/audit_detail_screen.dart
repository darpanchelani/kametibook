import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatter.dart';
import '../providers/security_controller.dart';
import '../widgets/security_widgets.dart';

class AuditDetailScreen extends ConsumerWidget {
  const AuditDetailScreen({required this.auditId, super.key});
  final String auditId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(securityControllerProvider).auditLogs.where((item) => item.id == auditId).firstOrNull;
    if (log == null) return Scaffold(appBar: AppBar(title: const Text('Audit Detail')), body: const Center(child: Text('Audit log not found')));
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Detail')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(log.actionType.label, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                AuditSeverityBadge(severity: log.severity),
                const SizedBox(height: 12),
                _Line(label: 'User', value: '${log.userName} (${log.userRole.isEmpty ? 'role not set' : log.userRole})'),
                _Line(label: 'Entity', value: '${log.entityType.label} - ${log.entityId}'),
                _Line(label: 'Old Value', value: log.oldValue.isEmpty ? '-' : log.oldValue),
                _Line(label: 'New Value', value: log.newValue.isEmpty ? '-' : log.newValue),
                _Line(label: 'Description', value: log.description),
                _Line(label: 'Platform', value: log.platform),
                _Line(label: 'Device', value: log.deviceInfo.isEmpty ? '-' : log.deviceInfo),
                _Line(label: 'Created', value: DateFormatter.display(log.createdAt)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 115, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800))),
        ]),
      );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
