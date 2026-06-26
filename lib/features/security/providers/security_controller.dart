import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ledger/models/ledger_entry_model.dart';
import '../../member/models/member_model.dart';
import '../../payment/models/payment_models.dart';
import '../models/security_models.dart';

class SecurityState {
  const SecurityState({
    this.auditLogs = const [],
    this.disputes = const [],
    this.comments = const [],
    this.reports = const [],
    this.deletionRequests = const [],
    this.privacySettings = const {},
  });

  final List<AuditLogModel> auditLogs;
  final List<DisputeModel> disputes;
  final List<DisputeCommentModel> comments;
  final List<ReportUserModel> reports;
  final List<DeletionRequestModel> deletionRequests;
  final Map<String, PrivacySettingsModel> privacySettings;

  SecurityState copyWith({
    List<AuditLogModel>? auditLogs,
    List<DisputeModel>? disputes,
    List<DisputeCommentModel>? comments,
    List<ReportUserModel>? reports,
    List<DeletionRequestModel>? deletionRequests,
    Map<String, PrivacySettingsModel>? privacySettings,
  }) {
    return SecurityState(
      auditLogs: auditLogs ?? this.auditLogs,
      disputes: disputes ?? this.disputes,
      comments: comments ?? this.comments,
      reports: reports ?? this.reports,
      deletionRequests: deletionRequests ?? this.deletionRequests,
      privacySettings: privacySettings ?? this.privacySettings,
    );
  }
}

class SecurityController extends StateNotifier<SecurityState> {
  SecurityController() : super(const SecurityState());

  void createAuditLog({
    required String kametiId,
    required String userId,
    required String userName,
    required String userRole,
    required AuditActionType actionType,
    required AuditEntityType entityType,
    required String entityId,
    required String description,
    String oldValue = '',
    String newValue = '',
    AuditSeverity severity = AuditSeverity.low,
  }) {
    final now = DateTime.now();
    final log = AuditLogModel(
      id: 'audit-${now.microsecondsSinceEpoch}',
      kametiId: kametiId,
      userId: userId,
      userName: userName,
      userRole: userRole,
      actionType: actionType,
      entityType: entityType,
      entityId: entityId,
      oldValue: oldValue,
      newValue: newValue,
      description: description,
      ipAddress: '',
      deviceInfo: '',
      platform: 'Flutter',
      severity: severity,
      createdAt: now,
    );
    state = state.copyWith(auditLogs: [log, ...state.auditLogs]);
  }

  List<AuditLogModel> getAuditLogsByKametiId(String kametiId) {
    final logs =
        state.auditLogs.where((log) => log.kametiId == kametiId).toList();
    logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return logs;
  }

  List<AuditLogModel> getAuditLogsByEntity(
      AuditEntityType entityType, String entityId) {
    return state.auditLogs
        .where(
            (log) => log.entityType == entityType && log.entityId == entityId)
        .toList();
  }

  AuditLogModel? getAuditLog(String id) {
    for (final log in state.auditLogs) {
      if (log.id == id) return log;
    }
    return null;
  }

  DisputeModel createDispute({
    required String kametiId,
    required String createdBy,
    required String createdByName,
    required String againstUserId,
    required String againstUserName,
    required DisputeType disputeType,
    required DisputeRelatedEntityType relatedEntityType,
    required String relatedEntityId,
    required String title,
    required String description,
    required DisputePriority priority,
  }) {
    final now = DateTime.now();
    final dispute = DisputeModel(
      id: 'dispute-${now.microsecondsSinceEpoch}',
      kametiId: kametiId,
      createdBy: createdBy,
      createdByName: createdByName,
      againstUserId: againstUserId,
      againstUserName: againstUserName,
      disputeType: disputeType,
      relatedEntityType: relatedEntityType,
      relatedEntityId: relatedEntityId,
      title: title,
      description: description,
      evidenceUrls: const [],
      status: DisputeStatus.open,
      priority: priority,
      assignedTo: '',
      organizerResponse: '',
      resolutionNote: '',
      resolvedBy: '',
      resolvedAt: null,
      createdAt: now,
      updatedAt: now,
    );
    state = state.copyWith(disputes: [dispute, ...state.disputes]);
    createAuditLog(
      kametiId: kametiId,
      userId: createdBy,
      userName: createdByName,
      userRole: '',
      actionType: AuditActionType.disputeCreated,
      entityType: AuditEntityType.dispute,
      entityId: dispute.id,
      description: 'Dispute created: $title',
      severity: AuditSeverity.medium,
    );
    return dispute;
  }

