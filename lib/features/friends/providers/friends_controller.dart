import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firebase_bootstrap.dart';
import '../../auth/providers/auth_controller.dart';
import '../../cloud/models/user_profile_model.dart';
import '../models/friend_models.dart';

class FriendsState {
  const FriendsState({
    this.friends = const <FriendModel>[],
    this.chats = const <ChatThreadModel>[],
    this.incomingRequests = const <FriendRequestModel>[],
    this.outgoingRequests = const <FriendRequestModel>[],
    this.searchResults = const <FriendSearchResult>[],
    this.isSearching = false,
    this.errorMessage = '',
  });

  final List<FriendModel> friends;
  final List<ChatThreadModel> chats;
  final List<FriendRequestModel> incomingRequests;
  final List<FriendRequestModel> outgoingRequests;
  final List<FriendSearchResult> searchResults;
  final bool isSearching;
  final String errorMessage;

  FriendsState copyWith({
    List<FriendModel>? friends,
    List<ChatThreadModel>? chats,
    List<FriendRequestModel>? incomingRequests,
    List<FriendRequestModel>? outgoingRequests,
    List<FriendSearchResult>? searchResults,
    bool? isSearching,
    String? errorMessage,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      chats: chats ?? this.chats,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      outgoingRequests: outgoingRequests ?? this.outgoingRequests,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FriendsController extends StateNotifier<FriendsState> {
  FriendsController(this._ref) : super(const FriendsState()) {
    _ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final userId = next.user?.id ?? '';
      if (next.status == AuthStatus.authenticated && userId.isNotEmpty) {
        syncForUser(userId);
      } else {
        clearUserData();
      }
    });

    final userId = _ref.read(authControllerProvider).user?.id ?? '';
    if (userId.isNotEmpty) syncForUser(userId);
  }

  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _friendsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _incomingRequestsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _outgoingRequestsSub;
  String _syncedUserId = '';
  final Set<String> _repairAttemptedKeys = <String>{};

  Future<void> syncForUser(String userId) async {
    if (userId.isEmpty || _syncedUserId == userId) return;
    _syncedUserId = userId;
    await _cancelSubscriptions();
    state = const FriendsState();
    if (!FirebaseBootstrap.isInitialized) return;

    _friendsSub = _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .orderBy('friendName')
        .snapshots()
        .listen(
      (snapshot) {
        final friends = snapshot.docs
            .map((doc) => FriendModel.fromMap({
                  ...doc.data(),
                  'friendUserId': doc.data()['friendUserId'] ?? doc.id,
                }))
            .where((friend) => friend.isActive)
            .toList();
        state = state.copyWith(friends: friends);
        unawaited(_repairExistingFriendEdges(userId, friends));
      },
      onError: (Object error) {
        debugPrint('KametiBook friends sync failed: $error');
      },
    );

    _chatsSub = _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .listen(
      (snapshot) {
        final chats = snapshot.docs
            .map((doc) => ChatThreadModel.fromMap({
                  ...doc.data(),
                  'id': doc.data()['id'] ?? doc.id,
                }))
            .toList()
          ..sort((a, b) {
            final aDate = a.lastMessageAt ?? a.updatedAt;
            final bDate = b.lastMessageAt ?? b.updatedAt;
            return bDate.compareTo(aDate);
          });
        state = state.copyWith(chats: chats);
      },
      onError: (Object error) {
        debugPrint('KametiBook chats sync failed: $error');
      },
    );

    _incomingRequestsSub = _firestore
        .collection('friendRequests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .snapshots()
        .listen(
      (snapshot) {
        final requests = snapshot.docs
            .map((doc) => FriendRequestModel.fromMap({
                  ...doc.data(),
                  'id': doc.data()['id'] ?? doc.id,
                }))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = state.copyWith(incomingRequests: requests);
      },
      onError: (Object error) {
        debugPrint('KametiBook incoming friend requests sync failed: $error');
      },
    );

    _outgoingRequestsSub = _firestore
        .collection('friendRequests')
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .snapshots()
        .listen(
      (snapshot) {
        final requests = snapshot.docs
            .map((doc) => FriendRequestModel.fromMap({
                  ...doc.data(),
                  'id': doc.data()['id'] ?? doc.id,
                }))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = state.copyWith(outgoingRequests: requests);
      },
      onError: (Object error) {
        debugPrint('KametiBook outgoing friend requests sync failed: $error');
      },
    );
  }

  Future<void> clearUserData() async {
    _syncedUserId = '';
    _repairAttemptedKeys.clear();
    await _cancelSubscriptions();
    state = const FriendsState();
  }

  Future<void> searchUsers(String rawQuery) async {
    final currentUser = _ref.read(authControllerProvider).user;
    final currentUserId = currentUser?.id ?? '';
    final query = rawQuery.trim().toLowerCase();
    if (query.length < 2) {
      state = state.copyWith(
        searchResults: const <FriendSearchResult>[],
        errorMessage: 'Enter at least 2 characters to search friends.',
      );
      return;
    }
    if (!FirebaseBootstrap.isInitialized) {
      state = state.copyWith(
        searchResults: const <FriendSearchResult>[],
        errorMessage: 'Firebase is required to search friends.',
      );
      return;
    }

    state = state.copyWith(isSearching: true, errorMessage: '');
    try {
      final byId = <String, UserProfileModel>{};
      final exactUsername =
          await _findByExactUsername(query).timeout(const Duration(seconds: 8));
      if (exactUsername != null) {
        byId[exactUsername.id] = exactUsername;
      }

      final collection = _firestore.collection('publicUserProfiles');
      final snapshots = await Future.wait([
        collection
            .where('usernameLower', isGreaterThanOrEqualTo: query)
            .where('usernameLower', isLessThanOrEqualTo: '$query\uf8ff')
            .orderBy('usernameLower')
            .limit(10)
            .get(),
        collection
            .where('fullNameLower', isGreaterThanOrEqualTo: query)
            .where('fullNameLower', isLessThanOrEqualTo: '$query\uf8ff')
            .orderBy('fullNameLower')
            .limit(10)
            .get(),
        collection
            .where('searchKeywords', arrayContains: query)
            .limit(10)
            .get(),
      ]).timeout(const Duration(seconds: 12));

      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          byId[doc.id] = UserProfileModel.fromMap({
            ...doc.data(),
            'id': doc.data()['id'] ?? doc.id,
          });
        }
      }

      final friendIds =
          state.friends.map((friend) => friend.friendUserId).toSet();
      final outgoingByUserId = {
        for (final request in state.outgoingRequests) request.toUserId: request,
      };
      final incomingByUserId = {
        for (final request in state.incomingRequests)
          request.fromUserId: request,
      };
      final results = byId.values
          .where(
              (profile) => profile.id.isNotEmpty && profile.id != currentUserId)
          .map((profile) => FriendSearchResult(
                profile: profile,
                isFriend: friendIds.contains(profile.id),
                outgoingRequest: outgoingByUserId[profile.id],
                incomingRequest: incomingByUserId[profile.id],
              ))
          .toList()
        ..sort((a, b) => a.profile.fullName.compareTo(b.profile.fullName));

      state = state.copyWith(
        searchResults: results,
        errorMessage: results.isEmpty ? 'No account found for "$query".' : '',
      );
    } catch (error) {
      debugPrint('KametiBook friend search failed: $error');
      state = state.copyWith(
        searchResults: const <FriendSearchResult>[],
        errorMessage: 'Search failed. Please try again.',
      );
    } finally {
      state = state.copyWith(isSearching: false);
    }
  }

