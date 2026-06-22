enum AuditActionType {
  kametiCreated('Kameti Created'),
  kametiUpdated('Kameti Updated'),
  kametiStarted('Kameti Started'),
  kametiCancelled('Kameti Cancelled'),
  memberInvited('Member Invited'),
  memberJoined('Member Joined'),
  memberRemoved('Member Removed'),
  memberRoleChanged('Member Role Changed'),
  memberBlocked('Member Blocked'),
  memberUnblocked('Member Unblocked'),
  paymentProofSubmitted('Payment Proof Submitted'),
  paymentApproved('Payment Approved'),
  paymentRejected('Payment Rejected'),
  paymentStatusChanged('Payment Status Changed'),
  payoutMarkedPaid('Payout Marked Paid'),
  payoutProofUpdated('Payout Proof Updated'),
  receiverConfirmed('Receiver Confirmed'),
  receiverCancelled('Receiver Cancelled'),
  luckyDrawStarted('Lucky Draw Started'),
  luckyDrawCompleted('Lucky Draw Completed'),
  biddingStarted('Bidding Started'),
  bidSubmitted('Bid Submitted'),
  bidUpdated('Bid Updated'),
  bidWithdrawn('Bid Withdrawn'),
  biddingClosed('Bidding Closed'),
  biddingCompleted('Bidding Completed'),
  ledgerEntryCreated('Ledger Entry Created'),
  ledgerEntryReversed('Ledger Entry Reversed'),
  reportGenerated('Report Generated'),
  reportShared('Report Shared'),
  disputeCreated('Dispute Created'),
  disputeUpdated('Dispute Updated'),
  disputeResolved('Dispute Resolved'),
  userReported('User Reported'),
  settingsChanged('Settings Changed'),
  securityRuleViolation('Security Rule Violation'),
  manualCorrection('Manual Correction');

  const AuditActionType(this.label);
  final String label;
}

enum AuditEntityType {
  kameti('Kameti'),
  member('Member'),
  payment('Payment'),
  payout('Payout'),
  receiverAllocation('Receiver Allocation'),
  luckyDraw('Lucky Draw'),
  biddingSession('Bidding Session'),
  bid('Bid'),
  ledgerEntry('Ledger Entry'),
  report('Report'),
  dispute('Dispute'),
  notification('Notification'),
  user('User'),
  settings('Settings');

  const AuditEntityType(this.label);
  final String label;
}

enum AuditSeverity {
  low('Low'),
  medium('Medium'),
  high('High'),
  critical('Critical');

  const AuditSeverity(this.label);
  final String label;
}

class AuditLogModel {
  const AuditLogModel({
    required this.id,
    required this.kametiId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.actionType,
    required this.entityType,
    required this.entityId,
    required this.oldValue,
    required this.newValue,
    required this.description,
    required this.ipAddress,
    required this.deviceInfo,
    required this.platform,
    required this.severity,
    required this.createdAt,
  });

  final String id;
  final String kametiId;
  final String userId;
  final String userName;
  final String userRole;
  final AuditActionType actionType;
  final AuditEntityType entityType;
  final String entityId;
  final String oldValue;
  final String newValue;
  final String description;
  final String ipAddress;
  final String deviceInfo;
  final String platform;
  final AuditSeverity severity;
  final DateTime createdAt;
}

enum DisputeType {
  paymentIssue('Payment Issue'),
  payoutIssue('Payout Issue'),
  wrongReceiver('Wrong Receiver'),
  luckyDrawIssue('Lucky Draw Issue'),
  biddingIssue('Bidding Issue'),
  ledgerIssue('Ledger Issue'),
  reportIssue('Report Issue'),
  memberBehavior('Member Behavior'),
  organizerIssue('Organizer Issue'),
  fraudSuspicion('Fraud Suspicion'),
  other('Other');

  const DisputeType(this.label);
  final String label;
}

enum DisputeRelatedEntityType {
  payment('Payment'),
  payout('Payout'),
  receiverAllocation('Receiver Allocation'),
  luckyDraw('Lucky Draw'),
  biddingSession('Bidding Session'),
  bid('Bid'),
  ledgerEntry('Ledger Entry'),
  report('Report'),
  member('Member'),
  kameti('Kameti');

  const DisputeRelatedEntityType(this.label);
  final String label;
}

enum DisputeStatus {
  open('Open'),
  underReview('Under Review'),
  waitingForResponse('Waiting'),
  resolved('Resolved'),
  rejected('Rejected'),
  closed('Closed');

  const DisputeStatus(this.label);
  final String label;
}

enum DisputePriority {
  low('Low'),
  normal('Normal'),
  high('High'),
  urgent('Urgent');

  const DisputePriority(this.label);
  final String label;
}

