import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadPaymentProof({
    required String kametiId,
    required String cycleId,
    required String memberId,
    required File file,
  }) async {
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref =
        _storage.ref('kametis/$kametiId/payments/$cycleId/$memberId/$name');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadPayoutProof({
    required String kametiId,
    required String allocationId,
    required File file,
  }) async {
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref = _storage.ref('kametis/$kametiId/payouts/$allocationId/$name');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadProfilePhoto(
      {required String userId, required File file}) async {
    final ref = _storage.ref(
        'users/$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> deleteFile(String path) => _storage.ref(path).delete();
}