  Future<String?> addFriend(UserProfileModel profile) async {
    final currentUser = _ref.read(authControllerProvider).user;
    if (currentUser == null) return 'Please login before adding friends.';
    if (profile.id == currentUser.id) return 'You cannot add your own account.';
    if (state.friends.any((friend) => friend.friendUserId == profile.id)) {
      return 'This user is already in your friends.';
    }
    if (state.outgoingRequests
        .any((request) => request.toUserId == profile.id)) {
      return 'Friend request already sent.';
    }
    if (state.incomingRequests
        .any((request) => request.fromUserId == profile.id)) {
      return 'This user already sent you a request. Accept it from Friend Requests.';
    }
    if (!FirebaseBootstrap.isInitialized) return 'Firebase is not configured.';

    final now = DateTime.now();
    final currentPublic = await _getPublicProfile(currentUser.id);
    final currentName = currentPublic?.fullName ?? currentUser.fullName;
    final currentUsername = currentPublic?.username ?? '';
    final currentPhone = currentPublic?.phone ?? currentUser.phone;
    final currentCity = currentPublic?.city ?? currentUser.city;
    final currentPhoto = currentPublic?.profilePhotoUrl ?? '';

    final requestId = friendRequestIdForUsers(currentUser.id, profile.id);
    final requestRef = _firestore.collection('friendRequests').doc(requestId);
    final request = FriendRequestModel(
      id: requestId,
      fromUserId: currentUser.id,
      toUserId: profile.id,
      fromName: currentName,
      fromUsername: currentUsername,
      fromPhone: currentPhone,
      fromCity: currentCity,
      fromPhotoUrl: currentPhoto,
      toName: profile.fullName,
      toUsername: profile.username,
      toPhone: profile.phone,
      toCity: profile.city,
      toPhotoUrl: profile.profilePhotoUrl,
      status: FriendRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await requestRef
          .set(request.toMap())
          .timeout(const Duration(seconds: 10));
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return 'A friend request already exists between these accounts.';
      }
      rethrow;
    }
    state = state.copyWith(
      outgoingRequests: [...state.outgoingRequests, request],
      searchResults: state.searchResults
          .map(
            (result) => result.profile.id == profile.id
                ? FriendSearchResult(
                    profile: result.profile,
                    isFriend: result.isFriend,
                    outgoingRequest: request,
                    incomingRequest: result.incomingRequest,
                  )
                : result,
          )
          .toList(),
    );
    return null;
  }

  Future<String?> acceptFriendRequest(FriendRequestModel request) async {
    final currentUser = _ref.read(authControllerProvider).user;
    if (currentUser == null) return 'Please login to accept requests.';
    if (request.toUserId != currentUser.id) {
      return 'Only the receiver can accept this request.';
    }
    if (!FirebaseBootstrap.isInitialized) return 'Firebase is not configured.';

    final now = DateTime.now();
    final chatId = chatIdForUsers(request.fromUserId, request.toUserId);
    final requesterFriend = FriendModel(
      userId: request.fromUserId,
      friendUserId: request.toUserId,
      friendName: request.toName,
      friendUsername: request.toUsername,
      friendPhone: request.toPhone,
      friendCity: request.toCity,
      friendPhotoUrl: request.toPhotoUrl,
      status: FriendStatus.active,
      createdAt: now,
      updatedAt: now,
      chatId: chatId,
    );
    final receiverFriend = FriendModel(
      userId: request.toUserId,
      friendUserId: request.fromUserId,
      friendName: request.fromName,
      friendUsername: request.fromUsername,
      friendPhone: request.fromPhone,
      friendCity: request.fromCity,
      friendPhotoUrl: request.fromPhotoUrl,
      status: FriendStatus.active,
      createdAt: now,
      updatedAt: now,
      chatId: chatId,
    );
    final thread = ChatThreadModel(
      id: chatId,
      participantIds: [request.fromUserId, request.toUserId],
      participantNames: {
        request.fromUserId: request.fromName,
        request.toUserId: request.toName,
      },
      participantPhotos: {
        request.fromUserId: request.fromPhotoUrl,
        request.toUserId: request.toPhotoUrl,
      },
      lastMessage: '',
      lastMessageAt: null,
      lastSenderId: '',
      createdAt: now,
      updatedAt: now,
    );

    final batch = _firestore.batch();
    batch.set(
      _firestore
          .collection('users')
          .doc(request.fromUserId)
          .collection('friends')
          .doc(request.toUserId),
      requesterFriend.toMap(),
    );
    batch.set(
      _firestore
          .collection('users')
          .doc(request.toUserId)
          .collection('friends')
          .doc(request.fromUserId),
      receiverFriend.toMap(),
    );
    batch.set(_firestore.collection('chats').doc(chatId), thread.toMap());
    batch.update(_firestore.collection('friendRequests').doc(request.id), {
      'status': FriendRequestStatus.accepted.name,
      'respondedAt': now.millisecondsSinceEpoch,
      'updatedAt': now.millisecondsSinceEpoch,
    });
    await batch.commit().timeout(const Duration(seconds: 12));
    return null;
  }

  Future<String?> rejectFriendRequest(FriendRequestModel request) async {
    final currentUser = _ref.read(authControllerProvider).user;
    if (currentUser == null) return 'Please login to reject requests.';
    if (request.toUserId != currentUser.id) {
      return 'Only the receiver can reject this request.';
    }
    final now = DateTime.now();
    await _firestore.collection('friendRequests').doc(request.id).update({
      'status': FriendRequestStatus.rejected.name,
      'respondedAt': now.millisecondsSinceEpoch,
      'updatedAt': now.millisecondsSinceEpoch,
    }).timeout(const Duration(seconds: 10));
    return null;
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final currentUser = _ref.read(authControllerProvider).user;
    final userId = currentUser?.id ?? '';
    final cleanText = text.trim();
    if (userId.isEmpty || cleanText.isEmpty) return;
    final now = DateTime.now();
    final messageRef =
        _firestore.collection('chats').doc(chatId).collection('messages').doc();
    final message = ChatMessageModel(
      id: messageRef.id,
      chatId: chatId,
      senderId: userId,
      text: cleanText,
      createdAt: now,
      readBy: [userId],
    );
    final batch = _firestore.batch();
    batch.set(messageRef, message.toMap());
    batch.update(_firestore.collection('chats').doc(chatId), {
      'lastMessage': cleanText,
      'lastMessageAt': now.millisecondsSinceEpoch,
      'lastSenderId': userId,
      'updatedAt': now.millisecondsSinceEpoch,
    });
    await batch.commit();
  }

  Stream<List<ChatMessageModel>> streamMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromMap({
                  ...doc.data(),
                  'id': doc.data()['id'] ?? doc.id,
                  'chatId': doc.data()['chatId'] ?? chatId,
                }))
            .toList());
  }

  FriendModel? friendById(String userId) {
    for (final friend in state.friends) {
      if (friend.friendUserId == userId) return friend;
    }
    return null;
  }

  ChatThreadModel? chatById(String chatId) {
    for (final chat in state.chats) {
      if (chat.id == chatId) return chat;
    }
    return null;
  }

  Future<UserProfileModel?> _findByExactUsername(String query) async {
    final usernameDoc =
        await _firestore.collection('usernames').doc(query).get();
    if (!usernameDoc.exists) return null;
    final userId = '${usernameDoc.data()?['userId'] ?? ''}';
    if (userId.isEmpty) return null;
    return _getPublicProfile(userId);
  }

  Future<UserProfileModel?> _getPublicProfile(String userId) async {
    final profileDoc =
        await _firestore.collection('publicUserProfiles').doc(userId).get();
    if (!profileDoc.exists || profileDoc.data() == null) return null;
    return UserProfileModel.fromMap({
      ...profileDoc.data()!,
      'id': profileDoc.data()!['id'] ?? profileDoc.id,
    });
  }

  Future<void> _repairExistingFriendEdges(
    String currentUserId,
    List<FriendModel> friends,
  ) async {
    if (currentUserId.isEmpty || friends.isEmpty) return;
    final currentPublic = await _getPublicProfile(currentUserId);
    final currentUser = _ref.read(authControllerProvider).user;
    final currentName =
        currentPublic?.fullName ?? currentUser?.fullName ?? 'Friend';
    final currentUsername = currentPublic?.username ?? '';
    final currentPhone = currentPublic?.phone ?? currentUser?.phone ?? '';
    final currentCity = currentPublic?.city ?? currentUser?.city ?? '';
    final currentPhoto = currentPublic?.profilePhotoUrl ?? '';

    for (final friend in friends) {
      final repairKey = chatIdForUsers(currentUserId, friend.friendUserId);
      if (!_repairAttemptedKeys.add(repairKey)) continue;

      try {
        final now = DateTime.now();
        final chatId = friend.chatId.isNotEmpty ? friend.chatId : repairKey;
        final reverseFriend = FriendModel(
          userId: friend.friendUserId,
          friendUserId: currentUserId,
          friendName: currentName,
          friendUsername: currentUsername,
          friendPhone: currentPhone,
          friendCity: currentCity,
          friendPhotoUrl: currentPhoto,
          status: FriendStatus.active,
          createdAt: friend.createdAt,
          updatedAt: now,
          chatId: chatId,
        );
        final batch = _firestore.batch();
        batch.set(
          _firestore
              .collection('users')
              .doc(friend.friendUserId)
              .collection('friends')
              .doc(currentUserId),
          reverseFriend.toMap(),
          SetOptions(merge: true),
        );
        batch.set(
          _firestore.collection('chats').doc(chatId),
          {
            'id': chatId,
            'participantIds': [currentUserId, friend.friendUserId],
            'participantNames': {
              currentUserId: currentName,
              friend.friendUserId: friend.friendName,
            },
            'participantPhotos': {
              currentUserId: currentPhoto,
              friend.friendUserId: friend.friendPhotoUrl,
            },
            'createdAt': friend.createdAt.millisecondsSinceEpoch,
            'updatedAt': now.millisecondsSinceEpoch,
          },
          SetOptions(merge: true),
        );
        await batch.commit().timeout(const Duration(seconds: 10));
      } catch (error) {
        debugPrint('KametiBook friend edge repair failed: $error');
      }
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _friendsSub?.cancel();
    await _chatsSub?.cancel();
    await _incomingRequestsSub?.cancel();
    await _outgoingRequestsSub?.cancel();
    _friendsSub = null;
    _chatsSub = null;
    _incomingRequestsSub = null;
    _outgoingRequestsSub = null;
  }

  @override
  void dispose() {
    unawaited(_cancelSubscriptions());
    super.dispose();
  }
}

final friendsControllerProvider =
    StateNotifierProvider<FriendsController, FriendsState>((ref) {
  return FriendsController(ref);
});