  void updateDisputeStatus({
    required String disputeId,
    required DisputeStatus status,
    required String userId,
    required String userName,
    String response = '',
    String resolutionNote = '',
  }) {
    DisputeModel? updated;
    state = state.copyWith(
      disputes: [
        for (final dispute in state.disputes)
          if (dispute.id == disputeId)
            updated = dispute.copyWith(
              status: status,
              organizerResponse: response.isEmpty ? null : response,
              resolutionNote: resolutionNote.isEmpty ? null : resolutionNote,
              resolvedBy: status == DisputeStatus.resolved ? userId : null,
              resolvedAt:
                  status == DisputeStatus.resolved ? DateTime.now() : null,
              updatedAt: DateTime.now(),
            )
          else
            dispute,
      ],
    );
    if (updated == null) return;
    createAuditLog(
      kametiId: updated.kametiId,
      userId: userId,
      userName: userName,
      userRole: '',
      actionType: status == DisputeStatus.resolved
          ? AuditActionType.disputeResolved
          : AuditActionType.disputeUpdated,
      entityType: AuditEntityType.dispute,
      entityId: disputeId,
      newValue: status.name,
      description: 'Dispute status updated to ${status.label}.',
      severity: status == DisputeStatus.resolved
          ? AuditSeverity.high
          : AuditSeverity.medium,
    );
  }

  void addDisputeComment({
    required String disputeId,
    required String kametiId,
    required String userId,
    required String userName,
    required String message,
  }) {
    final now = DateTime.now();
    final comment = DisputeCommentModel(
      id: 'comment-${now.microsecondsSinceEpoch}',
      disputeId: disputeId,
      kametiId: kametiId,
      userId: userId,
      userName: userName,
      message: message,
      attachmentUrls: const [],
      createdAt: now,
      updatedAt: now,
    );
    state = state.copyWith(comments: [comment, ...state.comments]);
  }

  List<DisputeModel> getDisputesByKametiId(String kametiId) {
    final disputes = state.disputes
        .where((dispute) => dispute.kametiId == kametiId)
        .toList();
    disputes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return disputes;
  }

  DisputeModel? getDispute(String disputeId) {
    for (final dispute in state.disputes) {
      if (dispute.id == disputeId) return dispute;
    }
    return null;
  }

  List<DisputeCommentModel> getComments(String disputeId) {
    final comments = state.comments
        .where((comment) => comment.disputeId == disputeId)
        .toList();
    comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return comments;
  }

