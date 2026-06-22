import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../models/security_models.dart';
import '../providers/security_controller.dart';
import '../widgets/security_widgets.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({required this.kametiId, super.key});
  final String kametiId;

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  final _searchController = TextEditingController();
  AuditEntityType? _filter;
  bool _criticalOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(securityControllerProvider);
    final logs = ref.read(securityControllerProvider.notifier).getAuditLogsByKametiId(widget.kametiId).where((log) {
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          log.userName.toLowerCase().contains(query) ||
          log.description.toLowerCase().contains(query) ||
          log.entityType.label.toLowerCase().contains(query);
      final matchesFilter = _filter == null || log.entityType == _filter;
      final matchesCritical = !_criticalOnly || log.severity == AuditSeverity.critical;
      return matchesSearch && matchesFilter && matchesCritical;
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Logs')),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              TextField(controller: _searchController, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Search audit logs', prefixIcon: Icon(Icons.search))),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  ChoiceChip(label: const Text('All'), selected: _filter == null && !_criticalOnly, onSelected: (_) => setState(() { _filter = null; _criticalOnly = false; })),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('Critical'), selected: _criticalOnly, onSelected: (_) => setState(() => _criticalOnly = true)),
                  const SizedBox(width: 8),
                  for (final type in [AuditEntityType.payment, AuditEntityType.member, AuditEntityType.receiverAllocation, AuditEntityType.biddingSession, AuditEntityType.luckyDraw, AuditEntityType.ledgerEntry, AuditEntityType.report, AuditEntityType.dispute]) ...[
                    ChoiceChip(label: Text(type.label), selected: _filter == type, onSelected: (_) => setState(() { _filter = type; _criticalOnly = false; })),
                    const SizedBox(width: 8),
                  ],
                ]),
              ),
            ]),
          ),
          Expanded(
            child: logs.isEmpty
                ? const EmptyState(icon: Icons.history_outlined, title: 'No audit logs yet.')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => AuditLogCard(
                      log: logs[index],
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.auditDetail, arguments: logs[index].id),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}
