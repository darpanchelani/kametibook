import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrap {
  static bool _initialized = false;
  static Object? _lastError;

  static bool get isInitialized => _initialized;
  static Object? get lastError => _lastError;

  static Future<void> initializeIfConfigured() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;
      _lastError = null;
    } catch (error) {
      _lastError = error;
      _initialized = false;
    }
  }
}
