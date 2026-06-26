import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../auth/providers/auth_controller.dart';
import '../models/security_models.dart';
import '../providers/security_controller.dart';
import '../widgets/security_widgets.dart';

class DisputeDetailScreen extends ConsumerStatefulWidget {
  const DisputeDetailScreen({required this.disputeId, super.key});
  final String disputeId;

  @override
  ConsumerState<DisputeDetailScreen> createState() =>
      _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends ConsumerState<DisputeDetailScreen> {
  final _commentController = TextEditingController();
  final _responseController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(securityControllerProvider);
    final controller = ref.read(securityControllerProvider.notifier);
    final dispute = controller.getDispute(widget.disputeId);
    if (dispute == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Dispute Detail')),
          body: const Center(child: Text('Dispute not found')));
    }
    final comments = controller.getComments(dispute.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Dispute Detail')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dispute.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      DisputeStatusBadge(status: dispute.status),
                      DisputePriorityBadge(priority: dispute.priority)
                    ]),
                    const SizedBox(height: 12),
                    Text(dispute.description),
                    const SizedBox(height: 12),
                    Text('Type: ${dispute.disputeType.label}'),
                    Text(
                        'Related: ${dispute.relatedEntityType.label} - ${dispute.relatedEntityId}'),
                    Text('Created by: ${dispute.createdByName}'),
                    Text(
                        'Created: ${DateFormatter.display(dispute.createdAt)}'),
                    if (dispute.organizerResponse.isNotEmpty)
                      Text('Organizer response: ${dispute.organizerResponse}'),
                    if (dispute.resolutionNote.isNotEmpty)
                      Text('Resolution: ${dispute.resolutionNote}'),
                  ]),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
              enableSuggestions: false,
              autocorrect: false,
              autofillHints: const <String>[],
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              controller: _responseController,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Response / resolution note')),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton(
                onPressed: () => _setStatus(dispute, DisputeStatus.underReview),
                child: const Text('Under Review')),
            OutlinedButton(
                onPressed: () =>
                    _setStatus(dispute, DisputeStatus.waitingForResponse),
                child: const Text('Request Response')),
            FilledButton(
                onPressed: () => _setStatus(dispute, DisputeStatus.resolved),
                child: const Text('Resolve')),
            OutlinedButton(
                onPressed: () => _setStatus(dispute, DisputeStatus.rejected),
                child: const Text('Reject')),
            OutlinedButton(
                onPressed: () => _setStatus(dispute, DisputeStatus.closed),
                child: const Text('Close')),
          ]),
          const SizedBox(height: 18),
          Text('Comments',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          TextField(
              enableSuggestions: false,
              autocorrect: false,
              autofillHints: const <String>[],
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              controller: _commentController,
              decoration: const InputDecoration(labelText: 'Add comment')),
          const SizedBox(height: 8),
          FilledButton.icon(
              onPressed: () => _addComment(dispute),
              icon: const Icon(Icons.comment_outlined),
              label: const Text('Add Comment')),
          const SizedBox(height: 8),
          if (comments.isEmpty)
            const Text('No comments yet.')
          else
            ...comments.map((comment) => DisputeCommentCard(comment: comment)),
        ]),
      ),
    );
  }

  void _setStatus(DisputeModel dispute, DisputeStatus status) {
    final user = ref.read(authControllerProvider).user;
    ref.read(securityControllerProvider.notifier).updateDisputeStatus(
          disputeId: dispute.id,
          status: status,
          userId: user?.id ?? '',
          userName: user?.fullName ?? 'Organizer',
          response: _responseController.text.trim(),
          resolutionNote: _responseController.text.trim(),
        );
    SnackbarHelper.showSuccess(context, 'Dispute updated.');
  }

  void _addComment(DisputeModel dispute) {
    final message = _commentController.text.trim();
    if (message.isEmpty) return;
    final user = ref.read(authControllerProvider).user;
    ref.read(securityControllerProvider.notifier).addDisputeComment(
          disputeId: dispute.id,
          kametiId: dispute.kametiId,
          userId: user?.id ?? '',
          userName: user?.fullName ?? 'Kameti User',
          message: message,
        );
    _commentController.clear();
  }
}
