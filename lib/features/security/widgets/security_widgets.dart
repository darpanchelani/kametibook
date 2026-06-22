import 'package:flutter/material.dart';

import '../../../core/utils/date_formatter.dart';
import '../models/security_models.dart';

class AuditSeverityBadge extends StatelessWidget {
  const AuditSeverityBadge({required this.severity, super.key});
  final AuditSeverity severity;
  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      AuditSeverity.low => Colors.blueGrey,
      AuditSeverity.medium => Colors.orange,
      AuditSeverity.high => Colors.deepOrange,
      AuditSeverity.critical => Colors.red,
    };
    return _Badge(label: severity.label, color: color);
  }
}

class AuditLogCard extends StatelessWidget {
  const AuditLogCard({required this.log, required this.onTap, super.key});
  final AuditLogModel log;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.history_outlined),
        title: Text(log.actionType.label, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('${log.userName} | ${log.entityType.label}\n${log.description}'),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AuditSeverityBadge(severity: log.severity),
            const SizedBox(height: 4),
            Text(DateFormatter.display(log.createdAt), style: const TextStyle(fontSize: 11)),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class DisputeStatusBadge extends StatelessWidget {
  const DisputeStatusBadge({required this.status, super.key});
  final DisputeStatus status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      DisputeStatus.open => Colors.orange,
      DisputeStatus.underReview => Colors.blue,
      DisputeStatus.waitingForResponse => Colors.purple,
      DisputeStatus.resolved => Colors.green,
      DisputeStatus.rejected => Colors.red,
      DisputeStatus.closed => Colors.blueGrey,
    };
    return _Badge(label: status.label, color: color);
  }
}

class DisputePriorityBadge extends StatelessWidget {
  const DisputePriorityBadge({required this.priority, super.key});
  final DisputePriority priority;
  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      DisputePriority.low => Colors.blueGrey,
      DisputePriority.normal => Colors.teal,
      DisputePriority.high => Colors.orange,
      DisputePriority.urgent => Colors.red,
    };
    return _Badge(label: priority.label, color: color);
  }
}

class DisputeCard extends StatelessWidget {
  const DisputeCard({required this.dispute, required this.onTap, super.key});
  final DisputeModel dispute;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.report_problem_outlined),
        title: Text(dispute.title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('${dispute.disputeType.label} | Created by ${dispute.createdByName}\n${dispute.relatedEntityType.label}: ${dispute.relatedEntityId}'),
        isThreeLine: true,
        trailing: Wrap(direction: Axis.vertical, spacing: 6, children: [
          DisputeStatusBadge(status: dispute.status),
          DisputePriorityBadge(priority: dispute.priority),
        ]),
        onTap: onTap,
      ),
    );
  }
}

class DisputeCommentCard extends StatelessWidget {
  const DisputeCommentCard({required this.comment, super.key});
  final DisputeCommentModel comment;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.comment_outlined),
        title: Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('${comment.message}\n${DateFormatter.display(comment.createdAt)}'),
        isThreeLine: true,
      ),
    );
  }
}

class RiskLevelBadge extends StatelessWidget {
  const RiskLevelBadge({required this.riskLevel, super.key});
  final RiskLevel riskLevel;
  @override
  Widget build(BuildContext context) {
    final color = switch (riskLevel) {
      RiskLevel.excellent => Colors.green,
      RiskLevel.good => Colors.teal,
      RiskLevel.fair => Colors.orange,
      RiskLevel.risky => Colors.deepOrange,
      RiskLevel.highRisk => Colors.red,
    };
    return _Badge(label: riskLevel.label, color: color);
  }
}

class TrustScoreCard extends StatelessWidget {
  const TrustScoreCard({required this.score, this.onTap, super.key});
  final TrustScoreModel score;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(score.overallScore.round().toString())),
        title: const Text('Trust Score', style: TextStyle(fontWeight: FontWeight.w900)),
        subtitle: const Text('Based on payments, disputes, bidding, and organizer activity.'),
        trailing: RiskLevelBadge(riskLevel: score.riskLevel),
        onTap: onTap,
      ),
    );
  }
}

class TrustScoreBreakdown extends StatelessWidget {
  const TrustScoreBreakdown({required this.score, super.key});
  final TrustScoreModel score;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Score Breakdown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          for (final entry in score.scoreBreakdown.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text(entry.key)),
                Text(entry.value.round().toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
              ]),
            ),
        ]),
      ),
    );
  }
}

class SecurityWarningCard extends StatelessWidget {
  const SecurityWarningCard({required this.message, super.key});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.withValues(alpha: 0.12),
      child: ListTile(leading: const Icon(Icons.warning_amber_outlined, color: Colors.orange), title: Text(message)),
    );
  }
}

class PrivacySettingTile extends StatelessWidget {
  const PrivacySettingTile({required this.title, required this.value, required this.onChanged, this.subtitle, super.key});
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(value: value, onChanged: onChanged, title: Text(title), subtitle: subtitle == null ? null : Text(subtitle!));
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final MaterialColor color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color.shade700, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}