class DisputeModel {
  const DisputeModel({
    required this.id,
    required this.kametiId,
    required this.createdBy,
    required this.createdByName,
    required this.againstUserId,
    required this.againstUserName,
    required this.disputeType,
    required this.relatedEntityType,
    required this.relatedEntityId,
    required this.title,
    required this.description,
    required this.evidenceUrls,
    required this.status,
    required this.priority,
    required this.assignedTo,
    required this.organizerResponse,
    required this.resolutionNote,
    required this.resolvedBy,
    required this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String kametiId;
  final String createdBy;
  final String createdByName;
  final String againstUserId;
  final String againstUserName;
  final DisputeType disputeType;
  final DisputeRelatedEntityType relatedEntityType;
  final String relatedEntityId;
  final String title;
  final String description;
  final List<String> evidenceUrls;
  final DisputeStatus status;
  final DisputePriority priority;
  final String assignedTo;
  final String organizerResponse;
  final String resolutionNote;
  final String resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DisputeModel copyWith({
    DisputeStatus? status,
    DisputePriority? priority,
    String? organizerResponse,
    String? resolutionNote,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? updatedAt,
  }) {
    return DisputeModel(
      id: id,
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
      evidenceUrls: evidenceUrls,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo,
      organizerResponse: organizerResponse ?? this.organizerResponse,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DisputeCommentModel {
  const DisputeCommentModel({
    required this.id,
    required this.disputeId,
    required this.kametiId,
    required this.userId,
    required this.userName,
    required this.message,
    required this.attachmentUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String disputeId;
  final String kametiId;
  final String userId;
  final String userName;
  final String message;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum RiskLevel {
  excellent('Excellent'),
  good('Good'),
  fair('Fair'),
  risky('Risky'),
  highRisk('High Risk');

  const RiskLevel(this.label);
  final String label;
}

class TrustScoreModel {
  const TrustScoreModel({
    required this.userId,
    required this.memberId,
    required this.kametiId,
    required this.overallScore,
    required this.paymentScore,
    required this.payoutScore,
    required this.biddingScore,
    required this.disputeScore,
    required this.organizerScore,
    required this.riskLevel,
    required this.scoreBreakdown,
    required this.positiveFactors,
    required this.negativeFactors,
    required this.lastCalculatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final String memberId;
  final String kametiId;
  final double overallScore;
  final double paymentScore;
  final double payoutScore;
  final double biddingScore;
  final double disputeScore;
  final double organizerScore;
  final RiskLevel riskLevel;
  final Map<String, double> scoreBreakdown;
  final List<String> positiveFactors;
  final List<String> negativeFactors;
  final DateTime lastCalculatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum ReportUserReason {
  fakePaymentProof('Fake Payment Proof'),
  abusiveBehavior('Abusive Behavior'),
  fraudSuspicion('Fraud Suspicion'),
  defaultedPayment('Defaulted Payment'),
  fakeIdentity('Fake Identity'),
  spam('Spam'),
  other('Other');

  const ReportUserReason(this.label);
  final String label;
}

class ReportUserModel {
  const ReportUserModel({
    required this.id,
    required this.reportedUserId,
    required this.reportedBy,
    required this.kametiId,
    required this.reason,
    required this.description,
    required this.evidenceUrls,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String reportedUserId;
  final String reportedBy;
  final String kametiId;
  final ReportUserReason reason;
  final String description;
  final List<String> evidenceUrls;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class PrivacySettingsModel {
  const PrivacySettingsModel({
    required this.userId,
    this.hidePhoneFromMembers = false,
    this.hideCityFromMembers = false,
    this.hideFinancialAmountInLockScreen = true,
    this.hideCnicInReports = true,
    this.allowMembersDownloadOwnStatement = true,
    this.allowGroupMembersViewFullLedger = false,
  });

  final String userId;
  final bool hidePhoneFromMembers;
  final bool hideCityFromMembers;
  final bool hideFinancialAmountInLockScreen;
  final bool hideCnicInReports;
  final bool allowMembersDownloadOwnStatement;
  final bool allowGroupMembersViewFullLedger;

  PrivacySettingsModel copyWith({
    bool? hidePhoneFromMembers,
    bool? hideCityFromMembers,
    bool? hideFinancialAmountInLockScreen,
    bool? hideCnicInReports,
    bool? allowMembersDownloadOwnStatement,
    bool? allowGroupMembersViewFullLedger,
  }) {
    return PrivacySettingsModel(
      userId: userId,
      hidePhoneFromMembers: hidePhoneFromMembers ?? this.hidePhoneFromMembers,
      hideCityFromMembers: hideCityFromMembers ?? this.hideCityFromMembers,
      hideFinancialAmountInLockScreen: hideFinancialAmountInLockScreen ?? this.hideFinancialAmountInLockScreen,
      hideCnicInReports: hideCnicInReports ?? this.hideCnicInReports,
      allowMembersDownloadOwnStatement: allowMembersDownloadOwnStatement ?? this.allowMembersDownloadOwnStatement,
      allowGroupMembersViewFullLedger: allowGroupMembersViewFullLedger ?? this.allowGroupMembersViewFullLedger,
    );
  }
}

class DeletionRequestModel {
  const DeletionRequestModel({
    required this.id,
    required this.userId,
    required this.reason,
    required this.status,
    required this.requestedAt,
    required this.processedAt,
  });

  final String id;
  final String userId;
  final String reason;
  final String status;
  final DateTime requestedAt;
  final DateTime? processedAt;
}
