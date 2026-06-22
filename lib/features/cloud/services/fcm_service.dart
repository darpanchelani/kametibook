import 'package:firebase_messaging/firebase_messaging.dart';

import '../repositories/user_repository.dart';

class FcmService {
  FcmService({FirebaseMessaging? messaging}) : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  Future<String?> requestPermissionAndToken() async {
    await _messaging.requestPermission();
    return _messaging.getToken();
  }
}

class NotificationTokenManager {
  const NotificationTokenManager({required this.fcmService, required this.userRepository});

  final FcmService fcmService;
  final UserRepository userRepository;

  Future<void> syncToken(String userId) async {
    final token = await fcmService.requestPermissionAndToken();
    if (token == null || token.isEmpty) return;
    await userRepository.updateFcmToken(userId, token);
  }
}
