import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../models/security_models.dart';
import '../providers/security_controller.dart';
import 'create_dispute_screen.dart';
import '../widgets/security_widgets.dart';

class DisputesScreen extends ConsumerStatefulWidget {
  const DisputesScreen({required this.kametiId, super.key});
  final String kametiId;

  @override
  ConsumerState<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends ConsumerState<DisputesScreen> {
  DisputeStatus? _status;

  @override
  Widget build(BuildContext context) {
    ref.watch(securityControllerProvider);
    final disputes = ref.read(securityControllerProvider.notifier).getDisputesByKametiId(widget.kametiId).where((dispute) {
      return _status == null || dispute.status == _status;
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disputes'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.createDispute,
              arguments: CreateDisputeArgs(kametiId: widget.kametiId, relatedEntityType: DisputeRelatedEntityType.kameti, relatedEntityId: widget.kametiId),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              ChoiceChip(label: const Text('All'), selected: _status == null, onSelected: (_) => setState(() => _status = null)),
              const SizedBox(width: 8),
              for (final status in DisputeStatus.values) ...[
                ChoiceChip(label: Text(status.label), selected: _status == status, onSelected: (_) => setState(() => _status = status)),
                const SizedBox(width: 8),
              ],
            ]),
          ),
          Expanded(
            child: disputes.isEmpty
                ? const EmptyState(icon: Icons.report_problem_outlined, title: 'No disputes yet.')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: disputes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => DisputeCard(
                      dispute: disputes[index],
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.disputeDetail, arguments: disputes[index].id),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}