  TrustScoreModel calculateMemberTrustScore({
    required MemberModel member,
    required List<MemberPaymentModel> payments,
    required List<LedgerEntryModel> ledgerEntries,
  }) {
    final memberPayments =
        payments.where((payment) => payment.memberId == member.id).toList();
    final late = memberPayments
        .where((payment) => payment.paymentStatus == PaymentStatus.late)
        .length;
    final rejected = memberPayments
        .where((payment) => payment.paymentStatus == PaymentStatus.rejected)
        .length;
    final paid = memberPayments
        .where((payment) => payment.paymentStatus == PaymentStatus.paid)
        .length;
    final disputesCreated = state.disputes
        .where((dispute) =>
            dispute.createdBy == member.userId ||
            dispute.createdBy == member.id)
        .length;
    final disputesAgainst = state.disputes
        .where((dispute) =>
            dispute.againstUserId == member.userId ||
            dispute.againstUserId == member.id)
        .length;
    final manualCorrections = ledgerEntries
        .where((entry) =>
            entry.memberId == member.id &&
            entry.entryType == LedgerEntryType.correction)
        .length;

    final paymentScore =
        (70 + paid * 4 - late * 10 - rejected * 15).clamp(0, 100).toDouble();
    final payoutScore = member.hasReceivedKameti ? 75.0 : 70.0;
    const biddingScore = 70.0;
    final disputeScore = (80 - disputesAgainst * 15 - disputesCreated * 3)
        .clamp(0, 100)
        .toDouble();
    final organizerScore = member.canManageGroup
        ? (75 - manualCorrections * 8).clamp(0, 100).toDouble()
        : 70.0;
    final overall = paymentScore * 0.40 +
        payoutScore * 0.20 +
        biddingScore * 0.15 +
        disputeScore * 0.15 +
        organizerScore * 0.10;
    final now = DateTime.now();
    return TrustScoreModel(
      userId: member.userId,
      memberId: member.id,
      kametiId: member.kametiId,
      overallScore: overall,
      paymentScore: paymentScore,
      payoutScore: payoutScore,
      biddingScore: biddingScore,
      disputeScore: disputeScore,
      organizerScore: organizerScore,
      riskLevel: _riskLevel(overall),
      scoreBreakdown: {
        'Payment': paymentScore,
        'Payout': payoutScore,
        'Bidding': biddingScore,
        'Dispute': disputeScore,
        'Organizer': organizerScore,
      },
      positiveFactors: [
        if (paid > 0) 'Paid $paid cycle(s).',
        if (disputesAgainst == 0) 'No active disputes against this member.',
      ],
      negativeFactors: [
        if (late > 0) '$late late payment(s).',
        if (rejected > 0) '$rejected rejected payment proof(s).',
        if (disputesAgainst > 0)
          '$disputesAgainst dispute(s) raised against this member.',
      ],
      lastCalculatedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  List<MemberModel> getRiskyMembers({
    required List<MemberModel> members,
    required List<MemberPaymentModel> payments,
    required List<LedgerEntryModel> ledgerEntries,
  }) {
    return members.where((member) {
      final score = calculateMemberTrustScore(
          member: member, payments: payments, ledgerEntries: ledgerEntries);
      return score.riskLevel == RiskLevel.risky ||
          score.riskLevel == RiskLevel.highRisk;
    }).toList();
  }

  void reportUser(ReportUserModel report) {
    state = state.copyWith(reports: [report, ...state.reports]);
    createAuditLog(
      kametiId: report.kametiId,
      userId: report.reportedBy,
      userName: report.reportedBy,
      userRole: '',
      actionType: AuditActionType.userReported,
      entityType: AuditEntityType.user,
      entityId: report.reportedUserId,
      description: 'User reported for ${report.reason.label}.',
      severity: AuditSeverity.high,
    );
  }

  PrivacySettingsModel privacySettingsFor(String userId) =>
      state.privacySettings[userId] ?? PrivacySettingsModel(userId: userId);

  void updatePrivacySettings(PrivacySettingsModel settings) {
    state = state.copyWith(
        privacySettings: {...state.privacySettings, settings.userId: settings});
  }

  void createDeletionRequest(String userId, String reason) {
    final now = DateTime.now();
    final request = DeletionRequestModel(
      id: 'delete-${now.microsecondsSinceEpoch}',
      userId: userId,
      reason: reason,
      status: 'pending',
      requestedAt: now,
      processedAt: null,
    );
    state =
        state.copyWith(deletionRequests: [request, ...state.deletionRequests]);
  }

  RiskLevel _riskLevel(double score) {
    if (score >= 90) return RiskLevel.excellent;
    if (score >= 75) return RiskLevel.good;
    if (score >= 60) return RiskLevel.fair;
    if (score >= 40) return RiskLevel.risky;
    return RiskLevel.highRisk;
  }
}

final securityControllerProvider =
    StateNotifierProvider<SecurityController, SecurityState>(
        (ref) => SecurityController());
