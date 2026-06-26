import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  bool get isAuthenticated =>
      user != null && userProfile != null && status == AuthStatus.authenticated;
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

  static const _firebaseTimeout = Duration(seconds: 20);

  final Map<String, _AccountRecord> _accountsByEmail = {};
  firebase_auth.FirebaseAuth get _firebaseAuth =>
      firebase_auth.FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<bool> refreshSession() async {
    state = state.copyWith(
        status: AuthStatus.checking, isLoading: true, errorMessage: '');
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
        return _completeSession(profile);
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
      state = const AuthState(
          status: AuthStatus.blocked,
          errorMessage: 'Your account is not active. Please contact support.');
      return false;
    }
    state = state.copyWith(status: AuthStatus.authenticated, isLoading: false);
    return true;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
        isLoading: true, status: AuthStatus.checking, errorMessage: '');
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final normalizedEmail = _normalizeEmail(email);
    if (!FirebaseBootstrap.isInitialized && !AppConfig.enableDemoMode) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage:
            'Secure login is not configured. Please connect Firebase before signing in.',
      );
      return false;
    }
    if (FirebaseBootstrap.isInitialized) {
      return _firebaseLogin(normalizedEmail, password);
    }
    final account = _accountsByEmail[normalizedEmail];
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
        errorMessage: 'Invalid email or password.',
        clearUser: true,
      );
      return false;
    }
    if (!_isActive(account.profile)) {
      state = const AuthState(
          status: AuthStatus.blocked,
          errorMessage: 'Your account is not active. Please contact support.');
      return false;
    }
    final updated = _copyProfileWithLogin(account.profile);
    _accountsByEmail[normalizedEmail] = account.copyWith(profile: updated);
    return _setAuthenticatedProfile(updated);
  }

  Future<bool> signup({
    required String fullName,
    required String username,
    required String email,
    required String phone,
    required String password,
    required String city,
  }) async {
    state = state.copyWith(
        isLoading: true, status: AuthStatus.checking, errorMessage: '');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final normalizedEmail = _normalizeEmail(email);
    final normalizedUsername = _normalizeUsername(username);
    final normalizedPhone = _normalizePhone(phone);
    if (FirebaseBootstrap.isInitialized) {
      return _firebaseSignup(
        fullName: fullName,
        username: normalizedUsername,
        email: normalizedEmail,
        phone: phone,
        normalizedPhone: normalizedPhone,
        password: password,
        city: city,
      );
    }
    if (!AppConfig.enableDemoMode) {
      state = const AuthState(
          status: AuthStatus.error,
          errorMessage:
              'Secure signup is not configured. Please connect Firebase before creating accounts.');
      return false;
    }
    if (_accountsByEmail.containsKey(normalizedEmail)) {
      state = const AuthState(
          status: AuthStatus.error,
          errorMessage:
              'An account with this email already exists. Please login.');
      return false;
    }
    final now = DateTime.now();
    final profile = UserProfileModel(
      id: 'user-${now.microsecondsSinceEpoch}',
      fullName: fullName.trim(),
      username: normalizedUsername,
      phone: phone.trim(),
      email: normalizedEmail,
      city: city.trim(),
      profilePhotoUrl: '',
      role: GlobalUserRole.user,
      status: UserProfileStatus.active,
      createdAt: now,
      updatedAt: now,
      lastLoginAt: now,
      fcmToken: '',
    );
    _accountsByEmail[normalizedEmail] =
        _AccountRecord(profile: profile, password: password);
    return _setAuthenticatedProfile(profile);
  }

  Future<void> sendPasswordReset(String email) async {
    if (FirebaseBootstrap.isInitialized) {
      await _firebaseAuth.sendPasswordResetEmail(email: _normalizeEmail(email));
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

  Future<bool> updateProfilePhoto(String photoUrl) async {
    final profile = state.userProfile;
    if (profile == null || photoUrl.trim().isEmpty) return false;
    final updated = profile.copyWith(
      profilePhotoUrl: photoUrl.trim(),
      updatedAt: DateTime.now(),
    );
    try {
      if (FirebaseBootstrap.isInitialized) {
        await _withTimeout(
          _firestore.collection('users').doc(updated.id).update({
            'profilePhotoUrl': updated.profilePhotoUrl,
            'updatedAt': updated.updatedAt.millisecondsSinceEpoch,
          }),
          'Profile photo update timed out. Please try again.',
        );
        await _syncPublicProfileBestEffort(updated);
      }
      state = state.copyWith(userProfile: updated, errorMessage: '');
      return true;
    } catch (error) {
      state = state.copyWith(
        errorMessage: _withDebugDetails(
          'Profile photo could not be updated. Please try again.',
          error,
        ),
      );
      return false;
    }
  }

  bool _isActive(UserProfileModel profile) =>
      profile.status == UserProfileStatus.active;
  String _normalizeEmail(String email) => email.trim().toLowerCase();
  String _normalizeUsername(String username) =>
      username.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  String _normalizePhone(String phone) => phone.replaceAll(RegExp(r'\D'), '');

  Future<bool> _firebaseLogin(String email, String password) async {
    try {
      final credential = await _withTimeout(
        _firebaseAuth.signInWithEmailAndPassword(
            email: email, password: password),
        'Login request timed out. Please check your internet connection and try again.',
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        state = const AuthState(
            status: AuthStatus.error,
            errorMessage: 'Login failed. Please try again.');
        return false;
      }
      final profile = await _fetchProfile(firebaseUser.uid);
      if (profile == null) {
        await _firebaseAuth.signOut();
        state = const AuthState(
            status: AuthStatus.profileMissing,
            errorMessage: 'No KametiBook account found. Please sign up first.');
        return false;
      }
      if (!_isActive(profile)) {
        await _firebaseAuth.signOut();
        state = const AuthState(
            status: AuthStatus.blocked,
            errorMessage:
                'Your account is not active. Please contact support.');
        return false;
      }
      final updated = _copyProfileWithLogin(profile);
      await _updateLastLoginBestEffort(updated);
      unawaited(_syncPublicProfileBestEffort(updated));
      return _setAuthenticatedProfile(updated);
    } on firebase_auth.FirebaseAuthException catch (error) {
      state = AuthState(
          status: AuthStatus.error, errorMessage: _loginErrorMessage(error));
      return false;
    } on TimeoutException catch (error) {
      state = AuthState(
          status: AuthStatus.error,
          errorMessage: error.message ??
              'Login timed out. Please check your internet connection and try again.');
      return false;
    } catch (error) {
      state = AuthState(
          status: AuthStatus.error,
          errorMessage:
              _withDebugDetails('Login failed. Please try again.', error));
      return false;
    }
  }

  Future<bool> _firebaseSignup({
    required String fullName,
    required String username,
    required String email,
    required String phone,
    required String normalizedPhone,
    required String password,
    required String city,
  }) async {
    firebase_auth.UserCredential? credential;
    try {
      credential = await _withTimeout(
        _firebaseAuth.createUserWithEmailAndPassword(
            email: email, password: password),
        'Signup request timed out. Please check your internet connection and try again.',
      );
      final firebaseUser = credential?.user;
      if (firebaseUser == null) {
        throw StateError('Firebase user was not created.');
      }
      final now = DateTime.now();
      final profile = UserProfileModel(
        id: firebaseUser.uid,
        fullName: fullName.trim(),
        username: username,
        phone: phone.trim(),
        email: email,
        city: city.trim(),
        profilePhotoUrl: '',
        role: GlobalUserRole.user,
        status: UserProfileStatus.active,
        createdAt: now,
        updatedAt: now,
        lastLoginAt: now,
        fcmToken: '',
      );
      final batch = _firestore.batch();
      final privateProfileRef =
          _firestore.collection('users').doc(firebaseUser.uid);
      final publicProfileRef =
          _firestore.collection('publicUserProfiles').doc(firebaseUser.uid);
      final usernameRef = _firestore.collection('usernames').doc(username);
      batch.set(usernameRef, {
        'userId': profile.id,
        'username': profile.username,
        'createdAt': now.millisecondsSinceEpoch,
      });
      batch.set(privateProfileRef, {
        ...profile.toMap(),
        'phoneNormalized': normalizedPhone,
        'searchKeywords': _buildProfileSearchKeywords(profile, normalizedPhone),
      });
      batch.set(publicProfileRef, {
        'id': profile.id,
        'fullName': profile.fullName,
        'fullNameLower': profile.fullName.toLowerCase(),
        'username': profile.username,
        'usernameLower': profile.username.toLowerCase(),
        'phone': profile.phone,
        'phoneNormalized': normalizedPhone,
        'email': profile.email,
        'emailLower': profile.email.toLowerCase(),
        'city': profile.city,
        'profilePhotoUrl': profile.profilePhotoUrl,
        'status': profile.status.name,
        'searchKeywords': _buildProfileSearchKeywords(profile, normalizedPhone),
        'createdAt': profile.createdAt.millisecondsSinceEpoch,
      });
      await _withTimeout(
        batch.commit(),
        'Profile creation timed out. Please check Firestore setup and your internet connection.',
      );
      return _setAuthenticatedProfile(profile);
    } catch (error, stackTrace) {
      debugPrint('KametiBook signup failed: $error');
      debugPrint('$stackTrace');
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
        } catch (_) {
          // If cleanup fails, signing out still prevents access without a verified profile.
        }
      }
      await _firebaseAuth.signOut();
      state = AuthState(
          status: AuthStatus.error, errorMessage: _signupErrorMessage(error));
      return false;
    }
  }

  Future<bool> _completeSession(UserProfileModel profile) async {
    if (!_isActive(profile)) {
      await _firebaseAuth.signOut();
      state = const AuthState(
          status: AuthStatus.blocked,
          errorMessage: 'Your account is not active. Please contact support.');
      return false;
    }
    unawaited(_syncPublicProfileBestEffort(profile));
    return _setAuthenticatedProfile(profile);
  }

  UserProfileModel _copyProfileWithLogin(UserProfileModel profile) {
    final now = DateTime.now();
    return UserProfileModel(
      id: profile.id,
      fullName: profile.fullName,
      phone: profile.phone,
      username: profile.username,
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
  }

  bool _setAuthenticatedProfile(UserProfileModel profile) {
    state = AuthState(
      user: UserModel(
          id: profile.id,
          fullName: profile.fullName,
          phone: profile.phone,
          city: profile.city,
          createdAt: profile.createdAt),
      userProfile: profile,
      status: AuthStatus.authenticated,
    );
    return true;
  }

  String _loginErrorMessage(firebase_auth.FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'Your account is not active. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Firebase Email/Password sign-in is disabled. Enable it in Firebase Console > Authentication > Sign-in method.';
      default:
        return _withDebugDetails(
            'Firebase Auth error (${error.code}). ${error.message ?? 'Login failed.'}',
            error);
    }
  }

  String _signupErrorMessage(Object error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account with this email already exists. Please login.';
        case 'operation-not-allowed':
          return 'Firebase Email/Password sign-in is disabled. Enable it in Firebase Console > Authentication > Sign-in method.';
        case 'weak-password':
          return 'Password is too weak. Use at least 8 characters with letters and numbers.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection and try again.';
        default:
          return _withDebugDetails(
              'Firebase Auth error (${error.code}). ${error.message ?? 'Account could not be created.'}',
              error);
      }
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Firestore permission denied while creating your profile. Deploy Firestore rules and make sure the database is created.';
        case 'unavailable':
          return 'Firebase is currently unavailable. Please check your internet connection and try again.';
        default:
          return _withDebugDetails(
              'Firebase error (${error.code}). ${error.message ?? 'Account profile could not be saved.'}',
              error);
      }
    }
    if (error is PlatformException) {
      return _withDebugDetails(
          'Platform error (${error.code}). ${error.message ?? 'Account could not be created.'}',
          error);
    }
    if (error is TimeoutException) {
      return error.message ??
          'Signup timed out. Please check your internet connection and try again.';
    }
    return _withDebugDetails(
        'Account could not be created. Please try again.', error);
  }

  Future<T> _withTimeout<T>(Future<T> future, String message) {
    return future.timeout(_firebaseTimeout,
        onTimeout: () => throw TimeoutException(message, _firebaseTimeout));
  }

  List<String> _buildProfileSearchKeywords(
      UserProfileModel profile, String normalizedPhone) {
    final values = <String>{
      profile.username.toLowerCase(),
      profile.fullName.toLowerCase(),
      profile.email.toLowerCase(),
      normalizedPhone,
      profile.phone.trim().toLowerCase(),
      profile.city.toLowerCase(),
    };
    for (final part in profile.fullName.toLowerCase().split(RegExp(r'\s+'))) {
      if (part.trim().isNotEmpty) values.add(part.trim());
    }
    return values.where((value) => value.trim().isNotEmpty).toList();
  }

  Future<void> _updateLastLoginBestEffort(UserProfileModel profile) async {
    try {
      await _withTimeout(
        _firestore.collection('users').doc(profile.id).update({
          'lastLoginAt': profile.lastLoginAt?.millisecondsSinceEpoch,
          'updatedAt': profile.updatedAt.millisecondsSinceEpoch,
        }),
        'Profile update timed out.',
      );
    } catch (error) {
      debugPrint('KametiBook lastLoginAt update skipped: $error');
    }
  }

  Future<void> _syncPublicProfileBestEffort(UserProfileModel profile) async {
    if (!FirebaseBootstrap.isInitialized || profile.id.isEmpty) return;
    final normalizedPhone = _normalizePhone(profile.phone);
    try {
      await _firestore.collection('publicUserProfiles').doc(profile.id).set({
        'id': profile.id,
        'fullName': profile.fullName,
        'fullNameLower': profile.fullName.toLowerCase(),
        'username': profile.username,
        'usernameLower': profile.username.toLowerCase(),
        'phone': profile.phone,
        'phoneNormalized': normalizedPhone,
        'email': profile.email,
        'emailLower': profile.email.toLowerCase(),
        'city': profile.city,
        'profilePhotoUrl': profile.profilePhotoUrl,
        'status': profile.status.name,
        'searchKeywords': _buildProfileSearchKeywords(profile, normalizedPhone),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('KametiBook public profile sync skipped: $error');
    }
  }

  String _withDebugDetails(String message, Object error) {
    if (!kDebugMode) return message;
    return '$message\n\nDebug details: ${error.runtimeType}: $error';
  }

  Future<UserProfileModel?> _fetchProfile(String uid) async {
    final doc = await _withTimeout(
      _firestore.collection('users').doc(uid).get(),
      'Profile lookup timed out. Please check your internet connection and try again.',
    );
    if (!doc.exists) return null;
    return UserProfileModel.fromMap(doc.data() ?? {});
  }
}

class _AccountRecord {
  const _AccountRecord({required this.profile, required this.password});
  final UserProfileModel profile;
  final String password;

  _AccountRecord copyWith({UserProfileModel? profile}) =>
      _AccountRecord(profile: profile ?? this.profile, password: password);
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});
