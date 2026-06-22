import 'package:cloud_firestore/cloud_firestore.dart';

import '../../cloud/models/kameti_invite_model.dart';
import '../../kameti/models/kameti_model.dart';
import '../../ledger/models/ledger_entry_model.dart';
import '../../member/models/member_model.dart';
import '../../notifications/models/notification_model.dart';
import '../../payment/models/payment_models.dart';
import '../../receiver/models/receiver_allocation_model.dart';
import '../../reports/models/report_model.dart';
import '../../security/models/security_models.dart';

abstract class KametiRepository {
  Future<void> createKameti(KametiModel kameti);
  Future<void> updateKameti(KametiModel kameti);
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamKameti(String kametiId);
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserKametis(String userId);
  Future<void> startKameti(String kametiId);
}

abstract class MemberRepository {
  Future<void> addMember(MemberModel member);
  Future<KametiInviteModel> inviteMember(KametiInviteModel invite);
  Future<void> acceptInvite(KametiInviteModel invite, String userId);
  Future<void> rejectInvite(String inviteId);
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMembers(String kametiId);
  Future<void> linkMemberToUser({required String kametiId, required String memberId, required String userId});
}

abstract class PaymentRepository {
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCycles(String kametiId);
  Stream<QuerySnapshot<Map<String, dynamic>>> streamPayments(String kametiId, String cycleId);
  Future<void> submitPaymentProof(String kametiId, String cycleId, String paymentId, Map<String, Object?> data);
  Future<void> approvePayment(String kametiId, String cycleId, String paymentId, Map<String, Object?> data);
  Future<void> rejectPayment(String kametiId, String cycleId, String paymentId, String reason);
}

abstract class ReceiverRepository {
  Future<void> confirmReceiver(String kametiId, ReceiverAllocationModel allocation);
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllocations(String kametiId);
  Future<void> markPayoutPaid(String kametiId, String allocationId, Map<String, Object?> data);
}

abstract class BiddingRepository {
  Future<void> startBidding(String kametiId, Map<String, Object?> sessionData);
  Future<void> submitBid(String kametiId, String sessionId, Map<String, Object?> bidData);
  Future<void> updateBid(String kametiId, String sessionId, String bidId, Map<String, Object?> bidData);
  Future<void> withdrawBid(String kametiId, String sessionId, String bidId);
  Future<void> closeBidding(String kametiId, String sessionId);
  Future<void> completeBidding(String kametiId, String sessionId, Map<String, Object?> resultData);
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamBiddingSession(String kametiId, String sessionId);
  Stream<QuerySnapshot<Map<String, dynamic>>> streamBids(String kametiId, String sessionId);
}

abstract class DrawRepository {
  Future<void> saveLuckyDrawResult(String kametiId, Map<String, Object?> drawData);
  Stream<QuerySnapshot<Map<String, dynamic>>> streamDraws(String kametiId);
}

abstract class LedgerRepository {
  Future<void> createLedgerEntry(String kametiId, LedgerEntryModel entry);
  Stream<QuerySnapshot<Map<String, dynamic>>> streamLedgerEntries(String kametiId);
  Future<void> syncLedger(String kametiId);
}

abstract class ReportRepository {
  Future<void> saveReportHistory(String kametiId, ReportModel report);
  Stream<QuerySnapshot<Map<String, dynamic>>> streamReports(String kametiId);
  Future<void> updateReportVisibility(String kametiId, String reportId, ReportVisibility visibility, List<String> memberIds);
}

abstract class NotificationRepository {
  Future<void> createNotification(NotificationModel notification);
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserNotifications(String userId);
  Future<void> markAsRead(String userId, String notificationId);
  Future<void> markAllAsRead(String userId);
}

abstract class AuditLogRepository {
  Future<void> createAuditLog(AuditLogModel log);
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAuditLogs(String kametiId);
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserSecurityLogs(String userId);
}

