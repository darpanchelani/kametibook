import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

abstract class AuthRepository {
  Stream<firebase_auth.User?> streamAuthState();
  firebase_auth.User? getCurrentUser();
  Future<void> signInWithEmailPassword(
      {required String email, required String password});
  Future<void> signUpWithEmailPassword(
      {required String email, required String password});
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<void> signUpWithPhone(
      {required String phone,
      required void Function(String verificationId) onCodeSent});
  Future<firebase_auth.UserCredential> verifyOtp(
      {required String verificationId, required String smsCode});
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({firebase_auth.FirebaseAuth? auth})
      : _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  final firebase_auth.FirebaseAuth _auth;

  @override
  firebase_auth.User? getCurrentUser() => _auth.currentUser;

  @override
  Stream<firebase_auth.User?> streamAuthState() => _auth.authStateChanges();

  @override
  Future<void> signInWithEmailPassword(
      {required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signUpWithEmailPassword(
      {required String email, required String password}) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> signUpWithPhone(
      {required String phone,
      required void Function(String verificationId) onCodeSent}) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) =>
          _auth.signInWithCredential(credential),
      verificationFailed: (error) => throw error,
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  @override
  Future<firebase_auth.UserCredential> verifyOtp(
      {required String verificationId, required String smsCode}) {
    final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: smsCode);
    return _auth.signInWithCredential(credential);
  }
}
