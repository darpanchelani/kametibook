import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile_model.dart';

abstract class UserRepository {
  Future<void> createUserProfile(UserProfileModel profile);
  Future<void> updateUserProfile(UserProfileModel profile);
  Stream<UserProfileModel?> streamUserProfile(String userId);
  Future<UserProfileModel?> getUserProfile(String userId);
  Future<void> updateFcmToken(String userId, String token);
}

class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> createUserProfile(UserProfileModel profile) => _firestore.collection('users').doc(profile.id).set(profile.toMap());

  @override
  Future<void> updateUserProfile(UserProfileModel profile) => _firestore.collection('users').doc(profile.id).update(profile.toMap());

  @override
  Future<UserProfileModel?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists ? UserProfileModel.fromMap(doc.data() ?? {}) : null;
  }

  @override
  Stream<UserProfileModel?> streamUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) => doc.exists ? UserProfileModel.fromMap(doc.data() ?? {}) : null);
  }

  @override
  Future<void> updateFcmToken(String userId, String token) => _firestore.collection('users').doc(userId).update({'fcmToken': token, 'updatedAt': DateTime.now().millisecondsSinceEpoch});
}