abstract class DisputeRepository {
  Future<void> createDispute(DisputeModel dispute);
  Future<void> updateDispute(String kametiId, String disputeId, Map<String, Object?> data);
  Future<void> addDisputeComment(DisputeCommentModel comment);
  Future<void> resolveDispute(String kametiId, String disputeId, Map<String, Object?> resolution);
  Stream<QuerySnapshot<Map<String, dynamic>>> streamDisputes(String kametiId);
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserDisputes(String userId);
}

abstract class TrustScoreRepository {
  Future<void> updateTrustScore(TrustScoreModel score);
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamTrustScore(String userId);
  Stream<QuerySnapshot<Map<String, dynamic>>> getRiskyMembers(String kametiId);
}

abstract class SecurityRepository {
  Future<void> reportUser(ReportUserModel report);
  Future<void> blockMember(String kametiId, String memberId, String reason);
  Future<void> unblockMember(String kametiId, String memberId);
  Future<void> createDeletionRequest(DeletionRequestModel request);
  Future<void> updatePrivacySettings(PrivacySettingsModel settings);
}

class FirebaseKametiRepository implements KametiRepository {
  FirebaseKametiRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  @override
  Future<void> createKameti(KametiModel kameti) => _firestore.collection('kametis').doc(kameti.id).set({'id': kameti.id, 'name': kameti.name, 'type': kameti.type.name, 'status': kameti.status.name, 'organizerName': kameti.organizerName, 'createdAt': kameti.createdAt.millisecondsSinceEpoch});

  @override
  Future<void> updateKameti(KametiModel kameti) => _firestore.collection('kametis').doc(kameti.id).update({'name': kameti.name, 'status': kameti.status.name, 'updatedAt': DateTime.now().millisecondsSinceEpoch});

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamKameti(String kametiId) => _firestore.collection('kametis').doc(kametiId).snapshots();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserKametis(String userId) => _firestore.collection('users').doc(userId).collection('joinedKametis').snapshots();

  @override
  Future<void> startKameti(String kametiId) => _firestore.collection('kametis').doc(kametiId).update({'status': KametiStatus.active.name, 'startedAt': DateTime.now().millisecondsSinceEpoch});
}

class FirebaseMemberRepository implements MemberRepository {
  FirebaseMemberRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  @override
  Future<void> addMember(MemberModel member) => _firestore.collection('kametis').doc(member.kametiId).collection('members').doc(member.id).set({'id': member.id, 'userId': member.userId, 'fullName': member.fullName, 'phone': member.phone, 'role': member.role.name, 'status': member.status.name});

  @override
  Future<KametiInviteModel> inviteMember(KametiInviteModel invite) async {
    await _firestore.collection('kametiInvites').doc(invite.id).set(invite.toMap());
    return invite;
  }

  @override
  Future<void> acceptInvite(KametiInviteModel invite, String userId) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('kametiInvites').doc(invite.id), {'status': KametiInviteStatus.accepted.name, 'acceptedAt': DateTime.now().millisecondsSinceEpoch, 'invitedUserId': userId});
    batch.set(_firestore.collection('users').doc(userId).collection('joinedKametis').doc(invite.kametiId), {'kametiId': invite.kametiId, 'role': invite.role.name, 'joinedAt': DateTime.now().millisecondsSinceEpoch});
    await batch.commit();
  }

  @override
  Future<void> rejectInvite(String inviteId) => _firestore.collection('kametiInvites').doc(inviteId).update({'status': KametiInviteStatus.rejected.name});

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMembers(String kametiId) => _firestore.collection('kametis').doc(kametiId).collection('members').snapshots();

  @override
  Future<void> linkMemberToUser({required String kametiId, required String memberId, required String userId}) {
    return _firestore.collection('kametis').doc(kametiId).collection('members').doc(memberId).update({'userId': userId, 'joinedByApp': true, 'linkedAt': DateTime.now().millisecondsSinceEpoch});
  }
}

class FirebasePaymentRepository implements PaymentRepository {
  FirebasePaymentRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCycles(String kametiId) => _firestore.collection('kametis').doc(kametiId).collection('cycles').snapshots();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> streamPayments(String kametiId, String cycleId) => _firestore.collection('kametis').doc(kametiId).collection('cycles').doc(cycleId).collection('payments').snapshots();

