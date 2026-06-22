import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../core/constants/app_config.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../cloud/models/user_profile_model.dart';
import '../models/user_model.dart';

enum AuthStatus {
  initial,
  checking,
  unauthenticated,
  authenticated,
  profileMissing,
  blocked,
  error;
}

class AuthState {
  const AuthState({
    this.user,
    this.userProfile,
    this.status = AuthStatus.initial,
    this.isLoading = false,
    this.errorMessage = '',
  });

  final UserModel? user;
  final UserProfileModel? userProfile;
  final AuthStatus status;
  final bool isLoading;
  final String errorMessage;

  bool get isAuthenticated => user != null && userProfile != null && status == AuthStatus.authenticated;
  bool get isProfileLoaded => userProfile != null;

  AuthState copyWith({
    UserModel? user,
    UserProfileModel? userProfile,
    AuthStatus? status,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      userProfile: clearUser ? null : userProfile ?? this.userProfile,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState(status: AuthStatus.unauthenticated));

  final Map<String, _AccountRecord> _accountsByPhone = {};
  firebase_auth.FirebaseAuth get _firebaseAuth => firebase_auth.FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<bool> refreshSession() async {
    state = state.copyWith(status: AuthStatus.checking, isLoading: true, errorMessage: '');
    if (FirebaseBootstrap.isInitialized) {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return false;
      }
      try {
        final profile = await _fetchProfile(firebaseUser.uid);
        if (profile == null) {
          await _firebaseAuth.signOut();
          state = const AuthState(
            status: AuthStatus.profileMissing,
            errorMessage: 'No KametiBook account found. Please sign up first.',
          );
          return false;
        }
        if (!_isActive(profile)) {
          await _firebaseAuth.signOut();
          state = const AuthState(
            status: AuthStatus.blocked,
            errorMessage: 'Your account is not active. Please contact support.',
          );
          return false;
        }
        state = AuthState(
          user: UserModel(
            id: profile.id,
            fullName: profile.fullName,
            phone: profile.phone,
            city: profile.city,
            createdAt: profile.createdAt,
          ),
          userProfile: profile,
          status: AuthStatus.authenticated,
        );
        return true;
      } catch (_) {
        await _firebaseAuth.signOut();
        state = const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Session could not be verified. Please login again.',
        );
        return false;
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (state.user == null || state.userProfile == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return false;
    }
    if (!_isActive(state.userProfile!)) {
      state = const AuthState(status: AuthStatus.blocked, errorMessage: 'Your account is not active. Please contact support.');
      return false;
    }
    state = state.copyWith(status: AuthStatus.authenticated, isLoading: false);
    return true;
  }

  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, status: AuthStatus.checking, errorMessage: '');
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!FirebaseBootstrap.isInitialized && !AppConfig.enableDemoMode) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'Secure login is not configured. Please connect Firebase before signing in.',
      );
      return false;
    }
    final normalized = _normalizePhone(phone);
    if (FirebaseBootstrap.isInitialized) {
      return _firebaseLogin(normalized, password);
    }
    if (!AppConfig.enableDemoMode) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'Secure login is not configured. Please connect Firebase before signing in.',
      );
      return false;
    }
    final account = _accountsByPhone[normalized];
    if (account == null) {
      state = const AuthState(
        status: AuthStatus.profileMissing,
        errorMessage: 'No KametiBook account found. Please sign up first.',
      );
      return false;
    }
    if (account.password != password) {
      state = state.copyWith(
        status: AuthStatus.error,
        isLoading: false,
        errorMessage: 'Invalid phone number or password.',
        clearUser: true,
      );
      return false;
    }
    if (!_isActive(account.profile)) {
      state = const AuthState(status: AuthStatus.blocked, errorMessage: 'Your account is not active. Please contact support.');
      return false;
    }
    final now = DateTime.now();
    final updatedProfile = UserProfileModel(
      id: account.profile.id,
      fullName: account.profile.fullName,
      phone: account.profile.phone,
      email: account.profile.email,
      city: account.profile.city,
      profilePhotoUrl: account.profile.profilePhotoUrl,
      role: account.profile.role,
      status: account.profile.status,
      createdAt: account.profile.createdAt,
      updatedAt: now,
      lastLoginAt: now,
      fcmToken: account.profile.fcmToken,
    );
    _accountsByPhone[normalized] = account.copyWith(profile: updatedProfile);
    state = AuthState(
      user: UserModel(
        id: updatedProfile.id,
        fullName: updatedProfile.fullName,
        phone: updatedProfile.phone,
        city: updatedProfile.city,
        createdAt: updatedProfile.createdAt,
      ),
      userProfile: updatedProfile,
      status: AuthStatus.authenticated,
    );
    return true;
  }

  Future<bool> signup({
    required String fullName,
    required String phone,
    required String password,
    required String city,
    String email = '',
  }) async {
    state = state.copyWith(isLoading: true, status: AuthStatus.checking, errorMessage: '');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final normalized = _normalizePhone(phone);
    if (FirebaseBootstrap.isInitialized) {
      return _firebaseSignup(
        fullName: fullName,
        phone: phone,
        normalizedPhone: normalized,
        password: password,
        city: city,
        email: email,
      );
    }
    if (!AppConfig.enableDemoMode) {
      state = const AuthState(status: AuthStatus.error, errorMessage: 'Secure signup is not configured. Please connect Firebase before creating accounts.');
      return false;
    }
    if (_accountsByPhone.containsKey(normalized)) {
      state = const AuthState(status: AuthStatus.error, errorMessage: 'An account with this phone number already exists. Please login.');
      return false;
    }
    if (email.trim().isNotEmpty && _accountsByPhone.values.any((record) => record.profile.email.toLowerCase() == email.trim().toLowerCase())) {
      state = const AuthState(status: AuthStatus.error, errorMessage: 'An account with this email already exists. Please login.');
      return false;
    }
    final now = DateTime.now();
    final profile = UserProfileModel(
      id: 'user-${now.microsecondsSinceEpoch}',
      fullName: fullName.trim(),
      phone: phone.trim(),
      email: email.trim(),
      city: city.trim(),
      profilePhotoUrl: '',
      role: GlobalUserRole.user,
      status: UserProfileStatus.active,
      createdAt: now,
      updatedAt: now,
      lastLoginAt: now,
      fcmToken: '',
    );
    _accountsByPhone[normalized] = _AccountRecord(profile: profile, password: password);
    state = AuthState(
      user: UserModel(
        id: profile.id,
        fullName: profile.fullName,
        phone: profile.phone,
        city: profile.city,
        createdAt: profile.createdAt,
      ),
      userProfile: profile,
      status: AuthStatus.authenticated,
    );
    return true;
  }

  Future<void> sendPasswordReset(String identifier) async {
    if (FirebaseBootstrap.isInitialized) {
      await _firebaseAuth.sendPasswordResetEmail(email: _authEmail(_normalizePhone(identifier)));
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<void> logout() async {
    if (FirebaseBootstrap.isInitialized) {
      await _firebaseAuth.signOut();
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  bool _isActive(UserProfileModel profile) => profile.status == UserProfileStatus.active;
  String _normalizePhone(String phone) => phone.replaceAll(RegExp(r'\D'), '');
  String _authEmail(String normalizedPhone) => '$normalizedPhone@kametibook.local';

  Future<bool> _firebaseLogin(String normalizedPhone, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(email: _authEmail(normalizedPhone), password: password);
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        state = const AuthState(status: AuthStatus.error, errorMessage: 'Login failed. Please try again.');
        return false;
      }
      final profile = await _fetchProfile(firebaseUser.uid);
      if (profile == null) {
        await _firebaseAuth.signOut();
        state = const AuthState(status: AuthStatus.profileMissing, errorMessage: 'No KametiBook account found. Please sign up first.');
        return false;
      }
      if (!_isActive(profile)) {
        await _firebaseAuth.signOut();
        state = const AuthState(status: AuthStatus.blocked, errorMessage: 'Your account is not active. Please contact support.');
        return false;
      }
      final now = DateTime.now();
      await _firestore.collection('users').doc(profile.id).update({
        'lastLoginAt': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      });
      final updated = UserProfileModel(
        id: profile.id,
        fullName: profile.fullName,
        phone: profile.phone,
        email: profile.email,
        city: profile.city,
        profilePhotoUrl: profile.profilePhotoUrl,
        role: profile.role,
        status: profile.status,
        createdAt: profile.createdAt,
        updatedAt: now,
        lastLoginAt: now,
        fcmToken: profile.fcmToken,
      );
      state = AuthState(
        user: UserModel(id: updated.id, fullName: updated.fullName, phone: updated.phone, city: updated.city, createdAt: updated.createdAt),
        userProfile: updated,
        status: AuthStatus.authenticated,
      );
      return true;
    } on firebase_auth.FirebaseAuthException catch (error) {
      state = AuthState(status: AuthStatus.error, errorMessage: error.code == 'user-not-found' ? 'No KametiBook account found. Please sign up first.' : 'Invalid phone number or password.');
      return false;
    } catch (_) {
      state = const AuthState(status: AuthStatus.error, errorMessage: 'Login failed. Please try again.');
      return false;
    }
  }

  Future<bool> _firebaseSignup({
    required String fullName,
    required String phone,
    required String normalizedPhone,
    required String password,
    required String city,
    required String email,
  }) async {
    firebase_auth.UserCredential? credential;
    try {
      final existing = await _firestore.collection('users').where('phoneNormalized', isEqualTo: normalizedPhone).limit(1).get();
      if (existing.docs.isNotEmpty) {
        state = const AuthState(status: AuthStatus.error, errorMessage: 'An account with this phone number already exists. Please login.');
        return false;
      }
      if (email.trim().isNotEmpty) {
        final emailExisting = await _firestore.collection('users').where('email', isEqualTo: email.trim().toLowerCase()).limit(1).get();
        if (emailExisting.docs.isNotEmpty) {
          state = const AuthState(status: AuthStatus.error, errorMessage: 'An account with this email already exists. Please login.');
          return false;
        }
      }
      credential = await _firebaseAuth.createUserWithEmailAndPassword(email: _authEmail(normalizedPhone), password: password);
      final firebaseUser = credential.user;
      if (firebaseUser == null) throw StateError('Firebase user was not created.');
      final now = DateTime.now();
      final profile = UserProfileModel(
        id: firebaseUser.uid,
        fullName: fullName.trim(),
        phone: phone.trim(),
        email: email.trim().toLowerCase(),
        city: city.trim(),
        profilePhotoUrl: '',
        role: GlobalUserRole.user,
        status: UserProfileStatus.active,
        createdAt: now,
        updatedAt: now,
        lastLoginAt: now,
        fcmToken: '',
      );
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        ...profile.toMap(),
        'phoneNormalized': normalizedPhone,
      });
      state = AuthState(
        user: UserModel(id: profile.id, fullName: profile.fullName, phone: profile.phone, city: profile.city, createdAt: profile.createdAt),
        userProfile: profile,
        status: AuthStatus.authenticated,
      );
      return true;
    } catch (_) {
      if (credential?.user != null) {
        await credential!.user!.delete();
      }
      await _firebaseAuth.signOut();
      state = const AuthState(status: AuthStatus.error, errorMessage: 'Account could not be created. Please try again.');
      return false;
    }
  }

  Future<UserProfileModel?> _fetchProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfileModel.fromMap(doc.data() ?? {});
  }
}

class _AccountRecord {
  const _AccountRecord({required this.profile, required this.password});
  final UserProfileModel profile;
  final String password;

  _AccountRecord copyWith({UserProfileModel? profile}) => _AccountRecord(profile: profile ?? this.profile, password: password);
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});
