import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firebase_bootstrap.dart';
import '../../auth/providers/auth_controller.dart';
import '../models/kameti_model.dart';

class KametiController extends StateNotifier<List<KametiModel>> {
  KametiController(this._ref) : super(const []) {
    _ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final userId = next.user?.id ?? '';
      if (next.status == AuthStatus.authenticated && userId.isNotEmpty) {
        syncForUser(userId);
      } else if (next.status == AuthStatus.unauthenticated ||
          next.status == AuthStatus.profileMissing ||
          next.status == AuthStatus.blocked) {
        clearUserData();
      }
    });

    final userId = _ref.read(authControllerProvider).user?.id ?? '';
    if (userId.isNotEmpty) syncForUser(userId);
  }

  static const _cloudTimeout = Duration(seconds: 45);

  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _joinedSubscription;
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _kametiSubscriptions = {};
  String _syncedUserId = '';

  Future<void> createKameti(KametiModel kameti) async {
    if (FirebaseBootstrap.isInitialized) {
      await _saveCloudKameti(kameti);
    }
    _upsertKameti(kameti);
  }

  Future<void> syncForUser(String userId) async {
    if (userId.isEmpty || _syncedUserId == userId) return;
    _syncedUserId = userId;
    await _cancelCloudSubscriptions();
    state = const [];
    if (!FirebaseBootstrap.isInitialized) return;

    _joinedSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('joinedKametis')
        .snapshots()
        .listen(
      (snapshot) {
        final activeIds = snapshot.docs
            .where((doc) => (doc.data()['status'] ?? 'active') == 'active')
            .map((doc) => doc.id)
            .toSet();

        for (final kametiId in _kametiSubscriptions.keys.toList()) {
          if (!activeIds.contains(kametiId)) {
            _kametiSubscriptions.remove(kametiId)?.cancel();
            _removeKameti(kametiId);
          }
        }

        for (final kametiId in activeIds) {
          _listenToKameti(kametiId);
        }
      },
      onError: (Object error) {
        debugPrint('KametiBook joined kametis sync failed: $error');
      },
    );
  }

  Future<void> clearUserData() async {
    _syncedUserId = '';
    await _cancelCloudSubscriptions();
    state = const [];
  }

  void _upsertKameti(KametiModel kameti) {
    state = [
      kameti,
      for (final item in state)
        if (item.id != kameti.id) item,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<KametiModel> visibleToUser(String userId) {
    if (userId.isEmpty) return const [];
    return state
        .where(
          (kameti) =>
              kameti.ownerUserId == userId ||
              kameti.memberUserIds.contains(userId),
        )
        .toList();
  }

  bool canViewKameti(String kametiId, String userId) {
    final kameti = byId(kametiId);
    if (kameti == null || userId.isEmpty) return false;
    return kameti.ownerUserId == userId ||
        kameti.memberUserIds.contains(userId);
  }

  bool canManageKameti(String kametiId, String userId) {
    final kameti = byId(kametiId);
    if (kameti == null || userId.isEmpty) return false;
    return kameti.ownerUserId == userId;
  }

  void addMemberUser(String kametiId, String userId) {
    if (userId.isEmpty) return;
    state = [
      for (final kameti in state)
        if (kameti.id == kametiId && !kameti.memberUserIds.contains(userId))
          kameti.copyWith(memberUserIds: [...kameti.memberUserIds, userId])
        else
          kameti,
    ];
  }

  KametiModel? byId(String id) {
    for (final kameti in state) {
      if (kameti.id == id) return kameti;
    }
    return null;
  }

  void updateStatus(String id, KametiStatus status) {
    state = [
      for (final kameti in state)
        if (kameti.id == id) kameti.copyWith(status: status) else kameti,
    ];
  }

  void updateRequirePaymentBeforeDraw(String id, bool value) {
    state = [
      for (final kameti in state)
        if (kameti.id == id)
          kameti.copyWith(requirePaymentBeforeDraw: value)
        else
          kameti,
    ];
  }

  void updateRequirePaymentBeforeBidding(String id, bool value) {
    state = [
      for (final kameti in state)
        if (kameti.id == id)
          kameti.copyWith(requirePaymentBeforeBidding: value)
        else
          kameti,
    ];
  }

  void updateDiscountDistributionType(
      String id, DiscountDistributionType value) {
    state = [
      for (final kameti in state)
        if (kameti.id == id)
          kameti.copyWith(discountDistributionType: value)
        else
          kameti,
    ];
  }

  void updateBiddingRules({
    required String id,
    double? minimumBidAmount,
    required String biddingRules,
  }) {
    state = [
      for (final kameti in state)
        if (kameti.id == id)
          kameti.copyWith(
              minimumBidAmount: minimumBidAmount, biddingRules: biddingRules)
        else
          kameti,
    ];
  }

  void updateReceiverSettings({
    required String id,
    bool? requirePaymentBeforeReceiving,
    bool? ownerReceivesFirstCycle,
    AfterOwnerAllocationMode? afterOwnerAllocationMode,
  }) {
    state = [
      for (final kameti in state)
        if (kameti.id == id)
          kameti.copyWith(
            requirePaymentBeforeReceiving: requirePaymentBeforeReceiving,
            ownerReceivesFirstCycle: ownerReceivesFirstCycle,
            afterOwnerAllocationMode: afterOwnerAllocationMode,
          )
        else
          kameti,
    ];
  }

  void updateReminderSettings({
    required String id,
    required bool remindersEnabled,
    required int paymentReminderDaysBefore,
    required bool paymentReminderOnDueDate,
    required bool overdueReminderEnabled,
    required OverdueReminderFrequency overdueReminderFrequency,
    required bool payoutProofReminderEnabled,
    required bool receiverPendingReminderEnabled,
    required bool biddingReminderEnabled,
    required bool luckyDrawReminderEnabled,
    required bool quietHoursEnabled,
    required String quietHoursStart,
    required String quietHoursEnd,
  }) {
    state = [
      for (final kameti in state)
        if (kameti.id == id)
          kameti.copyWith(
            remindersEnabled: remindersEnabled,
            paymentReminderDaysBefore: paymentReminderDaysBefore,
            paymentReminderOnDueDate: paymentReminderOnDueDate,
            overdueReminderEnabled: overdueReminderEnabled,
            overdueReminderFrequency: overdueReminderFrequency,
            payoutProofReminderEnabled: payoutProofReminderEnabled,
            receiverPendingReminderEnabled: receiverPendingReminderEnabled,
            biddingReminderEnabled: biddingReminderEnabled,
            luckyDrawReminderEnabled: luckyDrawReminderEnabled,
            quietHoursEnabled: quietHoursEnabled,
            quietHoursStart: quietHoursStart,
            quietHoursEnd: quietHoursEnd,
          )
        else
          kameti,
    ];
  }

  @override
  void dispose() {
    unawaited(_cancelCloudSubscriptions());
    super.dispose();
  }

  Future<void> _saveCloudKameti(KametiModel kameti) async {
    final batch = _firestore.batch();
    final kametiRef = _firestore.collection('kametis').doc(kameti.id);
    batch.set(kametiRef, kameti.toFirestore());

    if (kameti.ownerUserId.isNotEmpty) {
      final joinedRef = _firestore
          .collection('users')
          .doc(kameti.ownerUserId)
          .collection('joinedKametis')
          .doc(kameti.id);
      batch.set(joinedRef, {
        'kametiId': kameti.id,
        'role': 'organizer',
        'status': 'active',
        'joinedAt': kameti.createdAt.millisecondsSinceEpoch,
      });

      final memberRef = kametiRef.collection('members').doc(kameti.ownerUserId);
      batch.set(memberRef, {
        'id': kameti.ownerUserId,
        'kametiId': kameti.id,
        'userId': kameti.ownerUserId,
        'fullName': kameti.organizerName,
        'phone': '',
        'role': 'organizer',
        'status': 'active',
        'joinedByApp': true,
        'createdAt': kameti.createdAt.millisecondsSinceEpoch,
      });
    }

    try {
      await batch.commit().timeout(
            _cloudTimeout,
            onTimeout: () => throw TimeoutException(
              'Kameti cloud save timed out. Please check your internet connection and try again.',
              _cloudTimeout,
            ),
          );
    } on TimeoutException catch (error) {
      debugPrint('KametiBook cloud save acknowledgement delayed: $error');
    }
  }

  void _listenToKameti(String kametiId) {
    if (_kametiSubscriptions.containsKey(kametiId)) return;
    _kametiSubscriptions[kametiId] =
        _firestore.collection('kametis').doc(kametiId).snapshots().listen(
      (snapshot) {
        if (!snapshot.exists) {
          _removeKameti(kametiId);
          return;
        }
        final data = snapshot.data();
        if (data == null) return;
        _upsertKameti(KametiModel.fromFirestore({
          ...data,
          'id': data['id'] ?? snapshot.id,
        }));
      },
      onError: (Object error) {
        debugPrint('KametiBook kameti sync failed for $kametiId: $error');
      },
    );
  }

  void _removeKameti(String kametiId) {
    state = state.where((kameti) => kameti.id != kametiId).toList();
  }

  Future<void> _cancelCloudSubscriptions() async {
    await _joinedSubscription?.cancel();
    _joinedSubscription = null;
    for (final subscription in _kametiSubscriptions.values) {
      await subscription.cancel();
    }
    _kametiSubscriptions.clear();
  }
}

final kametiControllerProvider =
    StateNotifierProvider<KametiController, List<KametiModel>>((ref) {
  return KametiController(ref);
});