  @override
  Future<void> submitPaymentProof(String kametiId, String cycleId, String paymentId, Map<String, Object?> data) => _payment(kametiId, cycleId, paymentId).update({...data, 'paymentStatus': PaymentStatus.pendingApproval.name, 'submittedAt': DateTime.now().millisecondsSinceEpoch});

  @override
  Future<void> approvePayment(String kametiId, String cycleId, String paymentId, Map<String, Object?> data) => _firestore.runTransaction((transaction) async {
        transaction.update(_payment(kametiId, cycleId, paymentId), {...data, 'paymentStatus': PaymentStatus.paid.name, 'approvedAt': DateTime.now().millisecondsSinceEpoch});
      });

  @override
  Future<void> rejectPayment(String kametiId, String cycleId, String paymentId, String reason) => _payment(kametiId, cycleId, paymentId).update({'paymentStatus': PaymentStatus.rejected.name, 'rejectionReason': reason, 'rejectedAt': DateTime.now().millisecondsSinceEpoch});

  DocumentReference<Map<String, dynamic>> _payment(String kametiId, String cycleId, String paymentId) => _firestore.collection('kametis').doc(kametiId).collection('cycles').doc(cycleId).collection('payments').doc(paymentId);
}

class FirebaseReceiverRepository implements ReceiverRepository {
  FirebaseReceiverRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  @override
  Future<void> confirmReceiver(String kametiId, ReceiverAllocationModel allocation) => _firestore.runTransaction((transaction) async {
        final ref = _firestore.collection('kametis').doc(kametiId).collection('receiverAllocations').doc(allocation.id);
        final existing = await transaction.get(ref);
        if (existing.exists) throw StateError('Receiver already confirmed for this cycle.');
        transaction.set(ref, {'id': allocation.id, 'cycleId': allocation.cycleId, 'memberId': allocation.memberId, 'memberName': allocation.memberName, 'amount': allocation.amount, 'allocationType': allocation.allocationType.name, 'status': allocation.status.name});
      });

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllocations(String kametiId) => _firestore.collection('kametis').doc(kametiId).collection('receiverAllocations').snapshots();

  @override
  Future<void> markPayoutPaid(String kametiId, String allocationId, Map<String, Object?> data) => _firestore.collection('kametis').doc(kametiId).collection('receiverAllocations').doc(allocationId).update(data);
}

class FirebaseBiddingRepository implements BiddingRepository {
  FirebaseBiddingRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  @override
  Future<void> startBidding(String kametiId, Map<String, Object?> sessionData) => _session(kametiId, '${sessionData['id']}').set(sessionData);
  @override
  Future<void> submitBid(String kametiId, String sessionId, Map<String, Object?> bidData) => _session(kametiId, sessionId).collection('bids').doc('${bidData['id']}').set(bidData);
  @override
  Future<void> updateBid(String kametiId, String sessionId, String bidId, Map<String, Object?> bidData) => _session(kametiId, sessionId).collection('bids').doc(bidId).update(bidData);
  @override
  Future<void> withdrawBid(String kametiId, String sessionId, String bidId) => _session(kametiId, sessionId).collection('bids').doc(bidId).update({'status': 'withdrawn'});
  @override
  Future<void> closeBidding(String kametiId, String sessionId) => _session(kametiId, sessionId).update({'status': 'closed', 'endTime': DateTime.now().millisecondsSinceEpoch});
  @override
  Future<void> completeBidding(String kametiId, String sessionId, Map<String, Object?> resultData) => _firestore.runTransaction((transaction) async => transaction.update(_session(kametiId, sessionId), resultData));
  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamBiddingSession(String kametiId, String sessionId) => _session(kametiId, sessionId).snapshots();
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> streamBids(String kametiId, String sessionId) => _session(kametiId, sessionId).collection('bids').snapshots();
  DocumentReference<Map<String, dynamic>> _session(String kametiId, String sessionId) => _firestore.collection('kametis').doc(kametiId).collection('biddingSessions').doc(sessionId);
}

class FirebaseDrawRepository implements DrawRepository {
  FirebaseDrawRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;
  @override
  Future<void> saveLuckyDrawResult(String kametiId, Map<String, Object?> drawData) => _firestore.collection('kametis').doc(kametiId).collection('luckyDraws').doc('${drawData['id']}').set(drawData);
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> streamDraws(String kametiId) => _firestore.collection('kametis').doc(kametiId).collection('luckyDraws').snapshots();
}

class FirebaseLedgerRepository implements LedgerRepository {
  FirebaseLedgerRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;
  @override
  Future<void> createLedgerEntry(String kametiId, LedgerEntryModel entry) => _firestore.collection('kametis').doc(kametiId).collection('ledgerEntries').doc(entry.id).set({'id': entry.id, 'entryType': entry.entryType.name, 'direction': entry.direction.name, 'amount': entry.amount, 'memberId': entry.memberId, 'cycleId': entry.cycleId});
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> streamLedgerEntries(String kametiId) => _firestore.collection('kametis').doc(kametiId).collection('ledgerEntries').snapshots();
  @override
  Future<void> syncLedger(String kametiId) async {}
}

class FirebaseReportRepository implements ReportRepository {
  FirebaseReportRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;
  @override
  Future<void> saveReportHistory(String kametiId, ReportModel report) => _firestore.collection('kametis').doc(kametiId).collection('reports').doc(report.id).set({'id': report.id, 'title': report.title, 'type': report.reportType.name, 'visibility': report.visibility.name, 'createdAt': report.createdAt.millisecondsSinceEpoch});
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> streamReports(String kametiId) => _firestore.collection('kametis').doc(kametiId).collection('reports').snapshots();
  @override
  Future<void> updateReportVisibility(String kametiId, String reportId, ReportVisibility visibility, List<String> memberIds) => _firestore.collection('kametis').doc(kametiId).collection('reports').doc(reportId).update({'visibility': visibility.name, 'sharedWithMemberIds': memberIds});
}

class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;
  @override
  Future<void> createNotification(NotificationModel notification) => _firestore.collection('users').doc(notification.userId).collection('notifications').doc(notification.id).set({'id': notification.id, 'title': notification.title, 'message': notification.message, 'type': notification.notificationType.name, 'status': notification.status.name, 'kametiId': notification.kametiId, 'createdAt': notification.createdAt.millisecondsSinceEpoch});
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserNotifications(String userId) => _firestore.collection('users').doc(userId).collection('notifications').snapshots();
  @override
  Future<void> markAsRead(String userId, String notificationId) => _firestore.collection('users').doc(userId).collection('notifications').doc(notificationId).update({'status': NotificationStatus.read.name, 'readAt': DateTime.now().millisecondsSinceEpoch});
  @override
  Future<void> markAllAsRead(String userId) async {
    final docs = await _firestore.collection('users').doc(userId).collection('notifications').get();
    final batch = _firestore.batch();
    for (final doc in docs.docs) {
      batch.update(doc.reference, {'status': NotificationStatus.read.name});
    }
    await batch.commit();
  }
}

class FirebaseAuditLogRepository implements AuditLogRepository {
  FirebaseAuditLogRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;
  @override
  Future<void> createAuditLog(AuditLogModel log) => _firestore.collection('kametis').doc(log.kametiId).collection('auditLogs').doc(log.id).set({'id': log.id, 'userId': log.userId, 'userName': log.userName, 'actionType': log.actionType.name, 'entityType': log.entityType.name, 'entityId': log.entityId, 'description': log.description, 'severity': log.severity.name, 'createdAt': log.createdAt.millisecondsSinceEpoch});
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAuditLogs(String kametiId) => _firestore.collection('kametis').doc(kametiId).collection('auditLogs').snapshots();
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserSecurityLogs(String userId) => _firestore.collection('users').doc(userId).collection('securityLogs').snapshots();
}

class FirebaseDisputeRepository implements DisputeRepository {
  FirebaseDisputeRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;
  @override
  Future<void> createDispute(DisputeModel dispute) => _firestore.collection('kametis').doc(dispute.kametiId).collection('disputes').doc(dispute.id).set({'id': dispute.id, 'createdBy': dispute.createdBy, 'againstUserId': dispute.againstUserId, 'type': dispute.disputeType.name, 'status': dispute.status.name, 'priority': dispute.priority.name, 'title': dispute.title, 'description': dispute.description, 'createdAt': dispute.createdAt.millisecondsSinceEpoch});
  @override
  Future<void> updateDispute(String kametiId, String disputeId, Map<String, Object?> data) => _firestore.collection('kametis').doc(kametiId).collection('disputes').doc(disputeId).update(data);
  @override
  Future<void> addDisputeComment(DisputeCommentModel comment) => _firestore.collection('kametis').doc(comment.kametiId).collection('disputes').doc(comment.disputeId).collection('comments').doc(comment.id).set({'id': comment.id, 'userId': comment.userId, 'userName': comment.userName, 'message': comment.message, 'createdAt': comment.createdAt.millisecondsSinceEpoch});
  @override
  Future<void> resolveDispute(String kametiId, String disputeId, Map<String, Object?> resolution) => updateDispute(kametiId, disputeId, resolution);
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> streamDisputes(String kametiId) => _firestore.collection('kametis').doc(kametiId).collection('disputes').snapshots();
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserDisputes(String userId) => _firestore.collectionGroup('disputes').where('createdBy', isEqualTo: userId).snapshots();
}

class FirebaseTrustScoreRepository implements TrustScoreRepository {
  FirebaseTrustScoreRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;
  @override
  Future<void> updateTrustScore(TrustScoreModel score) => _firestore.collection('users').doc(score.userId).collection('trustScores').doc(score.kametiId.isEmpty ? 'global' : score.kametiId).set({'overallScore': score.overallScore, 'riskLevel': score.riskLevel.name, 'updatedAt': score.updatedAt.millisecondsSinceEpoch});
  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamTrustScore(String userId) => _firestore.collection('users').doc(userId).collection('trustScores').doc('global').snapshots();
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getRiskyMembers(String kametiId) => _firestore.collection('kametis').doc(kametiId).collection('trustScores').where('riskLevel', whereIn: ['risky', 'highRisk']).snapshots();
}

class FirebaseSecurityRepository implements SecurityRepository {
  FirebaseSecurityRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;
  @override
  Future<void> reportUser(ReportUserModel report) => _firestore.collection('kametis').doc(report.kametiId).collection('userReports').doc(report.id).set({'id': report.id, 'reportedUserId': report.reportedUserId, 'reportedBy': report.reportedBy, 'reason': report.reason.name, 'description': report.description, 'status': report.status, 'createdAt': report.createdAt.millisecondsSinceEpoch});
  @override
  Future<void> blockMember(String kametiId, String memberId, String reason) => _firestore.collection('kametis').doc(kametiId).collection('members').doc(memberId).update({'status': 'blocked', 'blockReason': reason});
  @override
  Future<void> unblockMember(String kametiId, String memberId) => _firestore.collection('kametis').doc(kametiId).collection('members').doc(memberId).update({'status': 'active'});
  @override
  Future<void> createDeletionRequest(DeletionRequestModel request) => _firestore.collection('deletionRequests').doc(request.id).set({'id': request.id, 'userId': request.userId, 'reason': request.reason, 'status': request.status, 'requestedAt': request.requestedAt.millisecondsSinceEpoch});
  @override
  Future<void> updatePrivacySettings(PrivacySettingsModel settings) => _firestore.collection('users').doc(settings.userId).collection('settings').doc('privacy').set({'hidePhoneFromMembers': settings.hidePhoneFromMembers, 'hideCityFromMembers': settings.hideCityFromMembers, 'hideCnicInReports': settings.hideCnicInReports, 'allowGroupMembersViewFullLedger': settings.allowGroupMembersViewFullLedger});
}
